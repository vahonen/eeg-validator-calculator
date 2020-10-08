classdef (Abstract) CalculationAlgorithm < handle
    properties (Abstract)
        name
        algName
        type
        calculationType
    end
    
    methods(Abstract)
        result = calculateEvent(self, samples, sampleRate)      
        result = calculateChannel(self, channel, epochs)
        result = calculateRecording(self, recording)
    end
end