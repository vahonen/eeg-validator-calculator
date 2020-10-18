classdef AlgMscCalculator < CalculationAlgorithm
    properties
        name = 'Magnitude Squared Coherence calculator'
        algName = 'AlgMscCalculator'
        type = ''
        calculationType = ''
        freqRange
        freqStep
    end
    
    methods
        function this = AlgMscCalculator(type, calculationType, freqRange, freqStep)
            this.type = type;
            this.calculationType = calculationType;
            this.freqRange = freqRange;
            this.freqStep = freqStep;
        end
    end
    
    methods
        % calculate over one event (= event segment)
        % not reasonable for msc
        function result = calculateEvent(self, samples, sampleRate)
            result = 0;
        end
        
        % calculate over one channel
        % not reasonable for msc
        function result = calculateChannel(self, channel, epochs)
            result = 0;
        end
        
        % calculate over one recording
        function result = calculateRecording(self, recording, n, processChannel)
            M = eye(numel(recording.channel), numel(recording.channel)); 
            % MSC of channel itself = 1, or should it be set to zero as not
            % informative/meaningful
            
            for r = 1 : numel(recording.channel)
                for c = r : numel(recording.channel)
                    if (processChannel(r) && processChannel(c) && r ~= c) 
                        % both channels are processed? if r=c => MSC=1, no need to calculate
                        
                        otherEventNbrs = vertcat(recording.channel(r).validEvents(:).eventNumber);
                        % collect valid event numbers for other channel
                        
                        sampleRate = recording.channel(r).sampleRate;
                        
                        totalCxy = [];
                        for ev = 1:numel(recording.channel(r).validEvents)
                            
                            if (recording.channel(r).validEvents(ev).n == n ...
                                    && ismember(recording.channel(r).validEvents(ev).eventNumber, otherEventNbrs))
                                % n is matching and other channel is also
                                % valid for current event segment
                                range = recording.channel(r).validEvents(ev).sampleRange;
                                [cxy, f] = mscohere(recording.channel(r).samples(range(1,1):range(1,2)), ...
                                    recording.channel(c).samples(range(1,1):range(1,2)), [], [], ...
                                    self.freqRange(1):self.freqStep:self.freqRange(2), sampleRate);
                                
                                totalCxy = [totalCxy mean(cxy)];
                            end
                        end
                            
                        if ~isempty(totalCxy)
                            M(r,c) = mean(totalCxy);
                            M(c,r) = mean(totalCxy);
                        end
                            
                    end
                end
            end
            
            result = M;
        end
    end
end