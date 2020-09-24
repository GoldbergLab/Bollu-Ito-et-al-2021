function newCellArray = subIdx(cellArray, varargin)
% Convenience function for slicing each array within a cell array of
%   arrays.
% Usage:
%   newCellArray = subIdx(cellArray, indices)
%   newCellArray = subIdx(cellArray, start, stop)
%   newCellArray = subIdx(cellArray, start, step, stop)
% Use NaN in place of stop to indicate the end of the array.

indices = NaN;
start = NaN;
step = NaN;
stop = NaN;
staticIndices = false;
switch length(varargin)
    case 0
        error('Not enough arguments');
    case 1
        indices = varargin{1};
        staticIndices = true;
    case 2
        start = varargin{1};
        stop =  varargin{2};
    case 3
        start = varargin{1};
        step =  varargin{2};
        stop =  varargin{3};
    otherwise
        error('Too many arguments');
end
newCellArray = cell(size(cellArray));
if isnan(indices)
    if isnan(start)
        start = 1;
    end
    if isnan(step)
        step = 1;
    end
end

% Broadcast start, step, and stop into variables the same length as cellArray
switch length(start)
    case 1
        start = zeros(size(cellArray)) + start;
    case length(cellArray)
    otherwise
        error('Start value must be either a scalar or the same length as the cellArray argument')
end
switch length(step)
    case 1
        step = zeros(size(cellArray)) + step;
    case length(cellArray)
    otherwise
        error('Step value must be either a scalar or the same length as the cellArray argument')
end
switch length(stop)
    case 1
        if isnan(stop)
            stop = cellfun(@length, cellArray);
        else
            stop = zeros(size(cellArray)) + stop;
        end
    case length(cellArray)
    otherwise
        error('Stop value must be either a scalar or the same length as the cellArray argument')
end

for k = 1:length(cellArray)
    if ~staticIndices
        indices = start(k):step(k):stop(k);
    end
    newCellArray{k} = cellArray{k}(indices);
end
