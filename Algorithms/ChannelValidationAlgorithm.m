classdef (Abstract) ChannelValidationAlgorithm < handle
    properties (Abstract)
        name string
        type string
    end
    
    methods (Abstract)
        result = execute(self)
    end
end