classdef subject
    %SUBJECT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        subj_sex = [];
        subj_age = [];
        subj_body = [];
        subj_strain = [];
        subj_notes = [];
    end
    
    methods
        function obj = subject(metadata)
            if nargin ~= 0
                obj.load_from_struct(metadata);
            end
        end
        
        function value = sex(obj)
            value = obj.get('subj_sex');
        end
        
        function value = age(obj)
            value = obj.get('subj_age');
        end
        
        function value = body(obj)
            value = obj.get('subj_body');
        end
        
        function value = strain(obj)
            value = obj.get('subj_strain');
        end
        
        function value = notes(obj)
            value = obj.get('subj_notes');
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

                value = obj.(sprintf('subj_%s', lower(subject_property)));

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
            obj.subj_sex = metadata.subject.sex;
            obj.subj_age = metadata.subject.age;
            obj.subj_body = metadata.subject.body;
            obj.subj_strain = metadata.subject.strain;
            obj.subj_notes = metadata.subject.notes;
        end
    end
end

