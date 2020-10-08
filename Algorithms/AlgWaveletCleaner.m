classdef AlgWaveletCleaner < CleaningAlgorithm
    properties
        name = "Wavelet cleaner"
        type string
        thCoef double
        windowSize double
        level uint8
    end
    
    methods
        function this = AlgWaveletCleaner(type, thCoef, windowSize, level)
            this.type = type;
            this.thCoef = thCoef;
            this.windowSize = windowSize;
            this.level = level;
        end
    end
    
    methods
        function cleanedSamples = execute(self, samples, sampleRate)
            
            [Lo, Hi] = wfilters(self.type);
            w = modwt(samples, Lo, Hi);
            
            
            
            %t = 1/sampleRate:1/sampleRate:length(samples)/sampleRate;
           
            th = zeros(1, self.level);
            
            % threshold over first windowSize samples (in secs)
            for i = 1:self.level
                th(i) = self.thCoef*std(w(i,1:self.windowSize*sampleRate));
            end
            
            % checking/zeroing first windowSize/2 samples (in secs)
            for i = 1:self.level
                for j = 1:floor(self.windowSize*sampleRate*3/4)
                    if abs(w(i,j)) > th(i)
                        w(i,j) = 0; %smoother zeroing?
                    end
                end
            end
     
            for i = 1:self.level
                j = floor(self.windowSize*sampleRate*3/4);
                while j <= (size(w,2) - floor(self.windowSize*sampleRate*3/4))                    
                    if (mod(j, floor(self.windowSize*sampleRate/2))) == floor(self.windowSize*sampleRate/4)
                        th(i) = self.thCoef*std(w(i,(j - floor(self.windowSize*sampleRate/4)):(j + floor(self.windowSize*sampleRate*3/4))));
                    end
                    if (mod(j, floor(size(w,2)/9)) == 0)
                        fprintf('.'); %just for visual feedback that something is happening if it takes long
                    end
                    j = j + 1;
                    if abs(w(i,j)) > th(i)
                        w(i,j) = 0;
                    end
                end
                fprintf('\n');
            end
            
            for i = 1:self.level
                th(i) = self.thCoef*std(w(i,(size(w,2)) - self.windowSize*sampleRate):size(w,2));
            end
            for i = 1:self.level
                for j = (size(w,2) - floor(self.windowSize*sampleRate*3/4) + 1):size(w,2)
                    if abs(w(i,j)) > th(i)
                        w(i,j) = 0;
                    end
                end
            end
            
           cleanedSamples = imodwt(w, Lo, Hi);
          
        end
    end
end