function output = vinfo(var, recurseDepth, maxLines, indentLevel, varName, showIntro, suppressInitialIndent)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% vinfo: A function to quickly see variable types, sizes, and structures
% usage:  output = vinfo(var)
%         output = vinfo(var, recurseDepth)
%         output = vinfo(var, recurseDepth, maxLines)
% For internal use only:
%         output = vinfo(var, recurseDepth, maxLines, indentLevel)
%         output = vinfo(var, recurseDepth, maxLines, indentLevel, varName)
%         output = vinfo(var, recurseDepth, maxLines, indentLevel, varName, showIntro)
%         output = vinfo(var, recurseDepth, maxLines, indentLevel, varName, showIntro, suppressInitialIndent)
%
% where,
%    output is a char array containing the variable description
%    var is the variable to describe
%    recurseDepth is how many layers deep to go into the variable structure
%    maxLines is the # of lines to display for each recurse level before
%       abbreviating
%    indentLevel is an internal variable to use readable indentation
%    varName is an internal variable to transmit input variable name
%    showIntro is an internal variable
%    suppressInitialIndent is an internal variable
%
% This is a way to display a flexible, detailed summary of a variable's
%   type, size, contents, and structure
%
% See also: vdisp
% Version: <version>
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('indentLevel', 'var')
    indentLevel = 0;
end
if ~exist('recurseDepth', 'var')
    recurseDepth = 2;
end
if ~exist('varName', 'var')
    varName = inputname(1);
end
if ~exist('showIntro', 'var')
    showIntro = true;
end
if ~exist('suppressIndent', 'var')
    suppressInitialIndent = false;
end
if ~exist('maxLines', 'var')
    maxLines = -1;
end

if isempty(varName)
    varName = 'anonymous';
end
getIndent = @(level)repmat(char(9), [1, level]);
output = getIndent(indentLevel*suppressInitialIndent);
varClass = class(var);
varSize = size(var);
varSizeText = join(arrayfun(@num2str, varSize, 'UniformOutput', false), ' x ');
varSizeText = varSizeText{1};
if showIntro
    output = [output, varName, ': '];
end
if isnumeric(var) && isrow(var) && numel(var) < 4
    valueText = [' = ', num2str(var)];
elseif ischar(var)
    valueText = [' = ''', var, ''''];
else
    valueText = '';
end
output = [output, 'class ', varClass, ' ', varSizeText, valueText];
% Next recursion depth info
if recurseDepth > 0
    preLength = floor(maxLines/2);
    postLength = maxLines - preLength - 1;
    switch varClass
        case 'struct'
            varFields = fieldnames(var);
            output = [output, newline, getIndent(indentLevel), 'Fields'];
            abbreviate = (maxLines ~= -1 && numel(varFields) > maxLines);
            if abbreviate
                indices = [1:preLength, -1, numel(varFields)-postLength:numel(varFields)];
            else
                indices = 1:numel(varFields);
            end
            for k = indices
                if k == -1
                    output = [output, newline, getIndent(indentLevel+1), '...'];
                    continue;
                end
                fieldName = varFields{k};
                output = [output, newline, getIndent(indentLevel+1), fieldName];
                if recurseDepth > 1
                    output = [output, ': ', vinfo(var(1).(fieldName), recurseDepth-1, maxLines, indentLevel+1, fieldName, false, true)];
                end
            end
        case 'cell'
            if isvector(var)
                % Don't bother trying to recurse on non-1D cell arrays.
                output = [output, newline, getIndent(indentLevel), 'Elements'];
                abbreviate = (maxLines ~= -1 && numel(var) > maxLines);
                if abbreviate
                    indices = [1:preLength, -1, numel(var)-postLength:numel(var)];
                else
                    indices = 1:numel(var);
                end
                if recurseDepth > 1
                    for k = indices
                        if k == -1
                            output = [output, newline, getIndent(indentLevel+1), '...'];
                            continue;
                        end
                        output = [output, newline, ...
                            getIndent(indentLevel+1), num2str(k), ': ', ...
                            vinfo(var{k}, recurseDepth-1, maxLines, indentLevel+1, num2str(k), false, true)];
                    end
                end
            end
        otherwise
    end
end