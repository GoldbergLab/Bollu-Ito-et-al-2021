function plotArbitraryData(targetAxes, variablesToPlot, variableNames, clearFirst)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% <function name>: <short description>
% usage:  [<output args>] = <function name>(<input args>)
%
% where,
%    <arg1> is <description>
%    <arg2> is <description>
%    <argN> is <description>
%
% <long description>
%
% See also: <related functions>

% Version: <version>
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

verbose = false;

if verbose, disp('plotArbitraryData...'), end
if verbose, disp(vinfo(variablesToPlot)), end

numVar = length(variablesToPlot);

if ~iscell(variablesToPlot)
    disp('Variables to plot:')
    vdisp(variablesToPlot)
    error('variablesToPlot argument must be a cell array');
end
if ~exist('clearFirst', 'var')
    clearFirst = false;
end
if isempty(variablesToPlot)
    if clearFirst
        targetAxes.cla();
    end
    return;
end
if ~exist('variableNames', 'var')
    variableNames = {};
end
if strcmp(variableNames, 'none')
    variableNames = {};
else
    if length(variableNames) > numVar
        variableNames = variableNames(1:numVar);
    elseif length(variableNames) < numVar
        for k = length(variableNames)+1:numVar
            variableNames{k} = ['Var', num2str(k)];
        end
    end
end

if clearFirst
    targetAxes.cla()
end

hold(targetAxes, 'on');

cellVariables = cellfun(@iscell, variablesToPlot);
if any(cellVariables)
    cellLength = unique(cellfun(@length, variablesToPlot(cellVariables)));
    if numel(cellLength) > 1
        error('If more than one input variables are cell arrays, all the cell array variables must be the same length.')
    end
end

switch numVar
    case 1
        % Only one variable to plot
        if cellVariables
            % Spread out stacked vars.
            if verbose, disp('plotArbitraryData: one set of stacked vars'), end
            [newVariablesToPlot, newVariableNames] = spreadOutStackedVariables(variablesToPlot, cellVariables, cellLength, variableNames);
            plotArbitraryData(targetAxes, newVariablesToPlot, newVariableNames)
        else
            % Plot a histogram of the variable
            targetAxes.XTickMode = 'auto';
            targetAxes.YTickMode = 'auto';
            histogram(targetAxes, variablesToPlot{1});
            if ~isempty(variableNames)
                xlabel(targetAxes, variableNames{1})
            end
            ylabel(targetAxes, 'Frequency')
            view(targetAxes, 2)
        end
    case 2
        if any(cellVariables)
            % Some or all of these variables are stacked variables.
            if verbose, disp('plotArbitraryData: two sets of stacked vars'), end
            [newVariablesToPlot, newVariableNames] = spreadOutStackedVariables(variablesToPlot, cellVariables, cellLength, variableNames);
            plotArbitraryData(targetAxes, newVariablesToPlot, newVariableNames)
        else
            % No stacked variables - just plot them
            if length(variablesToPlot{1}) == length(variablesToPlot{2})
                targetAxes.XTickMode = 'auto';
                targetAxes.YTickMode = 'auto';
                if verbose, disp('plotArbitraryData: plot 2'), end
                plot(targetAxes, variablesToPlot{1}, variablesToPlot{2})
                if ~isempty(variableNames)
                    xlabel(targetAxes, variableNames{1});
                    ylabel(targetAxes, variableNames{2});
                end
                view(targetAxes, 2)
            else
                if ~isempty(variableNames)
                    varName1 = variableNames(1); varName2 = variableNames(2);
                else
                    varName1 = {}; varName2 = {};
                end
                plotArbitraryData(targetAxes, variablesToPlot{1}, varName1)
                plotArbitraryData(targetAxes, variablesToPlot{2}, varName2)
            end
        end
    case 3
        if any(cellVariables)
            % Some or all of these variables are stacked variables.
            if verbose, disp('plotArbitraryData: three sets of stacked vars'), end
            [newVariablesToPlot, newVariableNames] = spreadOutStackedVariables(variablesToPlot, cellVariables, cellLength, variableNames);
            plotArbitraryData(targetAxes, newVariablesToPlot, newVariableNames)
        else
            % No stacked variables - just plot them
            targetAxes.XTickMode = 'auto';
            targetAxes.YTickMode = 'auto';
            targetAxes.ZTickMode = 'auto';
            targetAxes.XTickLabel = [];
            targetAxes.YTickLabel = [];
            targetAxes.ZTickLabel = [];
            if verbose, disp('plotArbitraryData: plot 3'), end
            plot3(targetAxes, variablesToPlot{1}, variablesToPlot{2}, variablesToPlot{3})
            if ~isempty(variableNames)
                xlabel(targetAxes, variableNames{1});
                ylabel(targetAxes, variableNames{2});
                zlabel(targetAxes, variableNames{3});
            end
            view(targetAxes, 3)
            grid(targetAxes, 'on')
        end
    otherwise
        if length(variablesToPlot{1}) == 1 && iscell(variablesToPlot{1})
            try
                if verbose, disp('plotArbitraryData: flattening singlet cell'), end
                variablesToPlot = cellfun(@(x)x{1}, variablesToPlot, 'UniformOutput', false);
            catch ME
            end
        end
        variableLengths = cellfun(@length, variablesToPlot);
        % This could be doubles or triplets - figure it out by seeing
        %   how the lengths of the inner arrays match up.
        if mod(numVar, 2) == 0
            dualMatchups = all(variableLengths(1:2:numVar) == variableLengths(2:2:numVar));
        else
            dualMatchups = false;
        end
        if mod(numVar, 3) == 0
            tripleMatchups = all(variableLengths(1:3:numVar) == variableLengths(2:3:numVar)) & ...
                             all(variableLengths(1:3:numVar) == variableLengths(3:3:numVar));
        else
            tripleMatchups = false;
        end
        if mod(numVar, 2) == 0 && dualMatchups
            % # arguments is > 3 but multiple of two. Plot variables in
            %   pairs.
            if verbose, disp('plotArbitraryData: plotting as doubles'), end
            for k = 1:2:numVar
                if ~isempty(variableNames)
                    varNames = variableNames(k:k+1);
                else
                    varNames = {};
                end
                if verbose, disp('plotArbitraryData: these seem to be pairs'), end
                plotArbitraryData(targetAxes, variablesToPlot(k:k+1), varNames);
            end
        elseif mod(numVar, 3) == 0 && tripleMatchups
            % # arguments is > 3 but multiple of three. plot variables in
            %   triplets.
            for k = 1:3:numVar
                if ~isempty(variableNames)
                    varNames = variableNames(k:k+2);
                else
                    varNames = {};
                end
                if verbose, disp('plotArbitraryData: these seem to be triplets'), end
                plotArbitraryData(targetAxes, variablesToPlot(k:k+2), varNames);
            end
        else
            % Just plot them individually as single variables
            for k = 1:numVar
                if ~isempty(variableNames)
                    varNames = variableNames(k);
                else
                    varNames = {};
                end
                if verbose, disp('plotArbitraryData: these seem to be singlets'), end
                plotArbitraryData(targetAxes, variablesToPlot(k), varNames);
            end
        end
end

hold(targetAxes, 'off');

function [newVariablesToPlot, newVariableNames] = spreadOutStackedVariables(variablesToPlot, cellVariables, cellLength, variableNames)
    % Rearrange any stacked variables as a repeated list. Any non-cell
    %   variables will be duplicated.
    % Example: 
    % variablesToPlot = {{a1, a2, a3}, {b1, b2, b3}, c, {d1, d2, d3}}
    %   becomes
    % variablesToPlot = {a1, b1, c, d1, a2, b2, c, d2, a3, b3, c, d3}
    numVar = length(variablesToPlot);
    newVariablesToPlot = {};
    newVariableNames = {};
    for k = 1:cellLength
        for v = 1:numVar
            if cellVariables(v)
                newVariablesToPlot{numVar*(k-1)+v} = variablesToPlot{v}{k};
            else
                newVariablesToPlot{numVar*(k-1)+v} = variablesToPlot{v};
            end
            if ~isempty(variableNames)
                newVariableNames{numVar*(k-1)+v} = variableNames{v};
            end
        end
    end

