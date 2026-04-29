function [render_volume, rgb_channels] = compose_display_volume(raw_volume, channels)
% Compose the display RGB volume from a canonical channel-state struct.

display_volume = double(Program.Helpers.to_user_uint8(raw_volume));
rgb_channels = {channels.r, channels.g, channels.b};
rgb_names = {'red', 'green', 'blue'};
n_channels = size(display_volume, 4);

color_indices = zeros(1, 3);
for c = 1:3
    color_indices(c) = local_safe_index(rgb_channels{c}.idx, n_channels);
end
render_volume = display_volume(:, :, :, color_indices);

for c = 1:3
    channel = rgb_channels{c};
    if ~channel.bool
        render_volume(:, :, :, c) = 0;
        continue
    end

    Program.Handlers.dialogue.step(sprintf('Computing %s channel...', rgb_names{c}));
    if ~local_is_neutral_window(channel.settings.low_high_in)
        render_volume(:, :, :, c) = local_adjust_channel( ...
            render_volume(:, :, :, c), ...
            channel.settings, ...
            false);
    end
end

render_volume = local_add_channel(display_volume, render_volume, channels.white);
render_volume = local_add_channel(display_volume, render_volume, channels.dic);
render_volume = local_add_gfp_channel(display_volume, render_volume, channels.gfp);

for c = 1:length(channels.other)
    other = channels.other{c};
    if ~other.bool || other.idx <= 0 || other.idx > n_channels
        continue
    end

    Program.Handlers.dialogue.step('Processing unknown channel...');
    other_channel = display_volume(:, :, :, other.idx);
    other_channel = repmat(squeeze(other_channel), [1, 1, 1, 3]);
    for rgb = 1:3
        other_channel(:, :, :, rgb) = other_channel(:, :, :, rgb) * other.color(rgb);
    end
    render_volume = render_volume + other_channel;
end
end

function render_volume = local_add_channel(raw_volume, render_volume, channel)
if ~channel.bool
    return
end

n_channels = size(raw_volume, 4);
idx = local_safe_index(channel.idx, n_channels);
channel_volume = local_adjust_channel(raw_volume(:, :, :, idx), channel.settings, true);
render_volume = render_volume + repmat(squeeze(channel_volume), [1, 1, 1, 3]);
end

function render_volume = local_add_gfp_channel(raw_volume, render_volume, channel)
if ~channel.bool
    return
end

n_channels = size(raw_volume, 4);
idx = local_safe_index(channel.idx, n_channels);
channel_volume = local_adjust_channel(raw_volume(:, :, :, idx), channel.settings, true);

gfp_color = Program.GUIPreferences.instance().GFP_color;
channel_volume = repmat(squeeze(channel_volume), [1, 1, 1, 3]);
channel_volume(:, :, :, ~gfp_color) = 0;
render_volume = render_volume + channel_volume;
end

function idx = local_safe_index(idx, n_channels)
if isempty(idx) || idx < 1
    idx = 1;
elseif idx > n_channels
    idx = n_channels;
end
end

function channel_volume = local_adjust_channel(channel_volume, settings, apply_gamma)
if nargin < 3
    apply_gamma = true;
end

gamma_value = settings.gamma;
if gamma_value < 0.01
    gamma_value = 1;
end
if ~apply_gamma
    gamma_value = 1;
end

channel_volume = uint8(min(max(round(channel_volume), 0), 255));
if ~local_is_neutral_window(settings.low_high_in) || gamma_value ~= 1
    channel_volume = imadjustn( ...
        channel_volume, ...
        settings.low_high_in, ...
        settings.low_high_out, ...
        gamma_value);
end
channel_volume = double(channel_volume);
end

function tf = local_is_neutral_window(low_high_in)
tf = isempty(low_high_in);
if tf
    return
end

tf = numel(low_high_in) == 2 && all(abs(double(low_high_in(:)') - [0 1]) < 1e-9);
end
