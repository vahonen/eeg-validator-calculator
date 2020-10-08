classdef Recording < handle
    properties
        edfFile string
        header struct
        channel Channel
    end
    methods
        % constructor
        function this = Recording(edfFile, header, recording, labels)
            
            this.edfFile = edfFile;
            this.header = header;
            
            if (~isempty(labels))
                this.header.label = labels;
            end
            
            for chNumber = 1:header.ns
                samples = recording(chNumber,:);
                this.channel(chNumber) = Channel(this.header.label{chNumber}, header.units{chNumber}, header.frequency(chNumber), samples);
            end
        end
        
        function plotChannels(self, range)
            count = numel(self.channel);
            figure('NumberTitle', 'off', 'Name', self.edfFile);
            for i = 1 : count
                subplot(count, 1, i)
                self.channel(i).plotChannel(range)
                hold on
            end
            hold off
        end
        
        function plotChannelsValidity(self, range)
            count = numel(self.channel);
            figure('NumberTitle', 'off', 'Name', self.edfFile);
            for i = 1 : count
                subplot(count, 1, i)
                self.channel(i).plotChannelValidity(range)
                hold on
            end
            hold off
        end
        
        function zeroArtefacts(self)
            for i = 1 : numel(self.channel)
                for jj = 1:numel(self.channel(i).invalidEpochs)
                    [startSample, endSample] = self.channel(i).getEpochRange(self.channel(i).invalidEpochs(jj));
                    self.channel(i).samples(startSample : endSample) = 0;
                end
            end
        end
    end
end