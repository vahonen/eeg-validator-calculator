# eeg-validator-calculator
## Configurable parameters
### validator_config.json
Key | Value range | Description
------------ | ------------- | ---------------
zeroTouch | true, false | **true**: No user intervention needed, validator_config.json settings and first found Excel in the working directory are used, **false**: user intervention needed (configuration file and Excel will be asked)
logfile | *character string* | The name for the file for storing Matlab log (diary)
timezone | *character string* | IANA specified timezone (e.g. Europe/Helsinki)
cleanedFolder | *character string* | The Folder where cleaned signals are to be stored
dropXchannels | true, false | **true**: 'x' marked channels in Excel are taken in (even though not processed), **false**: 'x' marked channels are dropped
epochTime | *positive number* | Signal segment (epoch) length in seconds, for validating
overlapPercent | 0..100 | Signal segment (epoch) overlap percentage, for validating (value 100 is not recommended)
setArtefactsToZero | true, false | **true**: Artefactual epochs are zeroed, **false**: Artefactual epochs are not zeroed
overwriteCleanedRecordings | true, false | **true**: cleaned recordings are overwritten, **false**: Cleaned recordings are not overwritten (file names postfixed with date and time)
createXmlAnnotations.artefacts | true, false | **true**: Create EDFbrowser compatible XML annotations for artefacts, **false**: Do not create XML annotations
createXmlAnnotations.stimulus | true, false | **true**: Create EDFbrowser compatible XML annotations for stimuli/events, **false**: Do not create XML annotations
useInfoFileLabels | true, false | **true**: Read channel labels from .info file (and store with cleaned EDF files), **false**: Use channel labels extracted from original EDF files

### calculator_config.json
Key | Value range | Description
------------ | ------------- | ---------------
zeroTouch | true, false | **true**: No user intervention needed, validator_config.json settings used, **false**: User intervention needed (EDF source directory and configuration file will be asked)
logfile | *character string* | The name for the file for storing Matlab log (diary)
sourceFolder | *character string* | The folder where EDF recordings for the metrics calculation are read
resultsFolder | *character string* | The folder where the calculated metrics are stored
timezone | *character string* | IANA specified timezone (e.g. Europe/Helsinki)
eventAdvance | *positive number* | Metrics measurement interval start point, prior to triggering event (in milliseconds)
eventDelay | *positive number* | Metrics measurement interval end point, post to triggering event (in milliseconds)
useInfoFileLabels | true, false | **true**: Read channel labels from .info file, **false**: Use channel labels extracted from EDF files
savedObjectName | *character string* | Name for the file where the Matlab object containing the calculated metrics is stored
overwriteSavedObject | true, false | **true**: The metrics object file is overwritten, **false**: The metrics object file is not overwritten (file names postfixed with date and time)

## Excel file for Calculator

Excel file has to contain the following mandatory column headers:
* filename
* channels

You can add any other (optional) columns as you like.
  
All processed EDF files (without .edf extension) should be added to _filename_ columnn. The calculator searches named EDF files in the working directory and in its all sub-directories. In _channels_ column, EEG channels are marked with 'e', ECG channels with 'c' and any other channels with 'x'.

Example:

![Image of Yaktocat](https://i.ibb.co/MnmNPR2/data-excel.png)

