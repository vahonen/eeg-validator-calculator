%f = 0:0.5:49.5;
nr = 1;
pl = 1;

addpath('./Services');
addpath('./Domain');
addpath('./Algorithms');
addpath('./Filters');

tic % start stopwatch timer

load('./Results3/nback_object_2019_2020_intra_ch_cli_128_64.mat'); %nBackCalculator

recs = numel(nBackCalculator); % all recordings
% recs = 12; % 1-12 are 2019 recordings (eeeeeecx), 13-20 are 2020:
% 13-18 recordings (cceeeeeexx....), 20 chs (6 EEG)
% 19-20 (eee...ex), 20 chs (19 EEG)
startRec = 1;

startCh = 1; % CHECK!

p = zeros(recs, 6, 6);
h = zeros(size(p));

for reg = startRec:recs
    
    chCount(reg) = numel(nBackCalculator(reg).nBackResults.algorithm(1).nBack(2).channel);
    for ch = startCh:startCh+chCount(reg)-1
        for n = 1:4 % 1..4-back
            nBackResult{n} = vertcat(nBackCalculator(reg).nBackResults.algorithm(1).nBack(n+1).channel(ch).event(:).result);
        end
            
        [p(reg, ch, 1), ~, stats] = ranksum(nBackResult{1}, nBackResult{2}, 'tail', 'both'); 
        h(reg, ch, 1) =  sign(stats.zval);
        [p(reg, ch, 2), ~, stats] = ranksum(nBackResult{1}, nBackResult{3}, 'tail', 'both');
        h(reg, ch, 2) =  sign(stats.zval);
        [p(reg, ch, 3), ~, stats] = ranksum(nBackResult{1}, nBackResult{4}, 'tail', 'both');
        h(reg, ch, 3) =  sign(stats.zval);
        [p(reg, ch, 4), ~, stats] = ranksum(nBackResult{2}, nBackResult{3}, 'tail', 'both');
        h(reg, ch, 4) =  sign(stats.zval);
        [p(reg, ch, 5), ~, stats] = ranksum(nBackResult{2}, nBackResult{4}, 'tail', 'both'); 
        h(reg, ch, 5) =  sign(stats.zval);
        [p(reg, ch, 6), ~, stats] = ranksum(nBackResult{3}, nBackResult{4}, 'tail', 'both');
        h(reg, ch, 6) =  sign(stats.zval);
    end
end

xlsFileName = '2019_2020_intra_ch_CLI_128_64.xlsx';

Excel = actxserver('excel.application');
WB = Excel.Workbooks.Add;
WS = WB.Worksheets;

sheet = 1;

fprintf('Building Excel: %s \n', xlsFileName);

row = 0;
for reg = startRec:recs
    row = row + 1;
    recName = string(nBackCalculator(reg).recordingName);
    header = {recName, '1vs2', '1vs3', '1vs4', '2vs3', '2vs4', '3vs4'};
    
    fprintf('Filling Excel for recording: %s \n', recName);
    
    for i = 1:numel(header)
        solu = strcat(char(char('A')+i-1), num2str(row));
        WS.Item(sheet).Range(solu).value = string(header{i});
    end
    
    for ch = startCh:startCh+chCount(reg)-1
        row = row + 1;
        solu = strcat('A', num2str(row));
        WS.Item(sheet).Range(solu).value = string(nBackCalculator(reg).nBackResults.algorithm.nBack(2).channel(ch).label);
       
        for n = 1:6
            solu = strcat(char(65 + n), num2str(row));
            WS.Item(sheet).Range(solu).value = squeeze(p(reg, ch, n));
            if (squeeze(p(reg, ch, n)) < 0.01) && (squeeze(h(reg, ch, n)) == 1)
                WS.Item(sheet).Range(solu).Interior.ColorIndex = 33;
            elseif (squeeze(p(reg, ch, n)) < 0.01) && (squeeze(h(reg, ch, n)) == -1)
                WS.Item(sheet).Range(solu).Interior.ColorIndex = 45;
            end
        end
    end
end

WB.SaveAs(fullfile(pwd, xlsFileName));
WB.Close();
Excel.Quit();