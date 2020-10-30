%f = 0:0.5:49.5;
nr = 1;
pl = 1;

addpath('./Services');
addpath('./Domain');
addpath('./Algorithms');
addpath('./Filters');

tic % start stopwatch timer

load('./Results2/nback_object_2020_t_a_plus_b'); %nBackCalculator

recs = numel(nBackCalculator); % all recordings
% recs = 12; % 1-12 are 2019 recordings (eeeeeecx), 13-20 are 2020:
% 13-18 recordings (cceeeeeexx....), 20 chs (6 EEG)
% 19-20 (eee...ex), 20 chs (19 EEG)
startRec = 1;

startCh = 1; % CHECK!
chCount = 19; % CHECK!

p = zeros(recs, chCount, chCount, 6);
h = zeros(size(p));

for reg = startRec:recs
    fprintf('Calculating statistics for recording: %s\n', nBackCalculator(reg).recordingName);
    for r = startCh:startCh+chCount-1
        for c = startCh:startCh+chCount-1
            for n = 1:4 % 1..4-back
                nBackResult{n} = nBackCalculator(reg).nBackResults.algorithm(1).nBack(n+1).result{r,c};
            end
            
            [p(reg, r, c, 1), ~, stats] = ranksum(nBackResult{1}, nBackResult{2}, 'tail', 'both');
            h(reg, r, c, 1) =  sign(stats.zval);
            
            [p(reg, r, c, 2), ~, stats] = ranksum(nBackResult{1}, nBackResult{3}, 'tail', 'both');
            h(reg, r, c, 2) =  sign(stats.zval);
            
            [p(reg, r, c, 3), ~, stats] = ranksum(nBackResult{1}, nBackResult{4}, 'tail', 'both');
            h(reg, r, c, 3) =  sign(stats.zval);
            
            [p(reg, r, c, 4), ~, stats] = ranksum(nBackResult{2}, nBackResult{3}, 'tail', 'both');
            h(reg, r, c, 4) =  sign(stats.zval);
            
            [p(reg, r, c, 5), ~, stats] = ranksum(nBackResult{2}, nBackResult{4}, 'tail', 'both');
            h(reg, r, c, 5) =  sign(stats.zval);
            
            [p(reg, r, c, 6), ~, stats] = ranksum(nBackResult{3}, nBackResult{4}, 'tail', 'both');
            h(reg, r, c, 6) =  sign(stats.zval);
            
            channelLabels{reg} = nBackCalculator(reg).nBackResults.algorithm.nBack.channelLabels;
        end
    end
end

%return

xlsFileName = 'nback_object_2020_t_a_plus_b.xlsx';

Excel = actxserver('excel.application');
WB = Excel.Workbooks.Add;
WS = WB.Worksheets;

sheet = 1;

fprintf('Building Excel: %s \n', xlsFileName);
for reg = startRec:recs
    
    fprintf('Filling Excel for recording: %s\n', nBackCalculator(reg).recordingName);
    row = 1;
    recName = string(nBackCalculator(reg).recordingName);
    header = {recName, '1vs2', '1vs3', '1vs4', '2vs3', '2vs4', '3vs4'};
    
    for i = 1:numel(header)
        solu = strcat(char(char('A')+i-1), num2str(row));
        WS.Item(sheet).Range(solu).value = string(header{i});
    end
    
    for rCh = startCh:startCh+chCount-1
        for cCh = startCh:startCh+chCount-1
            row = row + 1;
            
            solu = strcat('A', num2str(row));
            WS.Item(sheet).Range(solu).value = string(channelLabels{reg}{rCh}+"/"+channelLabels{reg}{cCh});
            
            for n = 1:6
                solu = strcat(char(65 + n), num2str(row));
                WS.Item(sheet).Range(solu).value = squeeze(p(reg, rCh, cCh, n));
                if (squeeze(p(reg, rCh, cCh, n)) < 0.01) && (squeeze(h(reg, rCh, cCh, n)) == 1)
                    WS.Item(sheet).Range(solu).Interior.ColorIndex = 33;
                elseif (squeeze(p(reg, rCh, cCh, n)) < 0.01) && (squeeze(h(reg, rCh, cCh, n)) == -1)
                    WS.Item(sheet).Range(solu).Interior.ColorIndex = 45;
                end
            end
        end
    end
	
    if (reg < recs)
        WS.Add([], WS.Item(WS.Count));   
        sheet = sheet + 1;
    end
end

WB.SaveAs(fullfile(pwd, xlsFileName));
WB.Close();
Excel.Quit();

toc % stop stopwatch timer
