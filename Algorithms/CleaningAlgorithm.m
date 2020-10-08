% abstract parent class for cleaning algorithms

classdef (Abstract) CleaningAlgorithm < handle
    properties (Abstract)
        name string
        type string
    end
    
    methods(Abstract)
        result = execute(self)
    end
end