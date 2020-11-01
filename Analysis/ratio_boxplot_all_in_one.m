%f = 0:0.5:49.5;
close all
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
chList = {'Fp1', 'Fp2'};
channelNbr = [];
allResults = {};
cliMedian = zeros(numel(chList),5);

for kk = 1:numel(chList)
    targetChannel = chList(kk);
    for reg = 1:recs
        chCount = numel(nBackCalculator(reg).nBackResults.algorithm(1).nBack(2).channel);
        chFound = false;
        for jj = 1:chCount
            label = nBackCalculator(reg).nBackResults.algorithm(1).nBack(2).channel(jj).label;
            if (strcmpi(label, targetChannel))
                channelNbr(reg) = jj;
                chFound = true;
                break;
            end
        end
        
        if (~chFound)
            channelNbr(reg) = 0;
        end
    end
    
    
    for n = 1:5
        x = [];
        for reg = 1:recs
            if (~isempty(nBackCalculator(reg).nBackResults.algorithm(1).nBack(n).channel) && channelNbr(reg) > 0)
                x = [x horzcat(nBackCalculator(reg).nBackResults.algorithm(1).nBack(n).channel(channelNbr(reg)).event(:).result)];
            end
        end
        
        allResults{n} = x;
    end
    
    x = [];
    g = [];
    
    for n = 1:5
        if (~isempty(allResults{n}))
            %res = allResults{jj};
            res = rmoutliers(allResults{n}, 'median');
            cliMedian(kk,n) = median(res);
            x = [x ; res'];
            nBack = strcat(num2str(n-1), '-back');
            gTmp = repmat(nBack, numel(res), 1);
            g = [g ; gTmp];
        end
    end
    figure
    boxplot(x, g)
    title(['CLI for ' + string(targetChannel) + ' (all recordings)']);
end % for jj = numel(targetChList)

cliMedian
toc