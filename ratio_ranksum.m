%f = 0:0.5:49.5;
nr = 1;
pl = 1;

load('.\Results\nback_object_CLI_intra_ch.mat'); %nBackCalculator

%recs = numel(nBackCalculator);

recs = 12; % 2019 recordings

p = zeros(recs, 6, 6);
h = zeros(size(p));

for reg = 1:recs
    for ch = 1:6        
        res_1 = nBackCalculator(reg).nBackResults.algorithm.nBack(2).channel(ch).event;
        res_1_psd = zeros(1, max(size(res_1)));
        for i = 1:max(size(res_1))
            res_1_psd(i) = res_1(i).result;
        end
        
        res_2 = nBackCalculator(reg).nBackResults.algorithm.nBack(3).channel(ch).event;
        res_2_psd = zeros(1, max(size(res_2)));
        for i = 1:max(size(res_2))
            res_2_psd(i) = res_2(i).result;
        end
        
        res_3 = nBackCalculator(reg).nBackResults.algorithm.nBack(4).channel(ch).event;
        res_3_psd = zeros(1, max(size(res_3)));
        for i = 1:max(size(res_3))
            res_3_psd(i) = res_3(i).result;
        end
        
        res_4 = nBackCalculator(reg).nBackResults.algorithm.nBack(5).channel(ch).event;
        res_4_psd = zeros(1, max(size(res_4)));
        for i = 1:max(size(res_4))
            res_4_psd(i) = res_4(i).result;
        end
        %m1 = median(res_1_psd,2); m2 = median(res_2_psd,2); m3 = median(res_3_psd,2); m4 = median(res_4_psd,2);
        [p(reg, ch, 1), ~, stats] = ranksum(res_1_psd, res_2_psd, 'tail', 'both'); 
        h(reg, ch, 1) =  sign(stats.zval);
        [p(reg, ch, 2), ~, stats] = ranksum(res_1_psd, res_3_psd, 'tail', 'both');
        h(reg, ch, 2) =  sign(stats.zval);
        [p(reg, ch, 3), ~, stats] = ranksum(res_1_psd, res_4_psd, 'tail', 'both');
        h(reg, ch, 3) =  sign(stats.zval);
        [p(reg, ch, 4), ~, stats] = ranksum(res_2_psd, res_3_psd, 'tail', 'both');
        h(reg, ch, 4) =  sign(stats.zval);
        [p(reg, ch, 5), ~, stats] = ranksum(res_2_psd, res_4_psd, 'tail', 'both'); 
        h(reg, ch, 5) =  sign(stats.zval);
        [p(reg, ch, 6), ~, stats] = ranksum(res_3_psd, res_4_psd, 'tail', 'both');
        h(reg, ch, 6) =  sign(stats.zval);
    end
end

row = 1;
for reg = 1:recs
    solu = strcat('A', num2str(row));
    writematrix(string(nBackCalculator(reg).recordingName), 'testi_3.xlsx', 'Sheet', 1, 'Range', solu);
    row = row + 1;
    for ch = 1:6
        solu = strcat('A', num2str(row));
        writematrix(string(nBackCalculator(reg).nBackResults.algorithm.nBack(2).channel(ch).label), 'testi_3.xlsx', 'Sheet', 1, 'Range', solu);
        for i = 1:6
            solu = strcat(char(65 + i), num2str(row));
            writematrix(squeeze(p(reg, ch, i)), 'testi_3.xlsx', 'Sheet', 1, 'Range', solu);
        end
        row = row + 1;
    end
end

Excel = actxserver('excel.application');
WB = Excel.Workbooks.Open(fullfile(pwd, 'testi_3.xlsx'),0,false);
for reg = 1:recs
    for ch = 1:6
        for n = 1:6
            solu = strcat(char(65 + n), num2str((reg - 1)*7 + 1 + ch));            
            if (squeeze(p(reg, ch, n)) < 0.01) && (squeeze(h(reg, ch, n)) == 1)
                WB.Worksheets.Item(1).Range(solu).Interior.ColorIndex = 33;
            elseif (squeeze(p(reg, ch, n)) < 0.01) && (squeeze(h(reg, ch, n)) == -1)
                WB.Worksheets.Item(1).Range(solu).Interior.ColorIndex = 45;
            end
        end
    end
end
    
WB.Save();
WB.Close();
Excel.Quit();
