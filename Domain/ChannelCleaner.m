
classdef ChannelCleaner < handle
    properties
        cleaningAlgorithm
    end
    
    methods
        % constructor
        function this = ChannelCleaner(cleaningAlgorithm)
            
            this.cleaningAlgorithm = cleaningAlgorithm;
        end
        
        % cleaning (artefact removal)
        function clean(self, channel)            
            if (numel(self.cleaningAlgorithm) > 0)
                fprintf("\nCleaning for channel %s started.\n", channel.label);
                for i = 1:numel(self.cleaningAlgorithm)
                    fprintf("Algorithm '%s (%s)' executing.\n", self.cleaningAlgorithm{i}.name, self.cleaningAlgorithm{i}.type);
                    channel.samples = self.cleaningAlgorithm{i}.execute(channel.samples, channel.sampleRate);
                end
                fprintf("Cleaning for channel %s completed.\n", channel.label);
            else
                fprintf("No any cleaning algorithms given.\n");
            end     
        end
    end
end