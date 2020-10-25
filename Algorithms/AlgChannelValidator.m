classdef AlgChannelValidator < ChannelValidationAlgorithm
    properties
        name = 'Basic Channel Validator'
        type = ''
        devCoef
    end
    
    methods
        function this = AlgChannelValidator(type, devCoef)
            this.type = type;
            this.devCoef = devCoef;
        end
    end
    
    methods
        function result = execute(self, channel, epochNumber)
            %result = rand < 0.5;
            result = ~((channel.epochPower(epochNumber) > channel.meanEpochPower + self.devCoef*channel.deviationEpochPower));
            %|| ...
            %(channel.epochMax(epochNumber) > channel.meanEpochPower + 4*channel.deviationEpochPower) || ... % 4x invalidates too easily?
            %(channel.epochDeviation(epochNumber) < channel.deviationEpoch/5) || ...
            %(channel.epochDeviation(epochNumber) > channel.deviationEpoch*3));
            
        end
    end
end