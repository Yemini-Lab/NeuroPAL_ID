function time_string = get_time_string(start_time, count, total)
    time_diff = convertTo(datetime("now"), 'epochtime', 'Epoch', start_time);
    second_diff = double(time_diff) / count;
    
    if second_diff < 0.1
        time_diff = (time_diff*60)/count;
        time_unit = 'ms';
        c_exp = 2;
    else
        time_diff = second_diff;
        time_unit = 'sec';
        c_exp = 1;
    end
    
    if ~exist('total', 'var')
        time_string = sprintf("(%.2f %s/ea)", time_diff, time_unit);
    else
        time_left = (time_diff/(60^c_exp)) * (total-count);
        time_string = sprintf("(%.2f %s/ea, ~%.f min left)", time_diff, time_unit, time_left);
    end
end

