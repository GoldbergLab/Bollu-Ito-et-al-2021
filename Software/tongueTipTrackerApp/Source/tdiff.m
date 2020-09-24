function diffs = tdiff(tableA, tableB)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% tdiff: Find the differences between two similar tables
% usage:  diffs = tdiff(tableA, tableB)
%
% where,
%    tableA and tableB are two tables with the same fields and dimensions
%    diffs is a struct with fields corresponding to table variable
%       that contain differences between the two tables. The value of each 
%       field is an array of row numbers indicating which rows differ
%       between the two variables for that variable name. The equality
%       comparison is done with the built in "isequal" function.
%
% Compares two tables, and outputs a struct containing the variable names
%   and row numbers that differ between the two tables.
%
% See also: isequal, setdiff

% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%w = width(tableA);

variablesA = tableA.Properties.VariableNames;
variablesB = tableB.Properties.VariableNames;
variablesAll = union(variablesA, variablesB);
variablesShared = intersect(variablesA, variablesB);
variablesNotShared = setdiff(variablesAll, variablesShared);

numRowsA = height(tableA);
numRowsB = height(tableB);
numRowsMax = max([numRowsA, numRowsB]);
numRowsMin = min([numRowsA, numRowsB]);

diffs = struct();
% Mark non-shared variable columns as differences
for variableNum = 1:numel(variablesNotShared)
    variable = variablesNotShared{variableNum};
    for rowNum = 1:numRowsMin
        diffs = updateDiffs(diffs, variable, rowNum);
    end
end
% Mark non-shared rows as differences
for variableNum = 1:numel(variablesAll)
    variable = variablesAll{variableNum};
    for rowNum = numRowsMin+1:numRowsMax
        diffs = updateDiffs(diffs, variable, rowNum);        
    end
end
% Mark any other differences
for variableNum = 1:numel(variablesShared)
    variable = variablesShared{variableNum};
    for rowNum = 1:numRowsMin
        if ~isequal(tableA.(variable)(rowNum), tableB.(variable)(rowNum))
            diffs = updateDiffs(diffs, variable, rowNum);
        end
    end
end

diffs = orderfields(diffs);

function diffs = updateDiffs(diffs, variable, row)
    if ~isfield(diffs, variable)
        diffs.(variable) = [row];
    else
        diffs.(variable) = sort([diffs.(variable), row]);
    end