# eeg-validator-calculator
## Configurable parameters
### validator_config.json
Key | Value range | Description
------------ | ------------- | ---------------
zeroTouch | true, false | **true**: No user intervention needed, validator_config.json settings and first found Excel in working directory are used, **false**: user intervention needed (configuration file and Excel will be asked)
logfile | *character string* | The name for the file for storing Matlab log
timezone | *character string* | IANA specified timezone (e.g. Europe/Helsinki)
cleanedFolder | *character string* | The Folder where cleaned signals are to be stored
dropXchannels | true, false | **true**: 'x' marked channels in Excel are taken in (even though not processed), **false**: 'x' marked channels are dropped
epochTime | *positive number* | Signal segment (epoch) length in seconds, for validating
overlapPercent | *positive number* | Signal segment (epoch) overlap, for validating
setArtefactsToZero | true, false | **true**: artefactual epochs are zeroed, **false**: artefactual epochs are not zeroed
overwriteCleanedRecordings | true, false | **true**: cleaned recordings are overwritten, **false**: cleaned recordings are not overwritten (date and time added to file names)
createXmlAnnotations.artefacts | true, false | **true**: create EDFbrowser compatible XML annotations for artefacts, **false**: do not create XML annotations
createXmlAnnotations.stimulus | true, false | **true**: create EDFbrowser compatible XML annotations for stimuli/events, **false**: do not create XML annotations, **false**: do not create XML annotations
useInfoFileLabels | true, false | **true**: read channel labels from .info file (and store with cleaned EDF files), **false**: use channel labels extracted from the original EDF file

### calculator_config.json
Key | Value range | Description
------------ | ------------- | ---------------
zeroTouch | true, false | **true**: no user intervention needed, validator_config.json settings used, **false**: user intervention needed
logfile | *character string* | The name for the file for storing Matlab log
sourceFolder | *character string* | The folder from where EDF recordings for the metrics calculation are read
resultsFolder | *character string* | The folder where the calculated metrics are stored
timezone | *character string* | IANA specified timezone (e.g. Europe/Helsinki)
eventAdvance | *positive number* | Metrics measurement interval start prior to triggering event (in milliseconds)
eventDelay | *positive number* | Metrics measurement interval end post to triggering event (in milliseconds)
useInfoFileLabels | true, false | **true**: read channel labels from .info file, **false**: use channel labels extracted from the EDF file
savedObjectName | *character string* | Name for the file where the Matlab object containing the calculated metrics is stored
overwriteSavedObject | true, false | **true**: the metrics object file is overwritten, **false**: the metrics object file is not overwritten (date and time added to file name)
