function Display_results_percentage(measurement,reference)

percentage = round(100*(measurement - reference)/reference);

if percentage <= 0
    cprintf([0.75,0,0],[num2str(percentage) '%%\n']);
elseif percentage == 0
    cprintf([0.75,0.5,0],[num2str(percentage) '%%\n']);
else
    cprintf([0,0.5,0],[num2str(percentage) '%%\n']);
end
end