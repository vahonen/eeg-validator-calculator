function saveChannelData(recording, process, filename)
channel = [];
for i = 1 : numel(recording.channel)
    channel(i).label = recording.channel(i).label;
    channel(i).sampleRate = recording.channel(i).sampleRate;
    channel(i).epochLengthInSamples = recording.channel(i).epochLengthInSamples;
    channel(i).epochOverlapInSamples = recording.channel(i).epochOverlapInSamples;
    channel(i).epochCount = recording.channel(i).epochCount;
    channel(i).invalidEpochCount = numel(recording.channel(i).invalidEpochs);
    channel(i).invalidEpochs = recording.channel(i).invalidEpochs;
    
    artefactStart = 0;
    artefactSegCount = 0;
    for jj = 1: numel(recording.channel(i).invalidEpochs)
        [startSample, endSample]= recording.channel(i).getEpochRange(recording.channel(i).invalidEpochs(jj));
        if (artefactStart == 0)
            artefactStart = startSample;
        end
        
        if (jj < numel(recording.channel(i).invalidEpochs))
            [nextStart, ~] = recording.channel(i).getEpochRange(recording.channel(i).invalidEpochs(jj+1));
        else
            nextStart = endSample + 2;
        end
        
        if (nextStart > endSample + 1)
            artefactSegCount = artefactSegCount + 1;
            channel(i).artefactSegStart(artefactSegCount) = (artefactStart - 1) * (1/recording.channel(i).sampleRate);
            channel(i).artefactSegDuration(artefactSegCount) = (endSample - artefactStart + 1) * (1/recording.channel(i).sampleRate);
            artefactStart = 0;
        end     
    end
    
    channel(i).artefactSegCount = artefactSegCount;
end

header.edfFile = recording.edfFile;
header.nbrOfChannels = numel(recording.channel);
header.processedChannels = process;

fulltime = [recording.header.startdate recording.header.starttime];
start = datetime(fulltime,'InputFormat','dd.MM.yyHH.mm.ss');
start = datetime(start, 'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSSSSSS'); %format used in XML annotations
header.start = start;

save(filename, 'channel', 'header');

end
