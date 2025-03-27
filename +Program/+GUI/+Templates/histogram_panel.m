classdef histogram_panel < dynamicprops
    %HISTOGRAM_PANEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        channel;
        parent_panel;
        parent_grid;
        histogram_axes;
        histogram_slider;
        title_panel;
        title_grid;
        ef_label;
        gamma_ef;
        title_label;
    end
    
    methods
        function obj = histogram_panel(parent_container)
            if nargin == 0
                app = Program.app;
                parent_container = app.ProcHistogramGrid;
            end

            % Create obj.parent_panel
            obj.parent_panel = uipanel(parent_container);
            obj.parent_panel.BorderType = 'none';
            obj.parent_panel.Layout.Row = 1;
            obj.parent_panel.Layout.Column = 2;

            % Create obj.parent_grid
            obj.parent_grid = uigridlayout(obj.parent_panel);
            obj.parent_grid.ColumnWidth = {17, '1x'};
            obj.parent_grid.RowHeight = {'fit', '1x', 'fit'};
            obj.parent_grid.ColumnSpacing = 0;
            obj.parent_grid.RowSpacing = 0;
            obj.parent_grid.Padding = [0 10 0 0];

            % Create obj.histogram_axes
            obj.histogram_axes = uiaxes(obj.parent_grid);
            zlabel(obj.histogram_axes, 'Z')
            obj.histogram_axes.Toolbar.Visible = 'off';
            obj.histogram_axes.XLim = [1 255];
            obj.histogram_axes.MinorGridLineStyle = '-';
            obj.histogram_axes.YScale = 'log';
            obj.histogram_axes.YMinorTick = 'on';
            obj.histogram_axes.Color = [0.651 0.651 0.651];
            obj.histogram_axes.GridColor = [0.502 0.502 0.502];
            obj.histogram_axes.MinorGridColor = [0.502 0.502 0.502];
            obj.histogram_axes.XMinorGrid = 'on';
            obj.histogram_axes.Layout.Row = 2;
            obj.histogram_axes.Layout.Column = [1 2];

            % Create obj.histogram_slider
            obj.histogram_slider = uislider(obj.parent_grid, 'range');
            obj.histogram_slider.MajorTicks = [];
            obj.histogram_slider.ValueChangedFcn = @(obj, event)(Program.GUI.Panels.histograms.trigger_update(obj, 'slider', event.Value));
            obj.histogram_slider.ValueChangingFcn = @(obj, event)(Program.GUI.Panels.histograms.trigger_update(obj, 'slider', event.Value));
            obj.histogram_slider.MinorTicks = [];
            obj.histogram_slider.Enable = 'off';
            obj.histogram_slider.Layout.Row = 3;
            obj.histogram_slider.Layout.Column = 2;

            % Create obj.title_panel
            obj.title_panel = uipanel(obj.parent_grid);
            obj.title_panel.BorderType = 'none';
            obj.title_panel.Layout.Row = 1;
            obj.title_panel.Layout.Column = 2;

            % Create obj.title_grid
            obj.title_grid = uigridlayout(obj.title_panel);
            obj.title_grid.ColumnWidth = {2, 'fit', '1x', 'fit', 'fit', 2};
            obj.title_grid.RowHeight = {'fit'};
            obj.title_grid.ColumnSpacing = 3;
            obj.title_grid.Padding = [0 0 0 0];

            % Create obj.ef_label
            obj.ef_label = uilabel(obj.title_grid);
            obj.ef_label.HorizontalAlignment = 'right';
            obj.ef_label.Layout.Row = 1;
            obj.ef_label.Layout.Column = 4;
            obj.ef_label.Text = 'Gamma:';
            
            % Create obj.gamma_ef
            obj.gamma_ef = uieditfield(obj.title_grid, 'numeric');
            obj.gamma_ef.Value = 0.8;
            obj.gamma_ef.ValueChangedFcn = @(obj, event)(Program.GUI.Panels.histograms.trigger_update(obj, 'gamma', event.Value));
            obj.gamma_ef.Enable = 'off';
            obj.gamma_ef.Layout.Row = 1;
            obj.gamma_ef.Layout.Column = 5;

            % Create obj.title_label
            obj.title_label = uilabel(obj.title_grid);
            obj.title_label.VerticalAlignment = 'bottom';
            obj.title_label.FontSize = 14;
            obj.title_label.FontWeight = 'bold';
            obj.title_label.Layout.Row = 1;
            obj.title_label.Layout.Column = 2;
            obj.title_label.Text = '{Ch} Channel';
        end

        function obj = move(obj, varargin)
            p = inputParser();
            addParameter(p, 'Parent', []);
            addParameter(p, 'Row', []);
            addParameter(p, 'Column', []);
            parse(p, varargin{:});

            for n=1:length(p.Parameters)
                argument = p.Parameters{n};
                if ~ismember(argument, p.UsingDefaults)
                    switch argument
                        case {'Row', 'Column'}
                            obj.parent_panel.Layout.(argument) = p.Results.(argument);

                        otherwise
                            obj.parent_panel.(argument) = p.Results.(argument);
                    end
                end
            end
        end

        function obj = load(obj, channel, array)
            if ~isa(channel, "Program.channel")
                return
            end

            app = Program.app;
            obj.channel = channel;
            obj.title_label.Text = sprintf("%s Channel", ...
                channel.fluorophore);

            histogram(obj.histogram_axes, array(:), ...
                'FaceColor', channel.color, ...
                'EdgeColor', channel.color);

            obj.histogram_axes.XLim(1) = ...
                app.HidezerointensitypixelsCheckBox.Value;
        end

        function obj = lock(obj, state)
            obj.batch_properties('Enable', state);
        end

        function obj = enable(obj)
            obj.batch_properties('Visible', 'on');
        end

        function obj = disable(obj)
            obj.batch_properties('Visible', 'off');
        end
    end

    methods (Access = private)
        function obj = set_layout(obj, component, property, value)
            component.Layout.(property) = value;
        end

        function obj = batch_function(obj, callable_reference)
            obj_class = ?Program.GUI.Templates.histogram_panel;
            for p=1:length(obj_class.PropertyList)
                prop = obj_class.PropertyList(p).Name;
                callable_reference(obj.(prop));
            end
        end

        function obj = batch_properties(obj, keyword, value)
            obj_class = ?Program.GUI.Templates.histogram_panel;
            for p=1:length(obj_class.PropertyList)
                prop = obj_class.PropertyList(p).Name;
                if isprop(obj.(prop), keyword)
                    obj.(prop).(keyword) = value;
                end
            end
        end
    end
end

