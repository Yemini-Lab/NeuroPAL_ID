function writeTrackMate(t_gap, video_info, video_neurons, output_file, figure)
    template_file = 'Data\NeuroPAL\xmlTemplate.xml';

    fileID = fopen(template_file, 'r');
    plainXML = textscan(fileID, '%s', 'Delimiter', '\n');
    fclose(fileID);
    
    plainXML = plainXML{1};
    lineIndex = find(contains(plainXML, '<AllSpots'), 1);
    
    plaintext = splitlines(fileread(template_file));
    new_file = plaintext(1:lineIndex);
    
    sif_start = '          <SpotsInFrame frame="%.f">';
    spot_line = '\n            <Spot ID="%.f" name="%s" STD_INTENSITY_CH1="0" STD_INTENSITY_CH2="0" STD_INTENSITY_CH3="0" QUALITY="0" TOTAL_INTENSITY_CH3="0" POSITION_T="%.f" TOTAL_INTENSITY_CH2="0" TOTAL_INTENSITY_CH1="0" CONTRAST_CH1="0" FRAME="%.f" MEAN_INTENSITY_CH3="0" CONTRAST_CH3="0" CONTRAST_CH2="0" MEAN_INTENSITY_CH1="0" MAX_INTENSITY_CH2="0" MEAN_INTENSITY_CH2="0" MAX_INTENSITY_CH3="0" MAX_INTENSITY_CH1="0" MIN_INTENSITY_CH3="0" MIN_INTENSITY_CH2="0" MIN_INTENSITY_CH1="0" SNR_CH3="0" SNR_CH1="0" SNR_CH2="0" MEDIAN_INTENSITY_CH1="0" VISIBILITY="1" RADIUS="6.0" MEDIAN_INTENSITY_CH2="0" MEDIAN_INTENSITY_CH3="0" POSITION_X="%f" POSITION_Y="%f" POSITION_Z="%.f" />';
    sif_end = sprintf('\n            </SpotsInFrame>');

    idx = 0;
    nn = max(size(video_neurons));

    if exist('figure', 'var')
        d = uiprogressdlg(figure,'Title','Saving annotations...','Indeterminate','off');
    end

    for t=1:video_info.nt
        if exist('d', 'var')
            d.Value = t/video_info.nt;
        end

        new_frame = sprintf(sif_start, t+t_gap);
    
        for n=1:nn
            if exist('d', 'var')
                d.Value = min((t+n/nn)/video_info.nt, 1);
            end

            try
                name = video_neurons(n).worldline.name;
        
                x = video_neurons(n).rois(t+t_gap).x_slice;
                y = video_neurons(n).rois(t+t_gap).y_slice;
                z = video_neurons(n).rois(t+t_gap).z_slice;
    
                new_frame = [new_frame, sprintf(spot_line, idx, name, t+t_gap, t+t_gap, x, y, z)];
                idx = idx + 1;
            catch
                % ...
            end
        end

        if ~strcmp(new_frame, sprintf(sif_start, t+t_gap))
            new_file{end+1} = [new_frame, sif_end];
        end
    end
    
    new_file{lineIndex} = sprintf('        <AllSpots nspots="%.f">', idx);
    new_file = [new_file; plaintext(lineIndex+1:end)];
    writecell(new_file, output_file, FileType='text', QuoteStrings='none');

    if exist('d', 'var')
        close(d);
    end
end