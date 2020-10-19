classdef AlgCliCalculator < CalculationAlgorithm
    properties
        name = 'CLI calculator'
        algName = 'AlgCliCalculator'
        type = ''
        calculationType = ''
        alphaRange % frequency range for denominator in CLI
        thetaRange % frequency range for numerator in CLI
        freqStep % frequency step within freq range
    end
    
    methods
        function this = AlgCliCalculator(type, calculationType, alphaRange, thetaRange, freqStep)
            this.type = type;
            this.calculationType = calculationType;
            this.alphaRange = alphaRange;
            this.thetaRange = thetaRange;
            this.freqStep = freqStep;
        end
    end
    
    methods
        % calculate over one event (= event segment)
        function result = calculateEvent(self, samples, sampleRate)
            
            %[pxx,f] = pwelch(samples', hamming(64), 32, 256, sampleRate);
            [pxxA, fA] = pwelch((samples' - mean(samples)), hamming(256), 128, self.alphaRange(1,1):self.freqStep: ...
                self.alphaRange(1,2), sampleRate);
            [pxxT, fT] = pwelch((samples' - mean(samples)), hamming(256), 128, self.thetaRange(1,1):self.freqStep: ...
                self.thetaRange(1,2), sampleRate);
            %result = pxx/sum(pxx);
            
            aPowerTot = fA*pxxA';
            tPowerTot = fT*pxxT';
            
            if (aPowerTot > 0)
                result = tPowerTot/aPowerTot;
            else
                result = 0;
                fprintf('###### AlgCliCalculator: aPower = 0 => result set to 0.\n');
            end
        end
        
        % calculate over one channel
        function result = calculateChannel(self, channel, epochs)
            for i = 1 : size(epochs, 1)
                samples = channel.samples(epochs(i, 1) : epochs(i, 2));
                [pxx,f] = pwelch(samples', hamming(128), 64, 0:0.5:49.5, channel.sampleRate);
                pxxMatrix(i,:) = pxx/sum(pxx);
            end
            result = mean(pxxMatrix);
        end
        
        % calculate over one recording (maybe not reasonable for PSD)
        % but using same structure for all calculation algorithms
        function result = calculateRecording(self, recording)
            result = 0;
        end
    end
end