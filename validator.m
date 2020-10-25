clc
clear all
close all

% turn off warning that might occur when reading excel to ML table
warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');

addpath('./Services');
addpath('./Domain');
addpath('./Algorithms');
addpath('./Filters');

% read default configuration from deafult_config.json file
config = jsondecode(fileread('validator_config.json'));
zeroTouch = config.zeroTouch;

% zeroTouch = false => ask user for excel file and configuration file
% zeroTouch = true => load (first found) excel file in working dir and use default_config.json for
% configuration

if (~zeroTouch)
    [excelFile,excelPath] = uigetfile({'*.xlsx';'*.xls'},...
        'Select Excel file (recordings)');
    [configFile, configPath] = uigetfile({'*.json'},...
        'Select configuration file');
    % read configuration from user given json file
    config = jsondecode(fileread(fullfile(configPath, configFile)));
else
    excelPath = strcat(pwd,'\');
    excelFiles = dir(fullfile(excelPath, '*.xls*'));
    if (~isempty(excelFiles))
        excelFile = excelFiles(1).name; % first found in working dir
        excelPath = excelFiles(1).folder;
    else
        error('Excel file not found in working dir (zero touch is enabled)');
    end
end

% save output to logfile (with overwrite, i.e. delete previous file)
logfile = config.logfile;
if exist(logfile, 'file')
    delete(logfile)
end

diary(logfile) % start logging

%ISO8601 date and time
fprintf("%s\n", datetime('now','TimeZone',config.timezone,'Format','yyyy-MM-dd''T''HH:mm:ss.SSSZ'));

tic % start stopwatch timer

% set filter(s), cleaning algorithms and validation algorithm(s)
filterList = setAlgorithms(config.filters, 'filter');
validationAlgorithm = setAlgorithms(config.validators, 'validator');
cleaningAlgorithm = setAlgorithms(config.cleaners, 'cleaner');

%cleaningAlgorithm = {}; % no cleaning, for quick test (for other parts)
%filterList = {}; % no filtering
validationAlgorithm = {}; % no validation

% create excelRecords object for reading file names
excelRecords = ExcelRecords(excelPath, excelFile, config.dropXChannels);
excelRecords.createFileList();
recordingList = excelRecords.getRecordingList;

for jj = 1:numel(recordingList) % loop through recordings
    
    folder = recordingList(jj).record.folder;
    edfFile = recordingList(jj).record.edf;
    logFile = recordingList(jj).record.log;
    infoFile = recordingList(jj).record.info;
    
    fprintf('\nProcessing recording: %s\n', edfFile);
    
    %edfread.m
    %[header, rec] = edfread(fullfile(folder, edfFile)); %read all channels
    [header, rec] = edfread(fullfile(folder, edfFile), 'targetSignals', recordingList(jj).channels);
    
    % create 'recording' object for EDF data
    % originalRecording(jj) = Recording(edfFile, header, rec); % original data, not currently needed...
    labels = [];
    if (config.useInfoFileLabels)
        if (isempty(infoFile))
            fprintf("Info file labels to be used but info file is not available. Using labels from edf file.\n");
        else
            labels = readLabelsFromInfo(fullfile(folder, infoFile));
            header.label = labels;
        end
    end
    
    recording(jj) = Recording(edfFile, header, rec, labels);
    
    % create filter, cleaner and validator objects
    channelFiltering = ChannelFiltering(filterList);
    channelCleaner = ChannelCleaner(cleaningAlgorithm);
    channelValidator = ChannelValidator(config.epochTime, config.overlapPercent, validationAlgorithm);
    
    % filter, clean and validate channels
    for i = 1:length(recording(jj).channel)
        if(recordingList(jj).process(i))
            channelFiltering.applyFilters(recording(jj).channel(i));
            channelCleaner.clean(recording(jj).channel(i));
            channelValidator.validate(recording(jj).channel(i));
        else
            fprintf('Channel %s not selected for processing\n', recording(jj).channel(i).label);
        end
    end
    
    % plot recordings
    %recording(jj).plotChannels([0 0]); % [startTime endTime], in seconds, e.g. [0 0] for whole signal
    recording(jj).plotChannelsValidity([0 0]);
    
    % set artefactual epochs signal level to zero
    if (config.setArtefactsToZero)
        fprintf('Setting signal levels for artefactual epochs to zero.\n');
        recording(jj).zeroArtefacts();
    end
    
    %recording(jj).plotChannels([0 0]);
    
    % save cleaned recording in edf format
    
    cleanedFolder = fullfile(config.cleanedFolder, edfFile(1 : end - 4));
    if ~exist(cleanedFolder, 'dir')
        mkdir(cleanedFolder)
    end
    
    if (~config.overwriteCleanedRecordings)
        cleanedFilename = strcat(edfFile(1 : end - 4) , '_clean_' , datestr(now, 'yyyymmdd'), '_', datestr(now,'HHMMSS'));
        
    else
        cleanedFilename = strcat(edfFile(1 : end - 4) , '_clean');
    end
    
    cleanedFullFilename = strcat(cleanedFilename,'.edf');
    cleanedFullFilename = fullfile(cleanedFolder, cleanedFullFilename);
    
    fprintf('Saving cleaned recording in edf format: %s\n\n', cleanedFullFilename);
    edfsave(cleanedFullFilename, header, recording(jj));
    
    cleanedFullFilename = strcat(cleanedFilename,'.mat');
    cleanedFullFilename = fullfile(cleanedFolder, cleanedFullFilename);
    
    fprintf('Saving artefactual epochs and other channel specific data in .mat file: %s\n\n', cleanedFullFilename);
    saveChannelData(recording(jj), recordingList(jj).process, cleanedFullFilename);
    
    if (config.createXmlAnnotations.artefacts)
        artefactAnnotationsFolder = fullfile(cleanedFolder, '\Artefacts');
        if ~exist(artefactAnnotationsFolder, 'dir')
            mkdir(artefactAnnotationsFolder)
        end
        
        xmlFilename = fullfile(artefactAnnotationsFolder, cleanedFilename);
        createArtefactXmlAnnotations(recording(jj), xmlFilename);
    end
    
    if (config.createXmlAnnotations.stimulus && ~isempty(logFile))
        stimulusAnnotationsFolder = fullfile(cleanedFolder, '\Stimulus');
        if ~exist(stimulusAnnotationsFolder, 'dir')
            mkdir(stimulusAnnotationsFolder)
        end
        xmlFilename = fullfile(stimulusAnnotationsFolder, cleanedFilename);
        createStimulusXmlAnnotations(recording(jj), fullfile(folder, logFile), xmlFilename);
    end
    
    if (~isempty(logFile))
        copyfile(fullfile(folder, logFile), cleanedFolder);
    end
    
    if (~isempty(infoFile))
        copyfile(fullfile(folder, infoFile), cleanedFolder);
    end
    
end % loop for all recordings (defined in Excel)

toc % stop stopwatch timer
diary off % stop logging
