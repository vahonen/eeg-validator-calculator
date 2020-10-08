function createStimulusXmlAnnotations(recording, logFile, fileName)

starttime = recording.header.starttime; %hh.mm.ss
startdate = recording.header.startdate; %dd.mm.yy

% time format for XML: yyyy-mm-ddThh:MM:ss.fff0000
% e.g. 2017-04-07T13:34:15.0290000

fulltime = [startdate starttime];
start = datetime(fulltime,'InputFormat','dd.MM.yyHH.mm.ss');
start = datetime(start, 'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSSSSSS'); %format used in XML

annotationData = [];
counter = 1;

fid = fopen(logFile, 'r');
while ~feof(fid)
    line = fgets(fid);
    
    % logfile format (example):
    %Space Invaders - Game started at: 2020-01-17 15:31:55.339071
    %1 Level: 2020-01-17 15:31:55.342587
    %D hook for the EEG analysis: 2020-01-17 15:31:55.342587
    %M Player got hit: 2020-01-17 15:32:19.629440
    % NOTE: timetamps in logfiles MUST follow above expression!
    
    expression = ['(?<year>\d+)-(?<month>\d+)-(?<day>\d+) (?<hours>\d+):(?<minutes>\d+):(?<seconds>\d+).(?<fractions>\d+)'];
    onset = regexp(line, expression, 'names');
    
    if (~isempty(onset))
        expression = ['(?<year>\d+)-(?<month>\d+)-(?<day>\d+)'];
        dateStart = regexp(line, expression);
        charLine = char(line);
        
        annotationData(counter).description = charLine(1:dateStart - 1);
        annotationData(counter).duration = 0;
        annotationData(counter).onset = [onset.year '-' onset.month '-' onset.day 'T' onset.hours ':' onset.minutes ':' ...
           onset.seconds '.' onset.fractions];
       
       counter = counter + 1;
    end
    
end

fclose(fid);

if (~isempty(annotationData))
     saveXmlAnnotations(strcat(fileName, '_stimulus.xml'), start, annotationData);
end

end
