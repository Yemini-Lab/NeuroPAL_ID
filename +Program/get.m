function value = get(obj, keyword)
    if isprop(obj, keyword)
        value = obj.(keyword);
    else
        obj_class = class(obj);
        switch obj_class
            case 'volume'
                obj_identifier = obj.path;
            case 'channel'
                obj_identifier = obj.fluorophore;
        end

        error('%s object %s has no property %s.', obj_class, obj_identifier, keyword);
    end
end