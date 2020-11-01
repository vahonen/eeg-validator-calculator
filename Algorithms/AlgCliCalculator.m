classdef AlgCliCalculator < CalculationAlgorithm
    properties
        name = 'CLI calculator'
        algName = 'AlgCliCalculator'
        type = ''
        calculationType = ''
        alphaRange % frequency range for denominator in CLI
        thetaRange % frequency range for numerator in CLI
        freqStep % frequency step within freq range
        windowLength % length of window
        overlap % number of overlapping samples for windowing
    end
    
    methods
        function this = AlgCliCalculator(type, calculationType, alphaRange, thetaRange, freqStep, windowLength, overlap)
            this.type = type;
            this.calculationType = calculationType;
            this.alphaRange = alphaRange;
            this.thetaRange = thetaRange;
            this.freqStep = freqStep;
            this.windowLength = windowLength;
            this.overlap = overlap;
        end
    end
    
    methods
        % calculate over one event (= event segment)
        function result = calculateEvent(self, samples, sampleRate)
            
            %[pxx,f] = pwelch(samples', hamming(64), 32, 256, sampleRate);
            [pxxA, fA] = pwelch((samples' - mean(samples)), hamming(self.windowLength), self.overlap, self.alphaRange(1,1):self.freqStep: ...
                self.alphaRange(1,2), sampleRate);
            [pxxT, fT] = pwelch((samples' - mean(samples)), hamming(self.windowLength), self.overlap, self.thetaRange(1,1):self.freqStep: ...
                self.thetaRange(1,2), sampleRate);
            %result = pxx/sum(pxx);
            
            
            %aPowerTot = fA*pxxA'; % or maybe not... should be calculated per freq bin
            %tPowerTot = fT*pxxT'; % or maybe not... should be calculated per freq bin
            
            aPowerTot = sum(pxxA); %sum(freqStep * pxxA) = freqStep*sum(pxxA)
            tPowerTot = sum(pxxT);  %sum(freqStep * pxxT) = freqStep*sum(pxxT)
            % => in CLI ratio, freqStep gets canceled
            
            if (aPowerTot > 0)
                result = tPowerTot/aPowerTot; % CLI.. should it be frontal theta / parietal alpha ?
            else
                result = 0;
                fprintf('###### AlgCliCalculator: aPowerTot = 0 => result set to 0.\n');
            end
        end
        
        % calculate over one channel
        function result = calculateChannel(self, channel, epochs)
            for i = 1 : size(epochs, 1)
                samples = channel.samples(epochs(i, 1) : epochs(i, 2));
                [pxx,f] = pwelch(samples', hamming(self.windowLength), self.overlap, 0:0.5:49.5, channel.sampleRate);
                pxxMatrix(i,:) = pxx/sum(pxx);
            end
            result = mean(pxxMatrix);
        end
        
        % calculate CLI between channels
        function result = calculateRecording(self, recording, n, processChannel)
            M ={};
            for r = 1 : numel(recording.channel)
                for c = 1 : numel(recording.channel)
                    if (processChannel(r) && processChannel(c))
                        eventCli = [];
                        for ev = 1:numel(recording.channel(r).validEvents)
                            otherEventNbrs = vertcat(recording.channel(r).validEvents(:).eventNumber);
                            % collect valid event numbers for other channel
                            sampleRate = recording.channel(r).sampleRate;
                            
                            if (recording.channel(r).validEvents(ev).n == n ...
                                    && ismember(recording.channel(r).validEvents(ev).eventNumber, otherEventNbrs))
                                % n is matching and other channel is also
                                % valid for current event segment
                                
                                range = recording.channel(r).validEvents(ev).sampleRange;
                                
                                aSamples = recording.channel(r).samples(range(1,1):range(1,2));
                                tSamples = recording.channel(c).samples(range(1,1):range(1,2));
                                
                                [pxxA, fA] = pwelch((aSamples' - mean(aSamples)), hamming(self.windowLength), self.overlap, self.alphaRange(1,1):self.freqStep: ...
                                    self.alphaRange(1,2), sampleRate);
                                [pxxT, fT] = pwelch((tSamples' - mean(tSamples)), hamming(self.windowLength), self.overlap, self.thetaRange(1,1):self.freqStep: ...
                                    self.thetaRange(1,2), sampleRate);
                                
                                aPowerTot = sum(pxxA); %sum(freqStep * pxxA) = freqStep*sum(pxxA)
                                tPowerTot = sum(pxxT);  %sum(freqStep * pxxT) = freqStep*sum(pxxT)
                                % => in CLI ratio, freqStep gets canceled
                                
                                if (aPowerTot > 0)
                                    eventCli = [eventCli tPowerTot/aPowerTot]; % CLI
                                else
                                    eventCli = [eventCli 0];
                                    fprintf('###### AlgCliCalculator: aPowerTot = 0 => eventCli value set to 0.\n');
                                end
                            end
                        end % for ev = ...
                        M{r,c} = eventCli; % CLI values for events (ch "r" / ch "c")
                    end 
                end
            end
            
            result = M;
        end
    end
end