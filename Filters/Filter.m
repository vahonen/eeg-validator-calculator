classdef (Abstract) Filter < handle
    properties (Abstract)
        name string
        type string
    end
    
    methods (Abstract)
        filteredChannel = applyFilter(self)
    end
end