classdef AlgPLVCalculator < CalculationAlgorithm
    properties
        name = 'Phase Locking Value calculator'
        algName = 'AlgPLVCalculator'
        type = ''
        calculationType = ''
        lowFreqRange
        highFreqRange
        transBandWidth
        maxAllowedDev
    end
    
    methods
        function this = AlgPLVCalculator(type, calculationType, lowFreqRange, highFreqRange, transBandWidth, maxAllowedDev)
            this.type = type;
            this.calculationType = calculationType;
            this.lowFreqRange = lowFreqRange;
            this.highFreqRange = highFreqRange;
            this.transBandWidth = transBandWidth;
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
            sampleRate = recording.header.frequency(1); %assuming same sample rate for all channels within same recording
            
            % PM filtering:
            
            % low freq:
            if (self.lowFreqRange(1,1) <= 0) % low pass (for low freq)
                frequencyBandEdges = [self.lowFreqRange(1,2), self.lowFreqRange(1,2) + self.transBandWidth];
                [n1,fo1,ao1,w1] = firpmord(frequencyBandEdges, [1, 0], self.maxAllowedDev(1:2), sampleRate);
                fprintf('# Low pass (low) [(%d) %d] \n', self.lowFreqRange(1,1), self.lowFreqRange(1,2));
            else % band pass (for low freq)
                frequencyBandEdges = [max(0, self.lowFreqRange(1,1) - self.transBandWidth), self.lowFreqRange(1,1), ...
                    self.lowFreqRange(1,2), self.lowFreqRange(1,2) + self.transBandWidth];
                [n1,fo1,ao1,w1] = firpmord(frequencyBandEdges, [0, 1, 0], self.maxAllowedDev, sampleRate);
                fprintf('# Band pass (low) [%d %d] \n', self.lowFreqRange(1,1), self.lowFreqRange(1,2));
            end
            
            % high freq:
            if (self.highFreqRange(1,2) > sampleRate/2) % high pass (for high freq)
                frequencyBandEdges = [max(0, self.highFreqRange(1,1) - self.transBandWidth), self.highFreqRange(1,1)];
                [n1,fo2,ao2,w2] = firpmord(frequencyBandEdges, [0, 1], self.maxAllowedDev(2:3), sampleRate);
                fprintf('# High pass (high) [%d (%d)] \n', self.highFreqRange(1,1), self.highFreqRange(1,2));
            else % band pass (for high freq)
                frequencyBandEdges = [max(0, self.highFreqRange(1,1) - self.transBandWidth), self.highFreqRange(1,1), ...
                    self.highFreqRange(1,2), self.highFreqRange(1,2) + self.transBandWidth];
                [n2,fo2,ao2,w2] = firpmord(frequencyBandEdges, [0, 1, 0], self.maxAllowedDev, sampleRate);
                fprintf('# Band pass (high) [%d %d] \n', self.highFreqRange(1,1), self.highFreqRange(1,2));
            end
            
            % modulating signal (low freq)
            bLow = firpm(n1,fo1,ao1,w1);
             % modulated signal (high freq)
            bHigh = firpm(n2,fo2,ao2,w2);
            
            for r = 1 : numel(recording.channel)
                for c = 1 : numel(recording.channel)
                    % n>0 => SKIP 0-back !!!!! (maybe some more sophisticated method could be used...)
                    
                    if (processChannel(r) && processChannel(c) && n > 0)
                        % both channels are processed? if r=c => MSC=1, no need to calculate
                        fprintf('n: %d, r: %d, c: %d\n', n, r, c);
                        otherEventNbrs = vertcat(recording.channel(c).validEvents(:).eventNumber);
                        % collect valid event numbers for other channel
                        
                        %sampleRate = recording.channel(r).sampleRate;
                        pac = [];
                        
                        y1 = filtfilt(bLow, 1, recording.channel(r).samples);
                        
                        % phase for modulating signal
                        phase_y1 = angle(hilbert(y1)); %
                        
                        y2 = filtfilt(bHigh, 1, recording.channel(c).samples);
                        % envelope
                        %yHighEnv = abs(hilbert(yHigh));
                        %yHighLow = filtfilt(bLow, 1, yHighEnv);
                        
                        % phase for envelope amplitude of modulated (high freq) signal
                        phase_y2 = angle(hilbert(y2)); %
                        
                        for ev = 1:numel(recording.channel(r).validEvents)
                            if (recording.channel(r).validEvents(ev).n == n ...
                                    && ismember(recording.channel(r).validEvents(ev).eventNumber, otherEventNbrs))
                                % n is matching and other channel is also
                                % valid for current event segment
                                range = recording.channel(r).validEvents(ev).sampleRange;
                                
%                                 plot(recording.channel(r).samples(range(1,1):range(1,2))),pause;
%                                 figure
%                                 plot(xLow(range(1,1):range(1,2))),pause;
%                                 figure
%                                 plot(unwrap(phaseXLow(range(1,1):range(1,2)))),pause;
%                                 figure
%                                 plot(yHigh(range(1,1):range(1,2))),pause;
%                                 figure
%                                 plot(yHighLow(range(1,1):range(1,2))),pause;
%                                 figure
%                                 plot(unwrap(phaseYHighLow(range(1,1):range(1,2)))),pause;
                                
                                % calculate PAC value per events
                                tmpPac = 0;
                                %for jj=1:min(numel(xSamples), numel(ySamples))
                                
                                tmp = zeros(range(1,2) - range(1,1) + 1, 1);
                                
                                for jj=range(1,1):range(1,2)
                                    tmpPac = tmpPac + exp(1i*(phase_y1(jj)-phase_y2(jj)));
                                    
                                    %tmp(jj-range(1,1)+1) = exp(1i*(phaseXLow(jj)-phaseYHighLow(jj)));
                                end
                                
                                %figure
                                %plot(angle(tmp)),pause;
                                %hist(angle(tmp), 50);
                                %sum(angle(tmp)),pause;
                                %abs(tmpPac), abs(sum(tmp)), pause;
                                
                                tmpPac = 1/(range(1,2)-range(1,1)+1) * abs(tmpPac);
                                %tmpPac = sum(angle(tmp));
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