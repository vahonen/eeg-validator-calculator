function nBackEvents = readNBackEvents(folder, filename)

filename = strcat(fullfile(folder, filename), '.log');
line = {};
nBackEvents = [];

fid = fopen(filename);
while ~feof(fid)
    line{end + 1} = deblank(fgets(fid));
end
fclose(fid);

nExp = '(?<n>^\d+)-back game started';
dExp = '^Displayed number (?<dispNum>\d+)';
mExp = '^Mouse clicked';
tExp = ['(?<year>\d+)-(?<month>\d+)-(?<day>\d+) (?<hours>\d+):(?<minutes>\d+):(?<seconds>\d+).(?<fractions>\d+)'];

n = -1;
target = 0; % 0=non-target, 1=target
nbackEvents = [];
counter = 1;

for i = 1:numel(line)
    nBack = regexpi(line{i}, nExp ,'names');
    if(~isempty(nBack)) % n-back game started
        n = str2double(nBack.n);
    end
    
    dNum = regexpi(line{i}, dExp ,'names');
    if(~isempty(dNum)) % number displayed
        d = str2double(dNum.dispNum);
        if (n > -1)
            if (i - n > 0)
                tmpExp = "^Displayed number " + string(d);
                if(~isempty(regexpi(line{i-n}, tmpExp))) % target
                    target = 1;
                else
                    target = 0;
                end
            else
                target = 0;
            end
            
            if (i + 1 <= numel(line))
                if(~isempty(regexpi(line{i+1}, mExp))) % mouse clicked
                    clickTime = regexp(line{i+1}, tExp, 'names');
                    dtMouse = datetime(str2double(clickTime.year), str2double(clickTime.month), str2double(clickTime.day), ...
                        str2double(clickTime.hours), str2double(clickTime.minutes), str2double(clickTime.seconds), ...
                        (str2double(clickTime.fractions)*(10^(3-length(clickTime.fractions)))));
                    mouseClicked = 1;
                else
                    mouseClicked = 0;
                end
            else
                mouseClicked = 0;
            end
            
            dispTime = regexp(line{i}, tExp, 'names');
            timestampDisplay = [dispTime.year '-' dispTime.month '-' dispTime.day 'T' dispTime.hours ':' dispTime.minutes ':' ...
                dispTime.seconds '.' dispTime.fractions];
            dtDisplay = datetime(str2double(dispTime.year), str2double(dispTime.month), str2double(dispTime.day), ...
                        str2double(dispTime.hours), str2double(dispTime.minutes), str2double(dispTime.seconds), ...
                        (str2double(dispTime.fractions)*(10^(3-length(dispTime.fractions)))));
            nBackEvents(counter).n = n;
            nBackEvents(counter).displayedNumber = d;
            nBackEvents(counter).timestamp = timestampDisplay;
            nBackEvents(counter).dtTime = dtDisplay; % datetime
            nBackEvents(counter).target = target;
            nBackEvents(counter).mouseClicked = mouseClicked;
            if (mouseClicked)
                nBackEvents(counter).delay = seconds(dtMouse-dtDisplay);
            else
                nBackEvents(counter).delay = 0;
            end
            nBackEvents(counter).sampleRange = []; % to be filled in validation phase (validateEvents.m)
            counter = counter + 1;
        end
    end
    
end



end