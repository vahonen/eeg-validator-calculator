function [appliedAlgs] = setAlgorithms(algList, algType)
appliedAlgs = {};
for i = 1:numel(algList)
    
    if (exist(strcat(algList(i).(algType), '.m'), 'file'))
        
        constructObject = [algList(i).(algType) '('];
        parameterNames = fieldnames(algList(i).parameters);
        
        for jj = 1:numel(parameterNames)
            constructObject = [constructObject , algList(i).parameters.(parameterNames{jj})];
            if (jj < numel(parameterNames))
                constructObject = [constructObject ','];
            end
        end
        constructObject = [constructObject ')'];
        newObject = eval(constructObject);
        appliedAlgs{end + 1} = newObject;
    else
        error('Unknown %s defined in json: %s\n', algType, algList(i).(algType));
    end
end
end
