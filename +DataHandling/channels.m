classdef channels
    
    properties (Constant)
        to_discard = {'NA', 'N/A', 'NULL'};
        fluorophore_mapping = dictionary( ...
            'red', {{'neptune', 'nep', 'n2.5', 'n25'}}, ...
            'green', {{'cyofp1', 'cyofp', 'cyo'}}, ...
            'blue', {'bfp'}, ...
            'white', {{'rfp', 'tagrfp', 'tagrfp1'}}, ...
            'dic', {{'dic', 'dia', 'nomarski', 'phase'}}, ...
            'gfp', {{'gfp', 'gcamp'}});
    end
    
    methods (Static)
        function channel_struct = get(file)
            [as_loaded, ~] = DataHandling.Lazy.file.get_channels(file);                     % Grab channel info from file.
            [names, order] = DataHandling.channels.sort(as_loaded);                         % Sort channels according to fluorophore mapping.
            [to_keep, to_discard] = DataHandling.channels.validate(as_loaded);              % Get rid of channels marked N/A or null.

            channel_struct = struct( ...
                'as_loaded', as_loaded, ...                                                 % Channels as loaded from raw file.
                'order', order, ...                                                         % Indices of all channels, in autosorted order.
                'names', names(to_keep), ...                                                % Names of all valid channels, in autosorted order.
                'null_channels', find(to_discard), ...                                      % Indices of invalid channels in autosorted array.
                'as_rendered', Program.Debugging.Validation.noskip_test(order(to_keep)));   % Indices of all valid channels as rendered from processing array.
        end

        function idx_struct = indices(reset_flag)
            persistent channel_indices

            if isempty(channel_indices) || exist('reset_flag', 'var')
                metadata = DataHandling.Lazy.file.metadata;

                RGBWDG_active = Program.GUIHandling.active_channels;
                RGBWDG_idx = Program.GUIHandling.ordered_channels;

                channels_in_file = metadata.channels.order(metadata.channels.order~=metadata.channels.null_channels);
                full_load = Program.Debugging.Validation.render_indices(channels_in_file);

                lazy_load = channels_in_file(RGBWDG_active);
                lazy_load_permutation = ismember(lazy_load, RGBWDG_idx(RGBWDG_active));

                [~, render_permutation] = ismember(channels_in_file, RGBWDG_idx);
                render_permutation(render_permutation==0) = find(render_permutation==0);

                unrendered_RGB = find(~RGBWDG_active(1:3));

                channel_indices = struct( ...
                    'in_file', channels_in_file, ...
                    'full_load', full_load, ...
                    'lazy_load', channels_in_file(Program.GUIHandling.active_channels), ...
                    'lazy_load_permutation', lazy_load_permutation, ...
                    'render_permutation', render_permutation, ...
                    'unrendered_RGB', unrendered_RGB);
            end
            
            idx_struct = channel_indices;
        end
        
        function [sorted_names, sorted_idx] = sort(channels)
            channels = string(channels(:));
            n_names = numel(channels);
        
            f_ch_names_lower = lower(channels);
        
            labels_order = keys(DataHandling.channels.fluorophore_mapping);
        
            labels = strings(n_names, 1);
        
            for j = 1:numel(labels_order)
                key = labels_order{j};
                synonyms = DataHandling.channels.fluorophore_mapping(key);
                synonyms_lower = lower(string(synonyms{1}));
        
                is_match = ismember(f_ch_names_lower, synonyms_lower);
                labels(is_match) = key;
            end
        
            sorted_names = strings(0, 1);
            permute_record = [];
        
            for j = 1:numel(labels_order)
                key = labels_order{j};

                idx = find(labels == key);

                sorted_names = [sorted_names; channels(idx)];
                permute_record = [permute_record; idx];
            end
        
            unmatched_idx = find(labels == "");
            if ~isempty(unmatched_idx)
                sorted_names = [sorted_names; channels(unmatched_idx)];
                permute_record = [permute_record; unmatched_idx];
            end

            sorted_idx = Program.Debugging.Validation.noskip_test(permute_record);
        end
        
        function [valid_idx, invalid_idx] = validate(channels)
            invalid_idx = ismember(channels, DataHandling.channels.to_discard);
            valid_idx = ~ismember(channels, DataHandling.channels.to_discard);
        end
    end
end

