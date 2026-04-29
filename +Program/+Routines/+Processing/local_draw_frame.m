function local_draw_frame(app, ax, frame)
if nargin < 1 || isempty(app)
    app = Program.app;
end

if isempty(frame)
    local_hide_frame(ax);
    return
end

frame = local_validate_frame(app, frame);
img = local_get_frame_handle(ax);
frame_size = size(frame);

if isempty(img) || ~isgraphics(img)
    img = image(frame, 'Parent', ax, ...
        'Tag', 'processing_frame', ...
        'HitTest', 'off', ...
        'PickableParts', 'none');
    setappdata(ax, 'proc_frame_handle', img);
    setappdata(ax, 'proc_frame_dims', frame_size);
    local_set_axis_limits(ax, frame_size);
    return
end

img.CData = frame;
img.Visible = 'on';

previous_size = [];
if isappdata(ax, 'proc_frame_dims')
    previous_size = getappdata(ax, 'proc_frame_dims');
end

if ~isequal(previous_size, frame_size)
    setappdata(ax, 'proc_frame_dims', frame_size);
    local_set_axis_limits(ax, frame_size);
end
end

function frame = local_validate_frame(app, frame)
if ndims(frame) == 2
    return
end

if ndims(frame) == 3 && size(frame, 3) >= 3
    if size(frame, 3) > 3
        frame = frame(:, :, 1:3);
    end
    return
end

msg = sprintf('Processing render: unexpected frame size %s', mat2str(size(frame)));
fprintf('%s\n', msg);
try
    app.logEvent('Processing', msg, 0);
catch
end
error('Processing render: invalid frame size %s', mat2str(size(frame)));
end

function img = local_get_frame_handle(ax)
img = [];
if isappdata(ax, 'proc_frame_handle')
    img = getappdata(ax, 'proc_frame_handle');
    if ~isempty(img) && isgraphics(img)
        return
    end
end

images = findall(ax, 'Type', 'image', 'Tag', 'processing_frame');
if ~isempty(images)
    img = images(1);
    img.Tag = 'processing_frame';
    if isprop(img, 'HitTest')
        img.HitTest = 'off';
    end
    if isprop(img, 'PickableParts')
        img.PickableParts = 'none';
    end
    setappdata(ax, 'proc_frame_handle', img);
    return
end

images = findall(ax, 'Type', 'image');
if ~isempty(images)
    img = images(1);
    img.Tag = 'processing_frame';
    if isprop(img, 'HitTest')
        img.HitTest = 'off';
    end
    if isprop(img, 'PickableParts')
        img.PickableParts = 'none';
    end
    setappdata(ax, 'proc_frame_handle', img);
end
end

function local_hide_frame(ax)
img = local_get_frame_handle(ax);
if ~isempty(img) && isgraphics(img)
    img.Visible = 'off';
end
end

function local_set_axis_limits(ax, frame_size)
ax.XLim = [1, max(1, frame_size(2))];
ax.YLim = [1, max(1, frame_size(1))];
end
