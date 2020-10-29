classdef NBackCalculator < handle
    properties
        recordingName
        calculationAlgorithm
        nBackResults
    end
    
    methods
        % constructor
        function this = NBackCalculator(algorithm, recordingName)
            this.calculationAlgorithm = algorithm;
            this.recordingName = recordingName;
            %this.nBackResults = {};
        end
        
        function calculate(self, recording, processChannel)
            if (numel(self.calculationAlgorithm) > 0)
                fprintf("\nCalculation for record %s started (n-back).\n", recording.edfFile);
                for i = 1:numel(self.calculationAlgorithm)
                    fprintf("Algorithm '%s (%s)' executing. Calculation type: %s\n", self.calculationAlgorithm{i}.name, self.calculationAlgorithm{i}.type, self.calculationAlgorithm{i}.calculationType);
                    switch (self.calculationAlgorithm{i}.calculationType)
                        case 'event'
                            % calculate per event segment
                            channelCounter = 1;
                            for jj = 1 : numel(recording.channel)
                                if (processChannel(jj))
                                    fprintf("Calculation for channel %s ongoing.\n", recording.channel(jj).label);
                                    nPrev = -1;
                                    counter = 1; % could counter(n) be better choice (n=1...5 (0-back...4-back))?
                                    for k = 1 : numel(recording.channel(jj).validEvents)
                                        
                                        samples = recording.channel(jj).samples;
                                        sampleRate = recording.channel(jj).sampleRate;
                                        
                                        startSample = recording.channel(jj).validEvents(k).sampleRange(1,1);
                                        endSample = recording.channel(jj).validEvents(k).sampleRange(1,2);
                                        
                                        tmpResult = self.calculationAlgorithm{i}.calculateEvent(samples(startSample:endSample), sampleRate);
                                        n = recording.channel(jj).validEvents(k).n + 1; %0-back = 1, 1-back = 2, ...
                                        
                                        if (n ~= nPrev)
                                            nPrev = n;
                                            counter = 1;
                                        end
                                        
                                        self.nBackResults.algorithm(i).nBack(n).channel(channelCounter).label = recording.channel(jj).label;
                                        self.nBackResults.algorithm(i).nBack(n).channel(channelCounter).event(counter).result = tmpResult;
                                        self.nBackResults.algorithm(i).nBack(n).channel(channelCounter).event(counter).target = recording.channel(jj).validEvents(k).target;
                                        self.nBackResults.algorithm(i).nBack(n).channel(channelCounter).event(counter).mouseClicked = recording.channel(jj).validEvents(k).mouseClicked;
                                        self.nBackResults.algorithm(i).nBack(n).channel(channelCounter).event(counter).delay = recording.channel(jj).validEvents(k).delay;
                                        counter = counter + 1;
                                    end % for k = 1 : numel(recording.channel(jj).validEvents)
                                    
                                    channelCounter = channelCounter + 1;
                                    
                                else % if (processChannel)
                                    fprintf("Calculation not performed for channel %s.\n", recording.channel(jj).label);
                                end
                            end
                        case 'channel'
                            % calculate per channel
                            channelCounter = 1;
                            for jj = 1 : numel(recording.channel)
                                
                                if (processChannel(jj))
                                    fprintf("Calculation for channel %s ongoing.\n", recording.channel(jj).label);
                                    
                                    foundN = [];
                                    for k = 1 : numel(recording.channel(jj).validEvents)
                                        n = recording.channel(jj).validEvents(k).n + 1;
                                        if(~ismember(n, foundN))
                                            foundN = [foundN n];
                                            epochs{n} = [recording.channel(jj).validEvents(k).sampleRange];
                                        else
                                            epochs{n} = [epochs{n}; recording.channel(jj).validEvents(k).sampleRange];
                                        end
                                    end
                                    
                                    for k = 1 : numel(foundN)
                                        n = foundN(k);
                                        
                                        tmpResult = self.calculationAlgorithm{i}.calculateChannel(recording.channel(jj), epochs{n});
                                    
                                        self.nBackResults.algorithm(i).nBack(n).channel(channelCounter).label = recording.channel(jj).label;
                                        self.nBackResults.algorithm(i).nBack(n).channel(channelCounter).result = tmpResult;
                                    end
                                    channelCounter = channelCounter + 1;
                                else % if (processChannel)
                                    fprintf("Calculation not performed for channel %s.\n", recording.channel(jj).label);
                                end
                            end
                            
                        case 'recording'
                            % calculate per recording 
                            for n = 1:5 % 1=nback_0, ..., 5= nback_4
                                fprintf("Calculating metrics for n-back: %d\n", n-1);
                                %if (ismember(n-1, vertcat(recording.channel(1).validEvents.n)))%something more reliable needed
                                    %fprintf("\n");
                                    tmpResult = self.calculationAlgorithm{i}.calculateRecording(recording, n-1, processChannel);
                                    self.nBackResults.algorithm(i).nBack(n).result = tmpResult;
                                    %self.nBackResults.algorithm(i).nBack(n).result = array2table(tmpResult,'VariableNames',{recording.channel.label}, ...
                                    %    'RowNames', {recording.channel.label});
                                    self.nBackResults.algorithm(i).nBack(n).channelLabels = {recording.channel.label};
                                %else
                                %    fprintf(" <- nothing here\n");
                                %end
                            end
                        otherwise
                            error("Unknown calculation type '%s' defined for '%s' in json.", self.calculationAlgorithm{i}.calculationType, self.calculationAlgorithm{i}.algName);
                    end
                end
                fprintf("Calculation for %s completed.\n", recording.edfFile);
            else
                fprintf("No any calculation algorithms given.\n");
            end
        end
    end
end