classdef AlgCliCalculator < CalculationAlgorithm
    properties
        name = 'CLI calculator'
        algName = 'AlgCliCalculator'
        type = ''
        calculationType = ''
    end
    
    methods
        function this = AlgCliCalculator(type, calculationType)
            this.type = type;
            this.calculationType = calculationType;
        end
    end
    
    methods
        % calculate over one event (= event segment)
        function result = calculateEvent(self, samples, sampleRate)
            
            %[pxx,f] = pwelch(samples', hamming(64), 32, 256, sampleRate);
            [pxx, ~] = pwelch((samples' - mean(samples)), hamming(256), 128, 0:0.5:49.5, sampleRate);
            result = pxx/sum(pxx);
            
            theta = 0;
            alpha = 0;
            for i = 4:8
                theta = theta + 0.5*result(i*2);
            end
            
            for i = 8:12
                alpha = alpha + 0.5*result(i*2);
            end
            
            if (alpha > 0)
                result = theta/alpha;
            else
                result = 0;
                fprintf('###### AlgCliCalculator: alpha gives 0 => result set to 0.');
                %result = mean(samples); %just for testing
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