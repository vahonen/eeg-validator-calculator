% function validates (game) events that do not overlap
% with artefactual segments

function validEvents = validateEvents(gameEvents, startTime, channelData, eventAdvance, eventDelay, sampleCount)

%validEvents={};
counter = 1;
dtStartTime = datetime(string(startTime), 'InputFormat','yy-MM-dd''T''HH:mm:ss.SSSSSS');
sampleRate = channelData.sampleRate;
if (isempty(gameEvents))
    fprintf("###### No events in game log or events are not in correct format.\n");
    validEvents = {};
end
for i = 1:numel(gameEvents)
    % timestamp format (ISO8601); '2017-04-07T14:25:14.685451'
    evTimestamp = gameEvents(i).timestamp;
    dtEvTimestamp = datetime(evTimestamp, 'InputFormat','yy-MM-dd''T''HH:mm:ss.SSSSSS');
    
    segStart = dtEvTimestamp - seconds(eventAdvance/1000); % ms -> s
    segEnd = dtEvTimestamp + seconds(eventDelay/1000); % ms -> s
    
    dtArtefactSegStart = dtStartTime + seconds(channelData.artefactSegStart);
    
    % if seg_start < artefact_end AND seg_end > artefact_start
    % => artefact is overlapping with segment
    
    overlapFound = false;
    for jj = 1:numel(dtArtefactSegStart)
        artStart = dtArtefactSegStart(jj);
        artEnd = dtArtefactSegStart(jj) + seconds(channelData.artefactSegDuration(jj));
     
        if ((segStart < artEnd) && (segEnd > artStart))
           % segment overlaps with artefact
           overlapFound = true;
           break;
        end
        
        if (artStart > segEnd) % no need to check further as no overlaps ahead
            break;
        end
    end
    
    if (~overlapFound)
        allsGood = true;
        % set sample range for event segment
        offsetStart = seconds(segStart - dtStartTime); % seconds in numeric value
        offsetEnd = seconds(segEnd - dtStartTime); % seconds in numeric value
        
        startSample = floor(sampleRate * offsetStart) + 1;
        endSample = min(floor(sampleRate * offsetEnd) + 1, sampleCount); % corr: ceil->floor, + 1
        
        if (offsetStart < 0)
            fprintf("###### Event taking place before edf recording starts, event start sample: %d\n", startSample);
            allsGood = false;
        end
        
        if (startSample > sampleCount)
            fprintf("###### Event taking place after edf recording end (%d samples), event start sample: %d\n", sampleCount, startSample);
            allsGood = false;
        end
        
        if (abs(endSample - startSample - ceil(sampleRate*(eventAdvance + eventDelay)/1000)) > 1) % allow +-1 sample deviation (due to rounding)
            fprintf("###### Invalid event length, start: %d, end: %d\n", startSample, endSample);
            allsGood = false;
        end
        
        if (allsGood)
           validEvents(counter) = gameEvents(i); 
           validEvents(counter).sampleRange = [startSample endSample];
           counter = counter + 1;
        end
    else
        % !debug!
        %fprintf("###### Event overlapping with artefact\n");
        %disp(gameEvents(i));
        %disp(artStart);
        %disp(artEnd);
       
    end
end

end