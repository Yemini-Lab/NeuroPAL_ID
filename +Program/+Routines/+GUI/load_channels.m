function load_channels(app, input)
            [ch_grid, ~] = Program.channel_handler.get_gui(app);
            n_rows = length(ch_grid.RowHeight);

            if isfile(input) || ischar(input) || isstring(input)
                [nc, names] = Program.channel_handler.channels_from_file(input);
            else
                names = input;
                nc = length(names);
            end

            [names, ~] = Program.channel_handler.autosort(names);

            % Create any missing grid rows.
            for row=n_rows:nc
                Program.channel_handler.create_channel(app, ch_grid);
            end

            % Delete any excess grid rows.
            for row=n_rows:-1:nc+1
                Program.channel_handler.delete_channel(app, row, 1, 0);
            end

            % Populate gui components.
            for c=1:nc
                if isprop(app, sprintf(Program.channel_handler.dd_string, c))
                    dd = app.(sprintf(Program.channel_handler.dd_string, c));
                else
                    target = Program.channel_handler.get_channel(app, c);
                    dd = target.gui.dd;
                end

                dd.Items = names;
                dd.Value = names{c};
            end
            
            % Style non-rgb gui components.
            non_rgb = keys(Program.channel_handler.fluorophore_mapping);
            non_rgb = non_rgb(4:end);
            for c=1:length(non_rgb)
                component = app.(sprintf(Program.channel_handler.rep_string, c+3));
                if isgraphics(component)
                    for item=1:length(component.Items)
                        style_idx = item+3;
                        rep_style = uistyle( ...
                            "FontColor", Program.channel_handler.label_colors{style_idx}, ...
                            "FontWeight", "bold", ...
                            "BackgroundColor", Program.channel_handler.channel_colors{style_idx});
                        addStyle(component, rep_style, "item", item);
                    end
                end
            end
        end
