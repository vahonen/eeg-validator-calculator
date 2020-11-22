%f = 0:0.5:49.5;
close all

addpath('./Services');
addpath('./Domain');
addpath('./Algorithms');
addpath('./Filters');

tic % start stopwatch timer

matFile = 'nback_object_2-4';
dirName = './ResultsPLV';

fileName = strcat(matFile, '.mat');
load(fullfile(dirName, fileName)); %nBackCalculator


recs = numel(nBackCalculator); % all recordings
% recs = 12; % 1-12 are 2019 recordings (eeeeeecx), 13-20 are 2020:
% 13-18 recordings (cceeeeeexx....), 20 chs (6 EEG)
% 19-20 (eee...ex), 20 chs (19 EEG)

chList = {};
origChList = nBackCalculator(1).nBackResults.algorithm(1).nBack(2).channelLabels;

nonEEG = {'EOG', 'ECG', 'Ch', 'EXT'};

for ii = 1:numel(origChList)
    if (~contains(origChList{ii}, nonEEG, 'IgnoreCase',true))
        chList{end+1} = origChList{ii};
    end
end
% remove non-EEG channels

origResults = {};
cleanedResults = {};
p = [];
h = [];
pValues = [];
count = 1;
pTable = table;
rNames = {};

for r = 1:numel(chList)
    for c = 1:numel(chList)
        modulatingChannel = chList(r);
        modulatedChannel = chList(c);
        
        
        rNames(end + 1) = strcat(modulatingChannel, modulatedChannel);
        for n = 1:5
            x = [];
            for reg = 1:recs
                labels = nBackCalculator(reg).nBackResults.algorithm(1).nBack(n).channelLabels;
                [~, rx] = ismember(modulatingChannel, labels);
                [~, cx] =ismember(modulatedChannel, labels);
                
                if (numel(nBackCalculator(reg).nBackResults.algorithm(1).nBack(n).result) > 0 && rx > 0 && cx > 0)
                    y = horzcat(nBackCalculator(reg).nBackResults.algorithm(1).nBack(n).result{rx,cx});
                    x = [x y]; % PLV values for level n, between chs "r" and "c"
                end
            end
            
            origResults{r,c,n} = x;
            cleanedResults{r,c,n} = rmoutliers(x, 'median');
        end
        
        [p(r,c,1), ~, stats] = ranksum(cleanedResults{r,c,2}, cleanedResults{r,c,3}, 'tail', 'both');
        h(r, c, 1) =  sign(stats.zval);
        [p(r,c,2), ~, stats] = ranksum(cleanedResults{r,c,2}, cleanedResults{r,c,4}, 'tail', 'both');
        h(r, c, 2) =  sign(stats.zval);
        [p(r,c,3), ~, stats] = ranksum(cleanedResults{r,c,2}, cleanedResults{r,c,5}, 'tail', 'both');
        h(r, c, 3) =  sign(stats.zval);
        [p(r,c,4), ~, stats] = ranksum(cleanedResults{r,c,3}, cleanedResults{r,c,4}, 'tail', 'both');
        h(r, c, 4) =  sign(stats.zval);
        [p(r,c,5), ~, stats] = ranksum(cleanedResults{r,c,3}, cleanedResults{r,c,5}, 'tail', 'both');
        h(r, c, 5) =  sign(stats.zval);
        [p(r,c,6), ~, stats] = ranksum(cleanedResults{r,c,4}, cleanedResults{r,c,5}, 'tail', 'both');
        h(r, c, 6) =  sign(stats.zval);
        
        pValues(count, :) = squeeze(p(r,c,:))';
        count = count + 1;
        
    end
end

vNames = {'n1vsn2', 'n1vsn3', 'n1vsn4', 'n2vsn3', 'n2vsn4', 'n3vsn4'};
pTable = array2table(pValues, 'VariableNames', vNames, 'RowNames', rNames);

xlsFileName = strcat(matFile, '_all', '.xlsx');

Excel = actxserver('excel.application');
WB = Excel.Workbooks.Add;
WS = WB.Worksheets;

sheet = 1;

fprintf('Building Excel: %s \n', xlsFileName);

row = 1;
header = {'1vs2', '1vs3', '1vs4', '2vs3', '2vs4', '3vs4'};
for i = 1:numel(header)
    solu = strcat(char(char('A')+i), num2str(row));
    WS.Item(sheet).Range(solu).value = string(header{i});
end

count = 1;
for r = 1:numel(chList)
    for c = 1:numel(chList)
        row = row + 1;
        solu = strcat('A', num2str(row));
        WS.Item(sheet).Range(solu).value = string(rNames{count});
        for n = 1:6
            solu = strcat(char(65 + n), num2str(row));
            WS.Item(sheet).Range(solu).value = squeeze(p(r, c, n));
            if ((squeeze(p(r, c, n)) < 0.01) && (squeeze(h(r, c, n)) == 1))
                WS.Item(sheet).Range(solu).Interior.ColorIndex = 33;
            elseif ((squeeze(p(r, c, n)) < 0.01) && (squeeze(h(r, c, n)) == -1))
                WS.Item(sheet).Range(solu).Interior.ColorIndex = 45;
            end
        end
        count = count + 1;
    end
end

WB.SaveAs(fullfile(pwd, xlsFileName));
WB.Close();
Excel.Quit();

