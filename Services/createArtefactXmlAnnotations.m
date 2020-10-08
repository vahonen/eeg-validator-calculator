function createArtefactXmlAnnotations(recording, fileName)
channel = recording.channel;
starttime = recording.header.starttime; %hh.mm.ss
startdate = recording.header.startdate; %dd.mm.yy

% time format for XML: yyyy-mm-ddThh:MM:ss.fff0000
% e.g. 2017-04-07T13:34:15.0290000

fulltime = [startdate starttime];
start = datetime(fulltime,'InputFormat','dd.MM.yyHH.mm.ss');
start = datetime(start, 'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSSSSSS'); %format used in XML

for i = 1 : numel(channel)
    label = channel(i).label;
    invalidEpochs = channel(i).invalidEpochs;
    sampleRate = channel(i).sampleRate;
    
    counter = 1;
    artefactStart = 0;
    annotationData = [];
    for jj = 1 : numel(invalidEpochs)
        [startSample, endSample] = channel(i).getEpochRange(invalidEpochs(jj));
        if (artefactStart == 0)
            artefactStart = startSample;
        end
        
        if (jj < numel(invalidEpochs))
            [nextStart, ~] = channel(i).getEpochRange(invalidEpochs(jj+1));
        else % last invalid epoch
            nextStart = endSample + 2;
        end
        
        if (nextStart > endSample + 1)
            annotationData(counter).onset = start + seconds((artefactStart - 1) * (1/sampleRate));
            annotationData(counter).duration = (endSample - artefactStart + 1) * (1/sampleRate);
            annotationData(counter).description = ['Artefact seg on ' label];
            counter = counter + 1;
            artefactStart = 0;
        end
    end
    
    saveXmlAnnotations(strcat(fileName, '_', label, '_artefacts.xml'), start, annotationData);
end

end
