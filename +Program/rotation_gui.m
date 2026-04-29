classdef rotation_gui
    %ROTATION_GUI Deprecated compatibility shim for crop_rotate_gui.

    methods (Static)
        function varargout = draw(varargin)
            [varargout{1:nargout}] = Program.crop_rotate_gui.draw(varargin{:});
        end

        function varargout = update(varargin)
            [varargout{1:nargout}] = Program.crop_rotate_gui.update(varargin{:});
        end

        function varargout = trigger(varargin)
            [varargout{1:nargout}] = Program.crop_rotate_gui.trigger(varargin{:});
        end

        function varargout = preview_output(varargin)
            [varargout{1:nargout}] = Program.crop_rotate_gui.preview_output(varargin{:});
        end

        function varargout = close(varargin)
            [varargout{1:nargout}] = Program.crop_rotate_gui.close(varargin{:});
        end

        function varargout = apply_mask(varargin)
            [varargout{1:nargout}] = Program.crop_rotate_gui.apply_mask(varargin{:});
        end

        function varargout = layout_controls(varargin)
            [varargout{1:nargout}] = Program.crop_rotate_gui.layout_controls(varargin{:});
        end

        function varargout = configure_roi_constraints(varargin)
            [varargout{1:nargout}] = Program.crop_rotate_gui.configure_roi_constraints(varargin{:});
        end

        function varargout = get_drawing_area(varargin)
            [varargout{1:nargout}] = Program.crop_rotate_gui.get_drawing_area(varargin{:});
        end

        function varargout = constrain_position_to_viewport(varargin)
            [varargout{1:nargout}] = Program.crop_rotate_gui.constrain_position_to_viewport(varargin{:});
        end

        function varargout = constrain_to_viewport(varargin)
            [varargout{1:nargout}] = Program.crop_rotate_gui.constrain_to_viewport(varargin{:});
        end

        function varargout = get_edges(varargin)
            [varargout{1:nargout}] = Program.crop_rotate_gui.get_edges(varargin{:});
        end

        function varargout = get_corners(varargin)
            [varargout{1:nargout}] = Program.crop_rotate_gui.get_corners(varargin{:});
        end

        function varargout = set_text_control_position(varargin)
            [varargout{1:nargout}] = Program.crop_rotate_gui.set_text_control_position(varargin{:});
        end
    end
end
