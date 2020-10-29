%f = 0:0.5:49.5;
nr = 1;
pl = 1;

addpath('./Services');
addpath('./Domain');
addpath('./Algorithms');
addpath('./Filters');

tic % start stopwatch timer

load('./Results2/nback_object_pac_event.mat'); %nBackCalculator

recs = numel(nBackCalculator); % all recordings
%recs = 12; % 1-12 are 2019 recordings (eeeeeecx), 13-20 are 2020:
% 13-18 recordings (cceeeeeexx....), 20 chs (6 EEG)
% 19-20 (eee...ex), 20 chs (19 EEG)
startRec = 1;

startCh = 1;
chCount = 6;

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

xlsFileName = 'testi_2019_G1_PAC.xlsx';

warning('off', 'MATLAB:xlswrite:AddSheet');

sheet = 1;
for reg = startRec:recs
    fprintf('Filling Excel for recording: %s\n', nBackCalculator(reg).recordingName);
    row = 1;
    
    recName = string(nBackCalculator(reg).recordingName);
    header = {recName, '1vs2', '1vs3', '1vs4', '2vs3', '2vs4', '3vs4'};
    
    for i = 1:numel(header)
        solu = strcat(char(char('A')+i-1), num2str(row));
        writematrix(string(header{i}), xlsFileName, 'Sheet', sheet, 'Range', solu);
    end
    
    row = row + 1;
    for rCh = startCh:startCh+chCount-1
        for cCh = startCh:startCh+chCount-1
            solu = strcat('A', num2str(row));
            writematrix(string(channelLabels{reg}{rCh}+"/"+channelLabels{reg}{cCh}), xlsFileName, 'Sheet', sheet, 'Range', solu);
            for i = 1:6
                solu = strcat(char(65 + i), num2str(row));
                writematrix(squeeze(p(reg, rCh, cCh, i)), xlsFileName, 'Sheet', sheet, 'Range', solu);
            end
            row = row + 1;
        end
    end
    sheet = sheet + 1;
end

Excel = actxserver('excel.application');
WB = Excel.Workbooks.Open(fullfile(pwd, xlsFileName),0,false);

sheet = 1;
for reg = startRec:recs
    fprintf('Marking Excel for recording: %s\n', nBackCalculator(reg).recordingName);
    row = 1;
    for rCh = startCh:startCh+chCount-1
        for cCh = startCh:startCh+chCount-1
            row = row + 1;
            for n = 1:6
                solu = strcat(char(65 + n), num2str(row));
                if (squeeze(p(reg, rCh, cCh, n)) < 0.01) && (squeeze(h(reg, rCh, cCh, n)) == 1)
                    WB.Worksheets.Item(sheet).Range(solu).Interior.ColorIndex = 33;
                elseif (squeeze(p(reg, rCh, cCh, n)) < 0.01) && (squeeze(h(reg, rCh, cCh, n)) == -1)
                    WB.Worksheets.Item(sheet).Range(solu).Interior.ColorIndex = 45;
                end
            end
        end
    end
    sheet = sheet + 1;
end

WB.Save();
WB.Close();
Excel.Quit();

toc % stop stopwatch timer
