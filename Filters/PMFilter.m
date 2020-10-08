classdef PMFilter < Filter
    properties
        frequencyBandEdges = []
        desiredAmplitude = []
        maxAllowedDev = []
        sampleRate = 0
        name = 'Parks-McClellan FIR Filter'
        type = ''
      
    end
    methods
        % constructor
        function this = PMFilter(type, edges, amplitude, dev, sr)
            
            this.type = type;
            this.frequencyBandEdges = edges;
            this.desiredAmplitude = amplitude;
            this.maxAllowedDev = dev;
            this.sampleRate = sr;
            
    
        end
        
        function filteredChannel = applyFilter(self, channel, sampleRate)
            
            if (sampleRate <= 0)
                if (self.sampleRate <= 0)
                    error("Given sample rate is erroneous!");
                else
                    sampleRate = self.sampleRate;
                end
            end
            
            [n,fo,ao,w] = firpmord(self.frequencyBandEdges, self.desiredAmplitude, self.maxAllowedDev, sampleRate);
            B = firpm(n,fo,ao,w);
            filteredChannel = filtfilt(B, 1, channel);
            
            %freqz(B,1,1024,sampleRate)
            
        end
        
        
    end
end