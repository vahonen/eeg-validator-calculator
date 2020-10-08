classdef Channel < dynamicprops
    properties
        label
        samples
        units
        sampleRate
        epochLengthInSamples
        epochOverlapInSamples
        epochCount
        invalidEpochs = []
        epochPower = []
        
        epochDeviation = []
        epochMax = []
        epochIqr = []
        
        totalEpochPower = 0
        meanEpochPower = 0
        medianEpochPower = 0
        deviationEpoch = 0
        deviationEpochPower = 0
        minEpochPower = 0
        maxEpochPower = 0
        iqrEpochPower = 0
        
        powerStatisticsCalculated = false
        epochsCalculated = false
        
    end
    
    methods
        function this = Channel(label, units, sampleRate, samples)
            this.label = label;
            this.samples = samples;
            this.units = units;
            this.sampleRate = sampleRate;
        end
        
        function label = get.label(self)
            label = self.label;
        end
        
        function samples = get.samples(self)
            samples = self.samples;
        end
        
        function calc = get.powerStatisticsCalculated(self)
            calc = self.powerStatisticsCalculated;
        end
        
        function calculateEpochs(self, epochTime, epochOverlapPercent)
            self.epochLengthInSamples = epochTime * self.sampleRate;
            self.epochOverlapInSamples = (epochOverlapPercent/100) * self.epochLengthInSamples;
            self.epochCount = 1 + ceil((length(self.samples) - self.epochLengthInSamples)/...
                (self.epochLengthInSamples - self.epochOverlapInSamples));
            self.epochsCalculated = true;
        end
        
        function setInvalidEpoch(self, epochNumber)
            if (~ismember(epochNumber, self.invalidEpochs))
                self.invalidEpochs = [self.invalidEpochs, epochNumber];
            end
        end
        
        function plotChannel(self, timeRange)
            
            startTime = 0;
            endTime = (length(self.samples) - 1)/self.sampleRate;
            
            if (timeRange(1,2) > timeRange(1,1))
                startTime = timeRange(1,1);
                endTime = min(timeRange(1,2), endTime);
            end
            
            if (endTime < startTime)
                error("Invalid time range!");
            end
            
            %figure('NumberTitle', 'off', 'Name', fileName + "_" + self.label);
            % plot whole channel/derivation in blue
            t = startTime:1/self.sampleRate:endTime;
            firstSample = 1 + startTime*self.sampleRate;
            lastSample = 1 + endTime*self.sampleRate;
            
            plot(t, self.samples(firstSample:lastSample), 'blue')
            
            % plot artefact segments in red
            hold on
            for i = 1:length(self.invalidEpochs)
                [startSample, endSample] = self.getEpochRange(self.invalidEpochs(i));
                if (startSample >= firstSample && startSample <= lastSample)
                    endSample = min(endSample, lastSample);
                    offset = startTime*self.sampleRate; %"time" offset for invalid epochs
                    plot(t(startSample-offset:endSample-offset), self.samples(startSample:endSample), 'red');
                    hold on
                end
                
            end
            title(self.label)
            xlabel('Time (s)');
            ylabel(['Amplitude (', self.units, ')']);
            hold off
        end
        
        function calculatePowerStatistics(self)
            % calculate total power over all epochs
            fprintf("Power statistic calculation for channel %s started.", self.label)
            
            self.totalEpochPower = 0;
            self.epochPower = [];
            counter = 1;
            for i = 1:(self.epochLengthInSamples - self.epochOverlapInSamples):(length(self.samples) - self.epochLengthInSamples + 1)
                %if (mod(counter, floor(self.epochCount/9)) == 0)
                %    fprintf(".");
                %end
                
                endSample = min(i + self.epochLengthInSamples - 1, length(self.samples));
                %self.epochPower(counter) = sum(self.samples(i:endSample).^2);
                self.epochPower(counter) = mean(self.samples(i:endSample).^2); %
                self.epochDeviation(counter) = std(self.samples(i:endSample)); %
                self.epochMax(counter) = max(self.samples(i:endSample).^2); %
                self.epochIqr(counter) = iqr(self.samples(i:endSample).^2); %
                counter = counter + 1;
            end
            
            self.totalEpochPower = sum(self.epochPower); % not relevant
            self.meanEpochPower = mean(self.epochPower);
            self.medianEpochPower = median(self.epochPower);
            self.deviationEpoch = mean(self.epochDeviation);
            self.deviationEpochPower = std(self.epochPower);
            self.minEpochPower = min(self.epochPower);
            self.maxEpochPower = max(self.epochPower);
            self.iqrEpochPower = iqr(self.epochPower); %interquartile range: Q3-Q1 (middle 50%)
            
            
            self.powerStatisticsCalculated = true;
            fprintf("\nPower statistic calculation for channel %s completed\n", self.label)
            %error("end");
        end
        
        function [startSample, endSample] = getEpochRange(self, epochNumber)
            startSample = max(1, (epochNumber - 1)*(self.epochLengthInSamples - self.epochOverlapInSamples) + 1); % corrected (+ 1 added)
            endSample = min(startSample + self.epochLengthInSamples - 1, length(self.samples));
        end
        
        function plotChannelValidity(self, timeRange)
            startTime = 0;
            endTime = (length(self.samples) - 1)/self.sampleRate;
            
            if (timeRange(1,2) > timeRange(1,1))
                startTime = timeRange(1,1);
                endTime = min(timeRange(1,2), endTime);
            end
            
            if (endTime < startTime)
                error("Invalid time range!");
            end
            
            %figure('NumberTitle', 'off', 'Name', fileName + "_" + self.label);
            
            t = startTime:1/self.sampleRate:endTime;
            firstSample = 1 + startTime*self.sampleRate;
            lastSample = 1 + endTime*self.sampleRate;
            
            y = zeros(1, length(t));
            plot(t, y, 'green', 'LineWidth',4)
            
            hold on
            for i = 1:length(self.invalidEpochs)
                [startSample, endSample] = self.getEpochRange(self.invalidEpochs(i));
                if (startSample >= firstSample && startSample <= lastSample)
                    endSample = min(endSample, lastSample);
                    offset = startTime*self.sampleRate; %"time" offset for invalid epochs
                    plot(t(startSample-offset:endSample-offset), y(startSample:endSample), 'red', 'LineWidth' , 4);
                    hold on
                end
                
            end
            title(self.label)
            xlabel('Time (s)');
            yticks([-1 1]);
            set(gca,'yticklabel',[])
            %ylabel(['Amplitude (', self.units, ')']);
            hold off
        end
    end
end