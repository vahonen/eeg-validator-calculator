function saveXmlAnnotations(fileName, starttime, annotationData)

if (numel(annotationData) > 0)
    fid = fopen(fileName, 'w');
    fprintf(fid, '<?xml version="1.0" encoding="UTF-8"?>\n');
    fprintf(fid, '<annotationlist>\n');
    fprintf(fid, '<recording_start_time>%s</recording_start_time>\n', starttime);
    
    for i = 1 : numel(annotationData)
        fprintf(fid, '<annotation>\n');
        fprintf(fid, '<onset>%s</onset>\n', annotationData(i).onset);
        if (annotationData(i).duration > 0)
            fprintf(fid, '<duration>%.7f</duration>\n', annotationData(i).duration); % with 7 decimals (as in EDFbrowser created annotations)
        else
            fprintf(fid, '<duration></duration>\n');
        end
        fprintf(fid, '<description>%s</description>\n', annotationData(i).description);
        fprintf(fid, '</annotation>\n');
    end
    
    fprintf(fid, '</annotationlist>');
    fclose(fid);
end

end