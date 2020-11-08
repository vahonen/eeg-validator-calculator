close all

addpath('./Services');
addpath('./Domain');
addpath('./Algorithms');
addpath('./Filters');

tic % start stopwatch timer

load('./Results3/nback_object_2019_2020_intra_ch_cli_128_64_new.mat'); %nBackCalculator

recs = numel(nBackCalculator); % all recordings

%recs = 5;
startRec = 1;


allResults = {};
chList = {'Fp1', 'Fp2', 'C3', 'C4', 'O1', 'O2'};
%chList = {'Fp1'};

for kk = 1:numel(chList)
    targetChannel = chList(kk);
    for reg = startRec:recs
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
        for reg = startRec:recs
            % CHECK!
            %if (~ismember(reg, [4 6 15 16])) % remove recs 4,6,15,16 => these have very high values compared to the rest
            if (~isempty(nBackCalculator(reg).nBackResults.algorithm(1).nBack(n).channel) && channelNbr(reg) > 0)
                y = horzcat(nBackCalculator(reg).nBackResults.algorithm(1).nBack(n).channel(channelNbr(reg)).event(:).result);
                y = rmoutliers(y, 'median'); % CHECK!
                x = [x y];
                %end
            end
        end
        
        allResults{kk,n} = x; %(x<=26); % !CHECK
    end
    
end % for kk = 1:numel(chList)

count = 1;
auc=[];
for low = 2:4 % 1-back ... 3-back
    for high = low + 1 : 5 % ...4-back
       
        for kk = 1:numel(chList)
            % 'low' n vs 'high' n (1->0-back, 2->1-back, etc.)
            
            scores1 = allResults{kk,low};
            scores2 = allResults{kk,high};
            
            scores = [scores1 scores2];
            
            labels1 = cell(1, size(scores1,2));
            labels2 = cell(1, size(scores2,2));
            
            labels1(:) = {'Low'};
            labels2(:) = {'High'};
            
            labels = [labels1 labels2];
            
            posclass = 'High';
            
            
            [x, y, ~, tempAuc] = perfcurve(labels, scores, posclass);
            subplot(3,2,count)
            plot(x,y,'Displayname',chList{kk})
            xlabel('1-Specifity');
            ylabel('Sensitivity');
            hold on
            
            auc(kk, count) = tempAuc;
        end
        
        count = count + 1;
       
        lgd = legend;
        lgd.Location = 'southeast';
        title([num2str(low-1)+"vs"+num2str(high-1)]);
    end
end

nVsN = {'n1vsn2', 'n1vsn3', 'n1vsn4', 'n2vsn3', 'n2vsn4', 'n3vsn4'};
aucTable = array2table(auc, 'VariableNames', nVsN, 'RowNames', chList)
toc % stop stopwatch timer
