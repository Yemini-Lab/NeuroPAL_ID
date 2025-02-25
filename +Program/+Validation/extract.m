function output = extract(input)
    switch class(input)
        case 'struct'
            fields = fieldnames(input);
            for f=1:length(fields)
                this_field = fields{f};
                input.(this_field) = Program.Validation.extract(input.(this_field));
            end
            output = input;

        case 'cell'
            if isscalar(input)
                output = input{1};
            else
                if isa(input{1}, 'double')
                    output = cell2mat(input);
                end
            end

        otherwise
            output = input;
    end
end

