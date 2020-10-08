classdef ChannelValidator < handle
    properties
        epochTime
        epochOverlapPercent
        algorithms
    end
    
    methods
        function this = ChannelValidator(epochTime, epochOverlapPercent, algorithms)
            this.epochTime = epochTime;
            this.epochOverlapPercent = epochOverlapPercent;
            this.algorithms = algorithms;
        end
        
        function validate(self, channel)
            
            if (~channel.epochsCalculated)
                channel.calculateEpochs(self.epochTime, self.epochOverlapPercent);
            end
            if (~channel.powerStatisticsCalculated)
                channel.calculatePowerStatistics();
            end
            
            if (~isempty(self.algorithms))
                fprintf("Validation for channel %s started.", channel.label);
                for i = 1:length(self.algorithms)
                    fprintf("\nAlgorithm '%s (%s)' executing.", self.algorithms{i}.name, self.algorithms{i}.type);
                    
                    % loop through epochs in channel
                    for j = 1:channel.epochCount
                        if (mod(j, floor(channel.epochCount/9)) == 0)
                            fprintf("."); %just for visual feedback that something is happening if it takes long
                        end
                        
                        result = self.algorithms{i}.execute(channel, j); % j = epoch index
                        if (~result)
                            channel.setInvalidEpoch(j);
                        end
                    end
                end
            else
                fprintf("\nNo any validation algorithms given.");
            end
            
            fprintf("\nTotal epochs: %d, artefactual epochs: %d\n",channel.epochCount, numel(channel.invalidEpochs))
            fprintf("Validation for channel %s completed.\n\n", channel.label);
        end
    end
    
end