classdef (HandleCompatible) BankControl < handle
    properties
        bankLayout          matlab.ui.container.GridLayout
        variableControls    VariableControl
        filterControls      FilterControl
        axesGrid            matlab.ui.control.UIAxes
        axesStartCoords     double
        dataTable           table
        cornerLayout        matlab.ui.container.GridLayout
        addBankBeforeButton matlab.ui.control.Button
        addBankAfterButton  matlab.ui.control.Button
        removeBankButton    matlab.ui.control.Button
        exportBankButton    matlab.ui.control.Button
        exportAllBankButton matlab.ui.control.Button
        prePlotCommandsLabel matlab.ui.control.Label
        prePlotCommands     matlab.ui.control.TextArea
    end
    methods (Access = public)
        function obj =            BankControl(parentLayout, row, column, nRows, nCols)
% ? Variables  ?
% ?   to plot     ?
% +/- columns ?
% Sampling ?
% 
% 
% Lick filter?            
            obj.axesStartCoords = [2, 2];
            obj.axesGrid = matlab.ui.control.UIAxes.empty();
            obj.filterControls = FilterControl.empty();
            obj.variableControls = VariableControl.empty();

            % Create bankLayout
            obj.bankLayout = uigridlayout(parentLayout);
            obj.bankLayout.ColumnSpacing = 0;
            obj.bankLayout.RowSpacing = 0;
            obj.bankLayout.Padding = [0 0 0 0];
            obj.bankLayout.Scrollable = 'on';
            obj.bankLayout.ColumnWidth = {};
            obj.bankLayout.RowHeight = {};
            
            obj.cornerLayout = uigridlayout(obj.bankLayout);
            obj.cornerLayout.ColumnSpacing = 2;
            obj.cornerLayout.RowSpacing = 2;
            obj.cornerLayout.Layout.Row = 1;
            obj.cornerLayout.Layout.Column = 1;
            obj.cornerLayout.ColumnWidth = {'1x', '1x', '1x', '3x'};
            obj.cornerLayout.RowHeight = {'1x', '1x', '1x'};
            obj.cornerLayout.Padding = [1, 1, 1, 1];
            obj.addBankBeforeButton = uibutton(obj.cornerLayout, 'Text', '<+', 'Tooltip', 'Add bank left', 'VerticalAlignment', 'center');
            obj.addBankAfterButton =  uibutton(obj.cornerLayout, 'Text', '+>', 'Tooltip', 'Add bank right', 'VerticalAlignment', 'center');
            obj.removeBankButton =    uibutton(obj.cornerLayout, 'Text', 'X', 'Tooltip', 'Remove this bank', 'VerticalAlignment', 'center');
            obj.exportBankButton =    uibutton(obj.cornerLayout, 'Text', '', 'Icon', 'exportIcon.png', 'Tooltip', 'Export bank to a normal figure', 'VerticalAlignment', 'center');
            obj.exportAllBankButton =    uibutton(obj.cornerLayout, 'Text', '', 'Icon', 'exportAllIcon.png', 'Tooltip', 'Export all banks to a normal figure', 'VerticalAlignment', 'center');
            obj.addBankBeforeButton.Layout.Row = 1;
            obj.addBankBeforeButton.Layout.Column = 1;
            obj.removeBankButton.Layout.Row = 1;
            obj.removeBankButton.Layout.Column = 2;
            obj.addBankAfterButton.Layout.Row = 1;
            obj.addBankAfterButton.Layout.Column = 3;
            obj.exportBankButton.Layout.Row = 2;
            obj.exportBankButton.Layout.Column = 2;
            obj.exportAllBankButton.Layout.Row = 2;
            obj.exportAllBankButton.Layout.Column = 3;
            obj.addBankBeforeButton.ButtonPushedFcn = @(src, evt) notify(obj, 'AddBefore');
            obj.addBankAfterButton.ButtonPushedFcn = @(src, evt) notify(obj, 'AddAfter');
            obj.removeBankButton.ButtonPushedFcn = @(src, evt) notify(obj, 'Remove');
            obj.exportBankButton.ButtonPushedFcn = @(src, evt) obj.copyToNewFigure();
            obj.exportAllBankButton.ButtonPushedFcn = @(src, evt) notify(obj, 'ExportAll');

            obj.prePlotCommands = uitextarea(obj.cornerLayout, 'FontName', 'Lucida Console');
            obj.prePlotCommands.Layout.Row = [2, 3];
            obj.prePlotCommands.Layout.Column = 4;
            obj.prePlotCommands.ValueChangedFcn = @(src, evt) notify(obj, 'PrePlotCommandsChanged');

            obj.prePlotCommandsLabel = uilabel(obj.cornerLayout);
            obj.prePlotCommandsLabel.Text = 'Pre-plot commands:';
            obj.prePlotCommandsLabel.Layout.Row = 1;
            obj.prePlotCommandsLabel.Layout.Column = 4;

            obj.updatePosition(row, column);
            
            addlistener(obj, 'BankSizeChanged', @obj.updateRemoveButtonVisibility);
            
            obj.initializeControls(nRows, nCols);
        end
        function                  copyToNewAxes(obj, ax, row, col)
            copyUIAxes(obj.axesGrid(row, col), ax);
        end
        function                  copyToNewFigure(obj, varargin)
            if isempty(varargin)
                container = figure('Position', [10, 10, obj.getBankPixelWidth(), obj.getBankPixelHeight()]);
            else
                container = varargin{1};
            end
            disp('copy to new figure')
            [nRows, nCols] = obj.getBankSize();
%            t = tiledlayout(f, nRows, nCols);
            k = 1;
            for row = 1:nRows
                for col = 1:nCols
                    ax = subtightplot(nRows, nCols, k, [0.075, 0.075], 0.05, 0.05, 'Parent', container);
%                    ax = nexttile(t, k);
                    copyUIAxes(obj.axesGrid(row, col), ax);
                    k = k + 1;
                end
            end
        end
        function                  updatePosition(obj, newRow, newCol)
            obj.bankLayout.Layout.Row = newRow;
            obj.bankLayout.Layout.Column = newCol;
        end
        function [nRows, nCols] = getBankSize(obj)
            [nRows, nCols] = size(obj.axesGrid);
        end
        function width          = getBankPixelWidth(obj)
            if isempty(obj.bankLayout.ColumnWidth)
                width = 1;
                return;
            elseif ~isnumeric(obj.bankLayout.ColumnWidth{1})
                width = 1;
                return;
            end
            componentWidth = sum(cell2mat(obj.bankLayout.ColumnWidth));
            spacingWidth = obj.bankLayout.ColumnSpacing * (length(obj.bankLayout.ColumnWidth)-1);
            width = componentWidth + spacingWidth + 20;  % Extra bit for scrollbar
        end
        function height          = getBankPixelHeight(obj)
            if isempty(obj.bankLayout.RowHeight)
                height = 1;
                return;
            elseif ~isnumeric(obj.bankLayout.RowHeight{1})
                height = 1;
                return;
            end
            componentHeight = sum(cell2mat(obj.bankLayout.RowHeight));
            spacingHeight = obj.bankLayout.RowSpacing * (length(obj.bankLayout.RowHeight)-1);
            height = componentHeight + spacingHeight + 20;  % Extra bit for scrollbar
        end
        function filterText =     getFilterText(obj, col)
            filterText = obj.filterControls(col).getFilterText();
        end
        function variableString = getVariableString(obj, row)
            variableString = obj.variableControls(row).getVariableString();
        end
        function variableText =   getVariableText(obj, row)
            variableText = obj.variableControls(row).getVariableText();
        end
        function variableText = getCleanedVariableText(obj, row)
            variableText = obj.getVariableText(row);
            variableText = strtrim(variableText);
            % Remove blank or whitespace only rows
            variableText(cellfun(@length, variableText)==0) = [];
        end
        function variableText =   getAllVariableText(obj)
            variableTexts = arrayfun(@(v)v.getVariableString(), obj.variableControls, 'UniformOutput', false);
            variableText = join(variableTexts, ' ');
        end
        function prePlotCommandText = getPrePlotCommandText(obj)
            prePlotCommandText = obj.prePlotCommands.Value;
        end
        function ax =             getAxes(obj, row, col)
            ax = obj.axesGrid(row, col);
        end
        function filterStruct =   exportFilters(obj)
            [~, nFilters] = obj.getBankSize();
            for k = 1:nFilters
                filterStruct(k).Text = obj.getFilterText(k);
                filterStruct(k).PostFilterMode = obj.filterControls(k).postFilterMode.Value;
                filterStruct(k).PostFilterValue = obj.filterControls(k).postFilterValue.Value;
            end
        end
        function variableStruct = exportVariables(obj)
            [nVariables, ~] = obj.getBankSize();
            for k = 1:nVariables
                variableStruct(k).Text = obj.getVariableText(k);
            end
        end
        function bankStruct =     exportBank(obj)
            bankStruct.Filters = obj.exportFilters();
            bankStruct.Variables = obj.exportVariables();
            bankStruct.PrePlotCommands = obj.getPrePlotCommandText();
        end
        function                  importBank(obj, bankStruct)
            obj.deleteControls();
            if isfield(bankStruct, 'Filters')
                for k = 1:length(bankStruct.Filters)
                    obj.addCol(NaN, bankStruct.Filters(k).Text, bankStruct.Filters(k).PostFilterMode, bankStruct.Filters(k).PostFilterValue);
                end
            end
            if isfield(bankStruct, 'Variables')
                for k = 1:length(bankStruct.Variables)
                    obj.addRow(NaN, bankStruct.Variables(k).Text);
                end
            end
            if isfield(bankStruct, 'PrePlotCommands')
                obj.prePlotCommands.Value = bankStruct.PrePlotCommands;
            else
                obj.prePlotCommands.Value = '';
            end
        end
        function                  delete(obj)
            obj.destroyFilterControls();
            obj.destroyVariableControls();
            obj.destroyAxesGrid();
            delete(obj.addBankBeforeButton);
            delete(obj.addBankAfterButton);
            delete(obj.removeBankButton);
            delete(obj.cornerLayout);
            delete(obj.bankLayout);
        end
    end
    methods (Access = private)
        function valid =              checkValidSizes(obj)
            [nRows, nCols] = obj.getBankSize();
            nFilters = length(obj.filterControls);
            nVariables = length(obj.variableControls);
            if nRows < 0 || nCols < 0 || nRows ~= nVariables || nCols ~= nFilters
                valid = False;
            else
                valid = True;
            end
        end
        function                      updateRemoveButtonVisibility(obj, varargin)
            nRows = length(obj.variableControls);
            if nRows > 0
                onlyOneRowLeft = (nRows == 1);
                obj.variableControls(1).removeButtonVisibility(~onlyOneRowLeft);
                for row = 2:nRows
                    obj.variableControls(row).removeButtonVisibility(true);
                end
            end
            nCols = length(obj.filterControls);
            if nCols > 0
                onlyOneColLeft = (nCols == 1);
                obj.filterControls(1).removeButtonVisibility(~onlyOneColLeft);
                for col = 2:nCols
                    obj.filterControls(col).removeButtonVisibility(true);
                end
            end
        end
        function newFilterControl =   createNewFilterControl(obj, col, text, mode, value)
            if ~exist('text', 'var')
                text = '';
            end
            if ~exist('mode', 'var')
                mode = '1st sequential N';
            end
            if ~exist('value', 'var')
                value = 5;
            end
            absCol = obj.getAbsoluteCol(col);
            absRow = 1;
            newFilterControl = FilterControl(obj.bankLayout, absCol, absRow, col, text, mode, value);
            newFilterControl.Column = col;
            addlistener(newFilterControl, "FilterChanged", @obj.filterControlChangedCallback);
            addlistener(newFilterControl, "AddBefore", @obj.addBeforeHandler);
            addlistener(newFilterControl, "AddAfter", @obj.addAfterHandler);
            addlistener(newFilterControl, "Remove", @obj.removeHandler);
        end
        function newVariableControl = createNewVariableControl(obj, row, text)
            if ~exist('text', 'var')
                text = '';
            end
            absCol = 1;
            absRow = obj.getAbsoluteRow(row);
            newVariableControl = VariableControl(obj.bankLayout, absCol, absRow, text);
            newVariableControl.Row = row;
            addlistener(newVariableControl, 'VariablesChanged', @obj.variableControlChangedCallback);
            addlistener(newVariableControl, "AddBefore", @obj.addBeforeHandler);
            addlistener(newVariableControl, "AddAfter", @obj.addAfterHandler);
            addlistener(newVariableControl, "Remove", @obj.removeHandler);
        end
        function newAxes =            createNewAxes(obj, row, col)
            newAxes = uiaxes(obj.bankLayout, 'XTick', [], 'YTick', [], 'TickLabelInterpreter', 'none');
            newAxes.Layout.Column = obj.getAbsoluteCol(col);
            newAxes.Layout.Row = obj.getAbsoluteRow(row);
            newAxes.UserData = struct();
            newAxes.UserData.col = col;
            newAxes.UserData.row = row;
%            tempAxesGrid(col, row).ContextMenu = obj.axesContextMenu;
            axis(newAxes, 'square');
        end
        function absCol =             getAbsoluteCol(obj, gridCol)
            absCol = gridCol + obj.axesStartCoords(1) - 1;
        end
        function absRow =             getAbsoluteRow(obj, gridRow)
            absRow = gridRow + obj.axesStartCoords(2) - 1;
        end
        function gridCol =            getGridCol(obj, absCol)
            gridCol = absCol - obj.axesStartCoords(1) + 1;
        end
        function gridRow =            getGridRow(obj, absRow)
            gridRow = absRow + obj.axesStartCoords(2) + 1;
        end
        function                      setLayoutSize(obj, nRows, nCols)
            nAbsRows = obj.getAbsoluteRow(nRows);
            nAbsCols = obj.getAbsoluteCol(nCols);
            obj.bankLayout.RowHeight = {};
            obj.bankLayout.ColumnWidth = {};
            [obj.bankLayout.RowHeight{1:nAbsRows}] = deal(250);
            [obj.bankLayout.ColumnWidth{1:nAbsCols}] = deal(250);
            obj.bankLayout.RowHeight{1} = 75;
            obj.bankLayout.ColumnWidth{1} = 225;
        end
        function                      addRow(obj, addRow, text)
            [nRows, nCols] = obj.getBankSize();
            obj.setLayoutSize(nRows+1, nCols);
            if ~exist('addRow', 'var') || isnan(addRow)
                addRow = nRows+1;
            end
            if ~exist('text', 'var')
                text = '';
            end
            if ~isnumeric(addRow) || addRow < 0 || addRow > nRows+1
                error('Row must be a number between 0 and the number of rows + 1');
            end
            % Shift variable control rows
            for row = addRow:nRows
                obj.variableControls(row).deltaRow(1);
                for col = 1:nCols
                    % Shift axes
                    obj.axesGrid(row, col).Layout.Row = obj.axesGrid(row, col).Layout.Row + 1;
                    obj.axesGrid(row, col).UserData.col = col;
                    obj.axesGrid(row, col).UserData.row = row+1;
                end
            end
            % Create new variable control
            newVariableControl = obj.createNewVariableControl(addRow, text);
            % Insert new control into container
            obj.variableControls = [obj.variableControls(1:addRow-1), newVariableControl, obj.variableControls(addRow:nRows)];
            % Create new vector of axes
            newAxes = arrayfun(@(col)obj.createNewAxes(addRow, col), 1:nCols);
            % Insert new axes
            obj.axesGrid = [obj.axesGrid(1:addRow-1, :); newAxes; obj.axesGrid(addRow:end, :)];
            [nRows, nCols] = obj.getBankSize();
            notify(obj, 'BankSizeChanged');
        end
        function                      addCol(obj, addCol, text, mode, value)
            if ~exist('text', 'var')
                text = '';
            end
            if ~exist('mode', 'var')
                mode = '1st sequential N';
            end
            if ~exist('value', 'var')
                value = 5;
            end
            [nRows, nCols] = obj.getBankSize();
            obj.setLayoutSize(nRows, nCols+1);
            if ~exist('addCol', 'var') || isnan(addCol)
                addCol = nCols+1;
            end
            if ~isnumeric(addCol) || addCol < 0 || addCol > nCols+1
                error('Col must be a number between 0 and the number of cols + 1');
            end
            % Shift variable control rows
            for col = addCol:nCols
                obj.filterControls(col).deltaColumn(1);
                for row = 1:nRows
                    % Shift axes
                    obj.axesGrid(row, col).Layout.Column = obj.axesGrid(row, col).Layout.Column + 1;
                    obj.axesGrid(row, col).UserData.col = col+1;
                    obj.axesGrid(row, col).UserData.row = row;
                end
            end
            % Create new variable control
            newFilterControl = obj.createNewFilterControl(addCol, text, mode, value);
            % Insert new control into container
            obj.filterControls = [obj.filterControls(1:addCol-1), newFilterControl, obj.filterControls(addCol:nCols)];
            % Create new vector of axes
            newAxes = arrayfun(@(row)obj.createNewAxes(row, addCol), 1:nRows);
            % Insert new axes
            obj.axesGrid = [obj.axesGrid(:, 1:addCol-1), newAxes', obj.axesGrid(:, addCol:end)];
            notify(obj, 'BankSizeChanged');
        end
        function                      removeRow(obj, removeRow)
            [nRows, nCols] = obj.getBankSize();
            if ~isnumeric(removeRow) || removeRow < 0 || removeRow > nRows
                error('Row must be a number between 0 and the number of rows');
            end
            for row = removeRow+1:nRows
                % Shift filter controls
                obj.variableControls(row).deltaRow(-1);
                for col = 1:nCols
                    % Shift axes
                    obj.axesGrid(row, col).Layout.Row = obj.axesGrid(row, col).Layout.Row - 1;
                    obj.axesGrid(row, col).UserData.col = col;
                    obj.axesGrid(row, col).UserData.row = row-1;
                end
            end
            % Call delete on row of axes
            for col = 1:nCols
                delete(obj.axesGrid(removeRow, col));
            end
            % Delete and remove defunct axes and filter controls from container arrays.
            delete(obj.variableControls(removeRow));
            obj.variableControls(removeRow) = [];
            obj.axesGrid(removeRow, :) = [];
            obj.setLayoutSize(nRows-1, nCols);
            notify(obj, 'BankSizeChanged');
        end
        function                      removeCol(obj, removeCol)
            [nRows, nCols] = obj.getBankSize();
            if ~isnumeric(removeCol) || removeCol < 0 || removeCol > nCols
                error(['Col must be a number between 0 and the number of cols. Instead it was:', num2str(removeCol)]);
            end
            for col = removeCol+1:nCols
                % Shift filter controls
                obj.filterControls(col).deltaColumn(-1);
                for row = 1:nRows
                    % Shift axes
                    obj.axesGrid(row, col).Layout.Column = obj.axesGrid(row, col).Layout.Column - 1;
                    obj.axesGrid(row, col).UserData.col = col-1;
                    obj.axesGrid(row, col).UserData.row = row;
                end
            end
            % Call delete on col of axes
            for row = 1:nRows
                delete(obj.axesGrid(row, removeCol));
            end
            % Delete and remove defunct axes and filter controls from container arrays.
            delete(obj.filterControls(removeCol));
            obj.filterControls(removeCol) = [];
            obj.axesGrid(:, removeCol) = [];
            obj.setLayoutSize(nRows, nCols-1);
            notify(obj, 'BankSizeChanged');
        end
        function                      deleteControls(obj)
            [nVariables, nFilters] = obj.getBankSize();
            while nVariables > 0
                obj.removeRow(1);
                [nVariables, ~] = obj.getBankSize();
            end
            while nFilters > 0
                obj.removeCol(1);
                [~, nFilters] = obj.getBankSize();
            end
        end
        function                      initializeControls(obj, nRows, nCols)
            for row = 1:nRows
                obj.addRow();
            end
            for col = 1:nCols
                obj.addCol();
            end
            notify(obj, 'BankSizeChanged');
        end
        function                      filterControlChangedCallback(obj, filterControl, event)
            eventData = ControlEventData(filterControl);
            notify(obj, 'FilterChanged', eventData);
        end
        function                      variableControlChangedCallback(obj, variableControl, event)
            eventData = ControlEventData(variableControl);
            notify(obj, 'VariableChanged', eventData);
        end
        function                      addBeforeHandler(obj, src, event)
            switch class(src)
                case 'FilterControl'
                    obj.addCol(src.Column);
                case 'VariableControl'
                    obj.addRow(src.Row);
            end
        end
        function                      addAfterHandler(obj, src, event)
            switch class(src)
                case 'FilterControl'
                    obj.addCol(src.Column+1);
                case 'VariableControl'
                    obj.addRow(src.Row+1);
            end
        end
        function                      removeHandler(obj, src, event)
            switch class(src)
                case 'FilterControl'
                    obj.removeCol(src.Column);
                case 'VariableControl'
                    obj.removeRow(src.Row);
            end
        end
        function                      destroyFilterControls(obj)
            for col = 1:length(obj.filterControls)
                delete(obj.filterControls(col));
            end
            obj.filterControls = FilterControl.empty();
        end
        function                      destroyVariableControls(obj)
            for row = 1:length(obj.variableControls)
                delete(obj.variableControls(row));
            end
            obj.variableControls = VariableControl.empty();
        end
        function                      destroyAxesGrid(obj)
            [nRows, nCols] = obj.getBankSize();
            for col = 1:nCols
                for row = 1:nRows
                    delete(obj.axesGrid(row, col));
                end
            end
            obj.axesGrid = matlab.ui.control.UIAxes.empty();
        end
    end
    events
        BankSizeChanged
        FilterChanged
        VariableChanged
        AddAfter
        AddBefore
        Remove
        ExportAll
        PrePlotCommandsChanged
    end
end