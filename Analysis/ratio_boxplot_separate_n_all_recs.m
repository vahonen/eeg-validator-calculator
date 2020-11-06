% dependency:
%   boxplotGroup.m
%   https://se.mathworks.com/matlabcentral/fileexchange/74437-boxplotgroup

close all

addpath('./Services');
addpath('./Domain');
addpath('./Algorithms');
addpath('./Filters');

tic % start stopwatch timer

load('./Results3/nback_object_2019_2020_intra_ch_cli_128_64_new.mat'); %nBackCalculator

recs = numel(nBackCalculator); % all recordings
% recs = 12; % 1-12 are 2019 recordings (eeeeeecx), 13-20 are 2020:
% 13-18 recordings (cceeeeeexx....), 20 chs (6 EEG)
% 19-20 (eee...ex), 20 chs (19 EEG)

chList = {'Fp1', 'Fp2', 'C3', 'C4', 'O1', 'O2'};
%chList = {'Fp1', 'Fp2'};
xOutlier = {};
channelNbr = [];

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
    
    % collect all n-specific CLI values in cell array
    cli = {};
    for reg = 1:recs
        for n = 1:5 % n=1 -> 0-back, ..., n=5 -> 4-back
            x = [];
            
            if (~isempty(nBackCalculator(reg).nBackResults.algorithm(1).nBack(n).channel) && channelNbr(reg) > 0)
                x = vertcat(nBackCalculator(reg).nBackResults.algorithm(1).nBack(n).channel(channelNbr(reg)).event(:).result);
            end
            
            xOutlier{reg, n} = x(isoutlier(x));
            x = rmoutliers(x, 'median'); % remove outliers % CHECK!
            cli{reg, n} = x;
            
        end
    end
    
    M = {};
    for n = 1:5
        maxSize = 0;
        for reg = 1:recs
            if (size(cli{reg, n},1) > maxSize)
                maxSize = size(cli{reg, n},1);
            end
        end
        M{n} = NaN(maxSize,recs);
    end
    
    X=[];
    for n = 1:5
        X = M{n};
        for reg = 1:recs
            X(1:length(cli{reg, n}), reg) = cli{reg,n};
        end
        M{n} = X;
    end
    
   %M(:,1) = []; % remove 0-back
   %M(:,4) = []; % remove 4-back
   
   regLabels = {};
   for reg = 1:recs
       %regLabels{reg} = ['reg ', num2str(reg)];
       label = nBackCalculator(reg).recordingName(3:8);
       
       regLabels{reg} = erase(label, '_');
   end
   
   % note indexing for M: 2 -> 1-back, 3 -> 2-back, ...
   % last color is "dummy", needed for gap between groups
   if (mod(kk-1,2) == 0)
    figure
   end
   
   subplot(2,1,mod(kk-1,2)+1)
   %subplot(6,1,kk)
   boxplotGroup({M{2} M{3} M{4}}, 'PrimaryLabels', {'1' '2' '3'}, 'secondaryLabels', regLabels, 'plotstyle', 'compact', 'Colors', ['r' 'k' 'b' 'c']);
   title(['P_{\theta} / P_{\alpha} (' + string(targetChannel) + ')']);
   
end % for kk = 1:numel(chList)

toc