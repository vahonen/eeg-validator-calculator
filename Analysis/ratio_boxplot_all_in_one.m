%f = 0:0.5:49.5;
close all

addpath('./Services');
addpath('./Domain');
addpath('./Algorithms');
addpath('./Filters');

tic % start stopwatch timer

load('./Results/nback_object.mat'); %nBackCalculator

recs = numel(nBackCalculator); % all recordings
% recs = 12; % 1-12 are 2019 recordings (eeeeeecx), 13-20 are 2020:
% 13-18 recordings (cceeeeeexx....), 20 chs (6 EEG)
% 19-20 (eee...ex), 20 chs (19 EEG)

%chList = {'Fp1', 'Fp2'};
chList = {'Fp1', 'Fp2', 'C3', 'C4', 'O1', 'O2'};

channelNbr = [];
allResults = {};
ratioMedian = zeros(numel(chList),5);
figure

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
            % CHECK!
            %if (~ismember(reg, [4 6 15 16])) % remove recs 4,6,15,16 => these have very high values compared to the rest
                if (~isempty(nBackCalculator(reg).nBackResults.algorithm(1).nBack(n).channel) && channelNbr(reg) > 0)
                    y = horzcat(nBackCalculator(reg).nBackResults.algorithm(1).nBack(n).channel(channelNbr(reg)).event(:).result);
                    %y = rmoutliers(y, 'median'); % CHECK!
                    x = [x y];
                end
            %end
        end
        
        allResults{kk,n} = x; %(x<=26); % !CHECK
    end
    
    x = [];
    g = [];
    
    for n = 1:5
        if (~isempty(allResults{kk,n}))
            res = allResults{kk,n};
            xOutliers{kk,n} = res(isoutlier(res));
            
            res = rmoutliers(res, 'median'); % CHECK!
            ratioMedian(kk,n) = median(res);
            
            
            x = [x ; res'];
            
            valMedian = sprintf('%.2f',ratioMedian(kk,n));
            nBack = strcat(num2str(n-1), '-back (' , valMedian, ')');
            gTmp = repmat(nBack, numel(res), 1);
            g = [g ; gTmp];
        end
    end
    
    count=numel(chList);
    % two plots per figure
    %if (kk > 1 && mod(kk-1, 2) == 0)
    %    figure
    %end
    
    %subplot(2,1,mod(kk-1, 2)+1)
    
    subplot(ceil(count/2),2,kk)
    boxplot(x, g, 'OutlierSize', 2, 'Symbol', 'ro')
    %boxplot(x, g, 'PlotStyle', 'compact')
    title(['P_{\theta} / P_{\alpha} (' + string(targetChannel) + ')']);
   
    ylim([0 30]);
    
    %subplot(2,2,kk+2)
    %histogram(x)
    %title(['P_{\theta} / P_{\alpha} (' + string(targetChannel) + ' , all recordings combined)']);
    
    [p(kk,1), h(kk,1)] = ranksum(allResults{kk,2}, allResults{kk,3}, 'tail', 'left');
    [p(kk,2), h(kk,2)] = ranksum(allResults{kk,2}, allResults{kk,4}, 'tail', 'left');
    [p(kk,3), h(kk,3)] = ranksum(allResults{kk,2}, allResults{kk,5}, 'tail', 'left');
    [p(kk,4), h(kk,4)] = ranksum(allResults{kk,3}, allResults{kk,4}, 'tail', 'left');
    [p(kk,5), h(kk,5)] = ranksum(allResults{kk,3}, allResults{kk,5}, 'tail', 'left');
    [p(kk,6), h(kk,6)] = ranksum(allResults{kk,4}, allResults{kk,5}, 'tail', 'left');

%     just for testing the t-test... 
%     [h(kk,1), p(kk,1)] = ttest2(allResults{kk,2}, allResults{kk,3}, 'tail', 'left');
%     [h(kk,2), p(kk,2)] = ttest2(allResults{kk,2}, allResults{kk,4}, 'tail', 'left');
%     [h(kk,3), p(kk,3)] = ttest2(allResults{kk,2}, allResults{kk,5}, 'tail', 'left');
%     [h(kk,4), p(kk,4)] = ttest2(allResults{kk,3}, allResults{kk,4}, 'tail', 'left');
%     [h(kk,5), p(kk,5)] = ttest2(allResults{kk,3}, allResults{kk,5}, 'tail', 'left');
%     [h(kk,6), p(kk,6)] = ttest2(allResults{kk,4}, allResults{kk,5}, 'tail', 'left');
    
    
    
end % for kk = numel(targetChList)
%sgtitle(['P_{\theta} / P_{\alpha} (all recordings combined)']);

% for kk = 1:numel(chList)
%     figure
%     for n = 2:5
%         subplot(2,2,n-1)
%         histogram(allResults{kk,n});
%         title([num2str(n-1)+"-back"]);
%     end
%     sgtitle(['P_{\theta} / P_{\alpha} (' + string(chList{kk}) + ', all recordings combined)']);
%     
% end

vNames = {'n1', 'n2', 'n3', 'n4'};
ratioMedianTable = array2table(ratioMedian(:,2:5), 'VariableNames', vNames, 'RowNames', chList)

vNames = {'n1vsn2', 'n1vsn3', 'n1vsn4', 'n2vsn3', 'n2vsn4', 'n3vsn4'};
pTable = array2table(p, 'VariableNames', vNames, 'RowNames', chList)

xx=[];
for n =2:5
for kk=1:numel(chList)
    xx(kk, n-1) = min(xOutliers{kk,n});
    end
end

    
toc