# eeg-validator-calculator
## Configurable parameters
### validator_config.json
Key | Value range | Description
------------ | ------------- | ---------------
zeroTouch | true, false | **true**: no user intervention needed, validator_config.json settings used, **false**: user intervention needed
logfile | *character string* | name for the file to save Matlab log
timezone | *character string* | IANA specified timezone (e.g. Europe/Helsinki)
cleanedFolder | *character string* | folder where cleaned signals are to be stored
dropXchannels | true, false | **true**: 'x' marked channels in Excel are taken in, **false**: 'x' marked channels are dropped
epochTime | *positive number* | Signal segment (epoch) length in seconds, for validating
overlapPercent | *positive number* | Signal segment (epoch) overlap, for validating
setArtefactsToZero | true, false | **true**: artefactual epochs are zeroed, **false**: artefactual epochs are not zeroed
overwriteCleanedRecordings | true, false | **true**: cleaned recordings are overwritten, **false**: cleaned recordings are not overwritten (date and time added to file names)
createXmlAnnotations.artefacts | true, false | **true**: create EDFbrowser compatible XML annotations for artefacts, **false**: do not create XML annotations
createXmlAnnotations.stimulus | true, false | **true**: create EDFbrowser compatible XML annotations for stimuli/events, **false**: do not create XML annotations, **false**: do not create XML annotations
useInfoFileLabels | true, false | **true**: read channel labels from .info file (and store with cleaned EDF files), **false**: use channel labels extracted from the original EDF file
