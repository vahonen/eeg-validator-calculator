classdef AlgPacCalculator < CalculationAlgorithm
    properties
        name = 'Phase-Amplitude Coupling calculator'
        algName = 'AlgPacCalculator'
        type = ''
        calculationType = ''
        lowFreqRange
        highFreqRange
        transBandWidth
        desiredAmplitude
        maxAllowedDev
    end
    
    methods
        function this = AlgPacCalculator(type, calculationType, lowFreqRange, highFreqRange, transBandWidth, desiredAmplitude, maxAllowedDev)
            this.type = type;
            this.calculationType = calculationType;
            this.lowFreqRange = lowFreqRange;
            this.highFreqRange = highFreqRange;
            this.transBandWidth = transBandWidth;
            this.desiredAmplitude = desiredAmplitude;
            this.maxAllowedDev = maxAllowedDev;
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
            % calculation method configurable with 'type' parameter (mean,
            % event, median)
            
            M = {};
            
            for r = 1 : numel(recording.channel)
                for c = 1 : numel(recording.channel)
                    % SKIP 0-back !!!!! (maybe some more sophisticated method...)
                    
                    if (processChannel(r) && processChannel(c) && n > 0)
                        % both channels are processed? if r=c => MSC=1, no need to calculate
                        fprintf('n: %d, r: %d, c: %d\n', n, r, c);
                        otherEventNbrs = vertcat(recording.channel(c).validEvents(:).eventNumber);
                        % collect valid event numbers for other channel
                        
                        sampleRate = recording.channel(r).sampleRate;
                        pac = [];
                        
                        % PM filtering
                        frequencyBandEdges = [max(0, self.lowFreqRange(1,1) - self.transBandWidth), self.lowFreqRange(1,1), ...
                            self.lowFreqRange(1,2), self.lowFreqRange(1,2) + self.transBandWidth];
                        
                        [nn,fo,ao,w] = firpmord(frequencyBandEdges, self.desiredAmplitude, self.maxAllowedDev, sampleRate);
                        bLow = firpm(nn,fo,ao,w);
                        xLow = filtfilt(bLow, 1, recording.channel(r).samples);
                        
                        %[bLow,aLow]=butter(3,[self.lowFreqRange(1,1)/(sampleRate/2),self.lowFreqRange(1,2)/(sampleRate/2)]);
                        %xLow = filtfilt(bLow, aLow, xSamples);
                        
                        % phase for modulating (low freq) signal
                        phaseXLow = angle(hilbert(xLow)); %
                        
                        %[bHigh,aHigh]=butter(3,[self.highFreqRange(1,1)/(sampleRate/2),self.highFreqRange(1,2)/(sampleRate/2)]);
                        %yHigh = filtfilt(bHigh, aHigh, ySamples);
                        
                        frequencyBandEdges = [max(0, self.highFreqRange(1,1) - self.transBandWidth), self.highFreqRange(1,1), ...
                            self.highFreqRange(1,2), self.highFreqRange(1,2) + self.transBandWidth];
                        
                        [nn,fo,ao,w] = firpmord(frequencyBandEdges, self.desiredAmplitude, self.maxAllowedDev, sampleRate);
                        bHigh = firpm(nn,fo,ao,w);
                        yHigh = filtfilt(bHigh, 1, recording.channel(c).samples);
                        
                        yHighEnv = abs(hilbert(yHigh));
                        %yHighLow = filtfilt(bLow, aLow, yHighEnv);
                        yHighLow = filtfilt(bLow, 1, yHighEnv);
                        
                         % phase for envelope amplitude of modulated (high freq) signal 
                        phaseYHighLow = angle(hilbert(yHighLow)); %
                        
                        for ev = 1:numel(recording.channel(r).validEvents)
                            if (recording.channel(r).validEvents(ev).n == n ...
                                    && ismember(recording.channel(r).validEvents(ev).eventNumber, otherEventNbrs))
                                % n is matching and other channel is also
                                % valid for current event segment
                                range = recording.channel(r).validEvents(ev).sampleRange;
                                
                                % calculate PAC value per events
                                tmpPac = 0;
                                %for jj=1:min(numel(xSamples), numel(ySamples))
                                for jj=range(1,1):range(1,2)
                                    tmpPac = tmpPac + exp(1i*(phaseXLow(jj)-phaseYHighLow(jj)));
                                end
                                tmpPac = 1/(range(1,2)-range(1,1)+1) * abs(tmpPac);
                                
                                pac = [pac tmpPac];
                            end
                        end
                        
                        if ~isempty(pac)
                            switch self.type
                                case 'mean' % not quite necessary? could be post-prosessed from event specific PACs
                                    M{r,c} = mean(pac); % average PAC of events
                                case 'median' % not quite necessary? could be post-prosessed from event specific PACs
                                    M{r,c} = median(pac); % median PAC of events
                                otherwise
                                    M{r,c} = pac; % PAC per event
                            end
                        end
                        
                    end
                end
            end
            result = M;
        end
    end
end