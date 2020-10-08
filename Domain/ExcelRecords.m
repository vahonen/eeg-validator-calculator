classdef ExcelRecords < handle
    properties (Access = private)
        fname string
        path string
        dropXChannels
        fileTable
        recordingList
        
    end
    methods
        % constructor
        function this = ExcelRecords(excelPath, excelFile, dropXChannels)
            this.fileTable = readtable(fullfile(excelPath, excelFile));
            this.fname = excelFile;
            this.path = excelPath;
            this.dropXChannels = dropXChannels;
            this.recordingList = [];
        end
        
        function createFileList(self)
            self.recordingList = [];
            % file names (edf, log, info) read from column named 'filename'
            fileName = string(self.fileTable.filename);
            % target signals read from column named 'channels'
            channels = string(self.fileTable.channels);
            
            %find ALL edf files in same dir or sub-dirs where summary excel
            %file is located
            edfFiles = dir(fullfile(self.path, '**\*.edf'));
            
            for i = 1:length(edfFiles)
                edfFileName{i} = edfFiles(i).name(1:end-4); %drop .edf extension
            end
            
            % loop through files in excel and select those that are found
            % in dir
            
            if (~isempty(edfFiles))
            
                recordIndex = 1;
                for i = 1:length(fileName)
                    index = find(strcmpi(edfFileName, fileName(i)));
                    if (~isempty(index))
                        % store file information
                        tmpRecord.folder = edfFiles(index).folder;
                        tmpRecord.edf = edfFiles(index).name;

                        extension = {'log', 'info', 'easy'};
                        for jj = 1 : length(extension) % check for existence of log, info and easy files
                            if (exist(fullfile(edfFiles(index).folder, strcat(edfFiles(index).name(1:end-3) , extension{jj})), 'file'))
                                tmpRecord.(extension{jj}) = strcat(edfFiles(index).name(1:end-3) , extension{jj});
                            else
                                tmpRecord.(extension{jj}) = '';
                            end
                        end

                        % store channel information (i.e. which channels are taken in)
                        channelArray = [];
                        processArray = [];
                        if(~ismissing(channels(i))) % channels defined
                            tmpChannel = char(channels(i));
                            for jj = 1:length(tmpChannel)
                                switch tmpChannel(jj)
                                    case 'e' % EEG
                                        channelArray = [channelArray jj]; % add channel
                                        processArray = [processArray 1];
                                    case 'x' % 'discard'
                                        if (~self.dropXChannels) % take in
                                            channelArray = [channelArray jj]; % add channel
                                            processArray = [processArray 0];
                                        end
                                    case 'c' % ECG
                                        channelArray = [channelArray jj]; % add channel
                                        processArray = [processArray 0];
                                    otherwise
                                        % do nothing, i.e. channel is not taken in
                                end
                            end
                        end

                        if(~isempty(channelArray))
                            self.recordingList(recordIndex).record = tmpRecord;
                            self.recordingList(recordIndex).channels = channelArray;
                            self.recordingList(recordIndex).process = processArray;
                            recordIndex = recordIndex + 1;
                        else
                            fprintf('No any channels defined to be taken in for %s\n', tmpRecord.edf);
                        end

                    else
                        fprintf('File %s defined in Excel not found in folder.\n', fileName(i));
                    end
                end
            else
                 fprintf('EDF files not found.\n');
            end
        end
        
        % getters
        function recordingList = getRecordingList(self)
            recordingList = self.recordingList;
        end
    end
end