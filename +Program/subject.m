classdef subject
    %SUBJECT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        sex = [];
        age = [];
        body = [];
        strain = [];
        notes = [];
    end
    
    methods
        function obj = subject(metadata)
            if nargin ~= 0
                obj.load_from_struct(metadata);
            end
        end

        function set(obj, keyword, value)
            if isprop(obj, keyword)
                obj.(keyword) = value;
            end
        end

        function validate(obj)
            window = Program.window;
            validation_map = Program.config.valid_subject_properties;
            subject_properties = keys(validation_map);

            for c=1:length(subject_properties)
                subject_property = subject_properties{c};

                value = obj.(lower(subject_property));

                if ~any(strcmp(value, validation_map{subject_property}))
                    message = sprintf('Unrecognized worm %s %s!', lower(subject_property), value);
                    uialert(window, message, 'Validation Failure', 'Icon', 'error');
                    return;
                end
            end
        end
    end

    methods (Access = private)
        function value = get(obj, keyword)
            if isprop(obj, keyword)
                value = obj.(keyword);
            else
                value = '';
            end
        end

        function obj = load_from_struct(obj, metadata)
            obj.sex = metadata.subject.sex;
            obj.age = metadata.subject.age;
            obj.body = metadata.subject.body;
            obj.strain = metadata.subject.strain;
            obj.notes = metadata.subject.notes;
        end
    end
end

