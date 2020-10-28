classdef AlgPacCalculator < CalculationAlgorithm
    properties
        name = 'Phase-Amplitude Coupling calculator'
        algName = 'AlgPacCalculator'
        type = ''
        calculationType = ''
        lowFreqRange
        highFreqRange
    end
    
    methods
        function this = AlgPacCalculator(type, calculationType, lowFreqRange, highFreqRange, transBandWidth, maxAllowedDev)
            this.type = type;
            this.calculationType = calculationType;
            this.lowFreqRange = lowFreqRange;
            this.highFreqRange = highFreqRange;
        end
    end
    
    methods
        % calculate over one event (= event segment)
        % not reasonable for PAC => dummy implementation
        function result = calculateEvent(~)
            result = 0;
        end
        
        % calculate over one channel
        % not reasonable for PAC => dummy implementation
        function result = calculateChannel(~)
            result = 0;
        end
        
        % calculate over one recording
        function result = calculateRecording(self, recording, n, processChannel)
            % calculation method could be configurable with 'type' parameter
            if(strcmp(self.type, 'mean'))
                M = zeros(numel(recording.channel), numel(recording.channel)); % average PAC of events
            else
                M = {}; % PAC stored per event
            end
            
            for r = 1 : numel(recording.channel)
                for c = 1 : numel(recording.channel)
                    if (processChannel(r) && processChannel(c))
                        % both channels are processed? if r=c => MSC=1, no need to calculate
                        
                        otherEventNbrs = vertcat(recording.channel(c).validEvents(:).eventNumber);
                        % collect valid event numbers for other channel
                        
                        sampleRate = recording.channel(r).sampleRate;
                        pac = [];
                        
                        for ev = 1:numel(recording.channel(r).validEvents)
                            
                            if (recording.channel(r).validEvents(ev).n == n ...
                                    && ismember(recording.channel(r).validEvents(ev).eventNumber, otherEventNbrs))
                                % n is matching and other channel is also
                                % valid for current event segment
                                range = recording.channel(r).validEvents(ev).sampleRange;
                                
                                xSamples = recording.channel(r).samples(range(1,1):range(1,2));
                                ySamples = recording.channel(c).samples(range(1,1):range(1,2));
                                
                                % NOTE on filtfilt usage with firpmord
                                % The length of the input X must be more than three times the filter
                                % order, defined as max(length(B)-1,length(A)-1).
                                
                                [bLow,aLow]=butter(3,[self.lowFreqRange(1,1)/(sampleRate/2),self.lowFreqRange(1,2)/(sampleRate/2)]);
                                xLow = filtfilt(bLow, aLow, xSamples);
                                phaseXLow = angle(hilbert(xLow)); %
                                
                                [bHigh,aHigh]=butter(3,[self.highFreqRange(1,1)/(sampleRate/2),self.highFreqRange(1,2)/(sampleRate/2)]);
                                yHigh = filtfilt(bHigh, aHigh, ySamples);
                                yHighEnv = abs(hilbert(yHigh));
                                yHighLow = filtfilt(bLow, aLow, yHighEnv);
                                phaseYHighLow = angle(hilbert(yHighLow)); %
                                
                                % calculate PAC value per events
                                tmpPac = 0;
                                for jj=1:min(numel(xSamples), numel(ySamples))
                                    tmpPac = tmpPac + exp(1i*(phaseXLow(jj)-phaseYHighLow(jj)));
                                end
                                tmpPac = 1/(min(numel(xSamples), numel(ySamples))) * abs(tmpPac);
                                
                                pac = [pac tmpPac];
                            end
                        end
                        
                        if ~isempty(pac)
                            if(strcmp(self.type, 'mean'))
                                M(r,c) = mean(pac); % average PAC of events
                            else
                                M{r,c} = pac; % PAC stored per event
                            end
                        end
                        
                    end
                end
            end
            result = M;
        end
    end
end