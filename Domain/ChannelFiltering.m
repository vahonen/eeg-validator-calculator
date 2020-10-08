classdef ChannelFiltering < handle
    properties
        filterList
    end
    
    methods
        % constructor
        function this = ChannelFiltering(filterList)
            this.filterList = filterList;
        end
        
        function applyFilters(self, channel)
            if (numel(self.filterList) > 0)
                fprintf("\nFiltering for channel %s started.\n", channel.label);
                for i = 1:numel(self.filterList)
                    fprintf("Algorithm '%s (%s)' executing.\n", self.filterList{i}.name, self.filterList{i}.type);
                    channel.samples = self.filterList{i}.applyFilter(channel.samples, channel.sampleRate);
                end
                fprintf("Filtering for channel %s completed.\n", channel.label);
            else
                fprintf("\nNo any filters given.\n");
            end
        end
    end
end