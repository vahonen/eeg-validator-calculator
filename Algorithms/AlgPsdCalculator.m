classdef AlgPsdCalculator < CalculationAlgorithm
    properties
        name = 'PSD calculator'
        algName = 'AlgPsdCalculator'
        type = ''
        calculationType = ''
    end
    
    methods
        function this = AlgPsdCalculator(type, calculationType)
            this.type = type;
            this.calculationType = calculationType;
        end
    end
    
    methods
        % calculate over one event (= event segment)
        function result = calculateEvent(self, samples, sampleRate)
            
            %[pxx,f] = pwelch(samples', hamming(64), 32, 256, sampleRate);
            [pxx,f] = pwelch(samples', hamming(128), 64, 0:0.5:49.5, sampleRate);
            result = pxx/sum(pxx);
            %result = mean(samples); %just for testing
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