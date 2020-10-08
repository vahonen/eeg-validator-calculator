%edfsave, works with and based on edfread.m

%stores only those channels that are loaded with edfread.m, that is,
%saved edf has less channels than in original edf
%if all channels were not loaded with edfread.m


function edfsave(filename, hdr, recording)

fid = fopen(filename, 'wb', 'ieee-le');

% save header
fprintf(fid, '%-8s', string(hdr.ver));
fprintf(fid, '%-80s', string(hdr.patientID));
fprintf(fid, '%-80s',string(hdr.recordID));
fprintf(fid, '%8s',string(hdr.startdate));% (dd.mm.yy)
fprintf(fid, '%8s', string(hdr.starttime));% (hh.mm.ss)
fprintf(fid, '%-8s', convertNumberToString(256*(1 + hdr.ns), 8)); % bytes
fprintf(fid, '%-44s', 'Reserved field of 44 characters'); % could be read in edfread
fprintf(fid,'%-8s',convertNumberToString(hdr.records, 8));
fprintf(fid,'%-8s',convertNumberToString(hdr.duration, 8));
fprintf(fid,'%-4s',convertNumberToString(hdr.ns, 4));

for ii = 1:hdr.ns
    fprintf(fid, '%-16s', string(hdr.label{ii}));
end

for ii = 1:hdr.ns
    fprintf(fid,'%-80s',string(hdr.transducer{ii}));
end

for ii = 1:hdr.ns
    fprintf(fid,'%-8s',string(hdr.units{ii}));
end
% Physical minimum
for ii = 1:hdr.ns
    fprintf(fid,'%-8s',convertNumberToString(hdr.physicalMin(ii), 8));
end
% Physical maximum
for ii = 1:hdr.ns
    fprintf(fid,'%-8s',convertNumberToString(hdr.physicalMax(ii), 8));
end
% Digital minimum
for ii = 1:hdr.ns
    fprintf(fid,'%-8s',convertNumberToString(hdr.digitalMin(ii), 8));
end
% Digital maximum
for ii = 1:hdr.ns
    fprintf(fid,'%-8s',convertNumberToString(hdr.digitalMax(ii), 8));
end
for ii = 1:hdr.ns
    fprintf(fid,'%-8s',string(hdr.prefilter{ii}));
end
for ii = 1:hdr.ns
    fprintf(fid,'%-8s',convertNumberToString(hdr.samples(ii), 8));
end
for ii = 1:hdr.ns
    fprintf(fid,'%-32s','reserved'); % could be read in edfread
end

% for de-scaling
scalefac = (hdr.physicalMax - hdr.physicalMin)./(hdr.digitalMax - hdr.digitalMin);
dc = hdr.physicalMax - scalefac .* hdr.digitalMax;

% save data
for ii = 1:hdr.records
    for jj = 1:hdr.ns
        dataBlock = recording.channel(jj).samples((ii-1)*hdr.samples(jj)+1:ii*hdr.samples(jj));
        dataBlock = (dataBlock - dc(jj)) / scalefac(jj); % de-scale (physical -> digital)
        fwrite(fid,dataBlock,'int16');
    end
    
end
fclose(fid);