close all

addpath('./Services');
addpath('./Domain');
addpath('./Algorithms');
addpath('./Filters');

tic % start stopwatch timer

% CONFIGURATION
% -->

% plot boxplots?
plotBoxplots = false;

% target excel file
xlsFileName = 'plv_p_values_all_in_one.xlsx';

% source dir for reading .mat files
dirName = './ResultsPLV';

% <--

matList = dir(fullfile(dirName, '**/*.mat'));
sheet = 1;

Excel = actxserver('excel.application');
WB = Excel.Workbooks.Add;
WS = WB.Worksheets;

matCount = numel(matList);
%matCount = 3; % for testing

for kk = 1:matCount
    load(fullfile(matList(kk).folder, matList(kk).name)); %nBackCalculator
    
    matFile = erase(matList(kk).name, '.mat');
    
    recs = numel(nBackCalculator); % all recordings
    % recs = 12; % 1-12 are 2019 recordings (eeeeeecx), 13-20 are 2020:
    % 13-18 recordings (cceeeeeexx....), 20 chs (6 EEG)
    % 19-20 (eee...ex), 20 chs (19 EEG)
    
    chList = {};
    origChList = {};
    
    % loop through recordings to gather channel list
    for ii = 1:recs
        origChList = union(origChList, nBackCalculator(ii).nBackResults.algorithm(1).nBack(2).channelLabels);
    end
    
    % remove non-EEG channels
    nonEEG = {'EOG', 'ECG', 'Ch', 'EXT'};
    for ii = 1:numel(origChList)
        if (~contains(origChList{ii}, nonEEG, 'IgnoreCase',true))
            chList{end+1} = origChList{ii}; % add automatically EEG chs
        end
    end
    
    %chList = {'Fp1', 'Fp2', 'C3', 'C4', 'O1', 'O2'}; % common subset
    %chList = {'Fp1', 'Fp2', 'F3', 'Fz', 'F4', 'P3', 'Pz', 'P4'}; % a subset of 19-channel setup
    
    % channels in 19-ch setup:
    %{'P7'}    {'P4'}    {'Cz'}    {'Pz'}    {'P3'}    {'P8'}    {'O1'}    {'O2'}
    %{'T8'}    {'F8'}    {'C4'}    {'F4'}    {'Fp2'}    {'Fz'}    {'C3'}
    %{'F3'}    {'Fp1'}    {'T7'}    {'F7'}    {'EXT'}
    
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
            
            rNames(end + 1) = strcat(modulatingChannel, '-', modulatedChannel);
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
        
    fprintf('Building Excel: %s, sheet: %s (%d/%d)\n', xlsFileName, matFile, kk, matCount);
    
    if (sheet > 1)
        WS.Add([], WS.Item(WS.Count));
    end
   
    sheetName = string(erase(matFile, 'nback_object_'));
    if (~isempty(sheetName))
        WS.Item(sheet).Name = sheetName;
    end
    
    WS.Item(sheet).Range('A1').value = string(matFile);
    
    row = 2;
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
    
    
    sheet = sheet + 1;
    
    % boxplot
    if (plotBoxplots)
        plotcounter = 0;
        maxplots = 6;
        for r = 1:numel(chList)
            for c = r:numel(chList)
                plvMedian=[];
                x=[];
                g=[];
                
                for n = 2:5 % 1-back..4-back
                    res = cleanedResults{r,c,n};
                    if (~isempty(res) && r ~= c)
                        plvMedian(r,c,n) = median(res);
                        x = [x ; res'];
                        
                        valMedian = sprintf('%.2f',plvMedian(r,c,n));
                        nBack = strcat(num2str(n-1), '-back (' , valMedian, ')');
                        gTmp = repmat(nBack, numel(res), 1);
                        g = [g ; gTmp];
                    end
                end
                if (r ~= c)
                    if (mod(plotcounter, maxplots) == 0)
                        figure
                    end
                    
                    subplot(ceil(maxplots/2),2,mod(plotcounter, maxplots)+1)
                    boxplot(x, g, 'OutlierSize', 2, 'Symbol', 'ro')
                    plotcounter = plotcounter + 1;
                    title([string(chList(r)) + '-' + string(chList(c))]);
                    sgtitle(strcat("PLV ", strrep(matFile,'_','-')));
                end
            end
        end
    end % if (plotBoxplots)
    
end % for kk = 1:matCount

WB.SaveAs(fullfile(pwd, xlsFileName));
WB.Close();
Excel.Quit();

toc % stop stopwatch timer