function idx = coIdx(data)
if iscell(data)
    % This is a cell array - generate an index series for each array
    idx = cellfun(@(d)1:length(d), data, 'UniformOutput', false);
else
    % This is hopefully a numeric array. generate a single index series
    idx = 1:length(data);
end