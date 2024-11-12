classdef channels
    
    properties (Constant)
        max_channels = 6;

        channel_names = {'r', 'g', 'b', 'w', 'dic', 'gfp', ...
            'red', 'green', 'blue', 'white', 'DIC', 'GFP'};

        channel_map = containers.Map( ...
            {'r', 'g', 'b', 'w', 'dic', 'gfp', ...
            'red', 'green', 'blue', 'white', 'DIC', 'GFP'}, ...
            [1, 2, 3, 4, 5, 6, ...
            1, 2, 3, 4, 5, 6]);

        dd_string = "Proc%sDropDown";
        cb_string = "Proc%sCheckBox";
    end
    
    methods (Static)
        function [idx, ch_idx, ch_bools] = render_idx()
            ch_idx = Program.Handlers.channels.idx;
            ch_bools = Program.handlers.channels.bools;
            idx = Program.Helpers.indices_to_render(ch_idx(ch_bools));
        end
        
        function channel_bools = bools()
            gui = Program.Handlers.channels.gui;
            channel_bools =  logical([ ...
                gui.R.cb.Value ...
                gui.G.cb.Value ...
                gui.B.cb.Value ...
                gui.W.cb.Value ...
                gui.DIC.cb.Value ...
                gui.GFP.cb.Value]);
        end
        
        function idx = idx()
            gui = Program.Handlers.channels.gui;
            idx = [ ...
                str2num(gui.R.dd.Value) ...
                str2num(gui.G.dd.Value) ...
                str2num(gui.B.dd.Value) ...
                str2num(gui.W.dd.Value) ...
                str2num(gui.DIC.dd.Value) ...
                str2num(gui.GFP.dd.Value)];
        end

        function name = idx_to_name(idx)
            indices = Program.Handlers.channels.idx;
            name = Program.Handlers.channels.channel_names{indices==idx};
        end
    end

    methods (Static, Access = private)
        function obj = gui()
            persistent handle_struct

            if isempty(handle_struct)
                app = Program.GUIHandling.app;
                channel_strings = {Program.Handlers.channels.channel_names{1:6}};
    
                for n=1:length(channel_strings)
                    channel = upper(channel_strings{n});
    
                    dropdown = sprintf(Program.Handlers.channels.dd_string, channel);
                    checkbox = sprintf(Program.Handlers.channels.cb_string, channel);
    
                    channel_struct = struct( ...
                        'dd', {app.(dropdown)}, ...
                        'cb', {app.(checkbox)});
    
                    if ~exist('handle_struct', 'var')
                        handle_struct = struct(channel, channel_struct);
    
                    else
                        handle_struct.(channel) = channel_struct;
                    end
                end
            end

            obj = handle_struct;
        end
    end
end

