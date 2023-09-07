function Display_results(measurement,threshold)
if measurement >= threshold
    cprintf([0,0.5,0],['+' num2str(measurement) '\n']);
elseif abs(measurement - threshold) == 0
    cprintf([0.75,0.5,0],[num2str(measurement) '\n']);
else
    cprintf([0.75,0,0],[num2str(measurement) '\n']);
end
end