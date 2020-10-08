clc
%clear all
close all

addpath('./Services');
addpath('./Domain');
addpath('./Algorithms');

% read default configuration from calculator_config.json file
config = jsondecode(fileread('calculator_config.json'));
zeroTouch = config.zeroTouch;

% zeroTouch = false => ask user for excel file and configuration file
% zeroTouch = true => load (first found) excel file in working dir and use default_config.json for
% configuration

% save output to logfile (with overwrite, i.e. delete previous file)
logfile = config.logfile;

if exist(logfile, 'file')
    fid = fopen(logfile, 'w');
    fclose(fid);
    delete(logfile)
end

diary(logfile) % start logging

%ISO8601 date and time
fprintf("Calculator started\n");
fprintf("%s\n", datetime('now','TimeZone',config.timezone,'Format','yyyy-MM-dd''T''HH:mm:ss.SSSZ'));

tic % start stopwatch timer

if (~zeroTouch)
    edfDir = uigetdir(pwd, 'Select EDF directory (all subdirectories will be included)');
else
    edfDir = fullfile(pwd, config.sourceFolder);
end

fprintf("Selected directory: %s\n", edfDir);

recordingList = dir(fullfile(edfDir, '**\*.edf')); % list all edf-files under selected dir (+subdirs)
calculationAlgorithm = setAlgorithms(config.calculators, 'calculator'); % set calculation algs as per json

for jj = 1:numel(recordingList) % loop through recordings
    
    edfFile = recordingList(jj).name;
    folder = recordingList(jj).folder;
    
    % read data from mat file
    dataFile = strcat(edfFile(1:end-4), '.mat');
   
    if (~exist(fullfile(folder, dataFile), 'file'))
        error('mat file for %s not found', fullfile(folder, edfFile));
    end
    
    recordingData = open(fullfile(folder, dataFile)); % read vars from mat
    
    fprintf('\nProcessing recording: %s\n', edfFile);
    
    [header, rec] = edfread(fullfile(folder, edfFile)); % read all channels
    %[header, rec] = edfread(fullfile(folder, edfFile), 'targetSignals', find(recordingData.header.processedChannels));
    
    
    labels = [];
    if (config.useInfoFileLabels)
        infoFile = dir(fullfile(folder, '*.info'));
        if (isempty(infoFile))
            fprintf("Info file labels to be used but info file is not available. Using labels from edf file.\n");
        else
            labels = readLabelsFromInfo(fullfile(folder, infoFile(1).name));
        end
    end
    
    recording(jj) = Recording(edfFile, header, rec, labels); % create Recording object for edf recording
   
    % add new property 'validEvents' to Channel object to be used in analysis
    % + fill in information from recordingData
    for i = 1:length(recording(jj).channel)
        recording(jj).channel(i).addprop('validEvents'); % add property validEvents
        recording(jj).channel(i).epochLengthInSamples = recordingData.channel(i).epochLengthInSamples;
        recording(jj).channel(i).epochOverlapInSamples = recordingData.channel(i).epochOverlapInSamples;
        recording(jj).channel(i).epochCount = recordingData.channel(i).epochCount;
        recording(jj).channel(i).invalidEpochs = recordingData.channel(i).invalidEpochs;
    end
    
    logFile = char(recordingData.header.edfFile);
    logFile = logFile(1:end-4);
    
    gameEvents = readNBackEvents(folder, logFile); % read game events from log-file
    
    % validate events -> invalid if overlapping with artefact seg
    for i = 1:length(recording(jj).channel)
        if(recordingData.header.processedChannels(i))
            fprintf('Validating events for channel %s\n', recording(jj).channel(i).label);
            validEvents = validateEvents(gameEvents, recordingData.header.start, recordingData.channel(i), config.eventAdvance, config.eventDelay, length(recording(jj).channel(i).samples));
            recording(jj).channel(i).validEvents = validEvents; % store valid events to channel specific struct
        else
            fprintf('Channel %s not selected for analysis\n', recording(jj).channel(i).label); % either ECG or selected as 'discarded' by user
        end
    end
    
    % create nBackCalculator object for recording (rec nbr: jj)
    nBackCalculator(jj) = NBackCalculator(calculationAlgorithm, edfFile);
    nBackCalculator(jj).calculate(recording(jj), recordingData.header.processedChannels); % calculate EEG metric(s)
    
    % ================================================================================ 
    % Calculation results are availabe here (when calculated separately for each event):
    %
    % nBackCalculator(rec_nbr).nBackResults.algorithm(alg_nbr).nBack(n).channel(ch_nbr).event(counter).result
    %
    % - rec nbr: record number, as per loop index (jj)
    % - alg_nbr: algorithm number as per oreder of listed algorithm(s) in calculator_config.json
    % - n: 1 = 0-back, 2 = 1-back, 3 = 2-back ,... 
    % - ch_number: channel number within recording (recording(jj).channel(ch_nbr))
    % - counter: running number of game events (n-back event = number is displayed) 
    % (note: event() has .target, .mouseClickedm .delay fields included as well)
    %
    % ...and when calculated per channel:
    % nBackCalculator(rec_nbr).nBackResults.algorithm(alg_nbr).nBack(n).channel(ch_nbr).result
    %
    % ...and when per recording:
    % nBackCalculator(rec_nbr).nBackResults.algorithm(alg_nbr).nBack(n).result
    %
    
end % loop for all recordings

% save just calculated n-back metrics
if (config.overwriteSavedObject)
    savedObjectName = config.savedObjectName;
else
    savedObjectName = strcat(config.savedObjectName, '_', datestr(now, 'yyyymmdd'), '_', datestr(now,'HHMMSS'));
end

save(savedObjectName, 'nBackCalculator');

% load n-back metrics e.g. like this:
% x = load('nback_object.mat'); % or whatever the mat-file name is
% nBackCalculator = x.nBackCalculator;
% clear x

% actually this gives the same end result with just one line: 
% load('nback_object.mat') % or whatever the mat-file name is

toc % stop stopwatch timer
diary off % stop logging
