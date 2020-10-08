classdef AlgChannelValidator < ChannelValidationAlgorithm
    properties
        name = 'Basic Channel Validator'
        type = ''
    end
    
    methods
        function this = AlgChannelValidator(type)
            this.type = type;
        end
    end
    
    methods
        function result = execute(~, channel, epochNumber)
            %result = rand < 0.5;
            result = ~((channel.epochPower(epochNumber) > channel.meanEpochPower + 2*channel.deviationEpochPower));
            %|| ...
            %(channel.epochMax(epochNumber) > channel.meanEpochPower + 4*channel.deviationEpochPower) || ... % 4x invalidates too easily?
            %(channel.epochDeviation(epochNumber) < channel.deviationEpoch/5) || ...
            %(channel.epochDeviation(epochNumber) > channel.deviationEpoch*3));
            
        end
    end
end