function labels = readLabelsFromInfo(fname)
labels = [];

fid = fopen(fname);

expression = 'Channel \d+: (\w*)';

while (~feof(fid))
    line = fgets(fid);
    x = regexp(line, expression, 'tokens');
    if (~isempty(x))
        labels = [labels x{1}];
    end
end

fclose(fid);

end