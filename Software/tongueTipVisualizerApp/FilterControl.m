classdef (HandleCompatible) FilterControl < handle
    properties
        filterLayout      matlab.ui.container.GridLayout
        filterText        matlab.ui.control.TextArea
        postFilterMode    matlab.ui.control.DropDown
        postFilterValue   matlab.ui.control.NumericEditField
        NLabel            matlab.ui.control.Label
        totalLabel        matlab.ui.control.Label
        Column            double
        addBeforeButton     matlab.ui.control.Button
        addAfterButton     matlab.ui.control.Button
        removeButton     matlab.ui.control.Button        
    end
    methods  %(Access = public)
        function obj =               FilterControl(parentLayout, column, row, gridColumn, text, postFilterMode, postFilterValue)
            if ~exist('text', 'var')
                text = '';
            end
            if ~exist('postFilterMode', 'var')
                postFilterMode = '1st sequential N';
            end
            if ~exist('postFilterValue', 'var')
                postFilterValue = 5;
            end
            % Create GridLayout
            obj.Column = gridColumn;
            obj.filterLayout = uigridlayout(parentLayout);
%            obj.filterLayout.ColumnWidth = {'5x', '1x', '2x', '1x', '1x'};
            obj.filterLayout.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            obj.filterLayout.RowHeight = {'1x', '1x', '1x', '1x'};
            obj.filterLayout.ColumnSpacing = 1;
            obj.filterLayout.RowSpacing = 1;
            obj.filterLayout.Padding = [1 1 1 1];
            obj.filterLayout.Scrollable = 'on';
            obj.filterLayout.Layout.Row = row;
            obj.filterLayout.Layout.Column = column;

            obj.postFilterMode = uidropdown(obj.filterLayout, ...
                'Items',{'1st sequential N','Rand. sequential N', 'Random N', 'All'},...
                'Value',postFilterMode);
            obj.postFilterMode.Layout.Row = 2;
            obj.postFilterMode.Layout.Column = [1, 5];
            obj.postFilterMode.ValueChangedFcn = @obj.changePostFilterMode;
            
            obj.NLabel = uilabel(obj.filterLayout);
            obj.NLabel.Text = 'N=';
            obj.NLabel.Layout.Row = 2;
            obj.NLabel.Layout.Column = 6;
           
            obj.postFilterValue = uieditfield(obj.filterLayout, ...
              'numeric',...
              'Limits', [1, Inf],...
              'RoundFractionalValues',true,...
              'Value', 5);
            obj.postFilterValue.Layout.Row = 2;
            obj.postFilterValue.Layout.Column = [7, 8];
            obj.postFilterValue.Value = postFilterValue;
            obj.postFilterValue.ValueChangedFcn = @obj.changePostFilterValue;

            obj.totalLabel = uilabel(obj.filterLayout);
            obj.totalLabel.Text = ' / ?';
            obj.totalLabel.Layout.Row = 2;
            obj.totalLabel.Layout.Column = [9, 10];
           
            obj.filterText = uitextarea(obj.filterLayout, 'FontName', 'Lucida Console', 'Value', text);
            obj.filterText.Layout.Row = [3, 4];
            obj.filterText.Layout.Column = [1, 10];
            obj.filterText.ValueChangedFcn = @obj.changeFilterValue;
            
            obj.addBeforeButton = uibutton(obj.filterLayout, 'Text', '< +', 'Tooltip', 'Add filter left');
            obj.addBeforeButton.VerticalAlignment = 'top';
            obj.addBeforeButton.Layout.Row = 1;
            obj.addBeforeButton.Layout.Column = [1, 2];
            obj.addBeforeButton.ButtonPushedFcn = @obj.addBeforeButtonCallback;    

            obj.removeButton = uibutton(obj.filterLayout, 'Text', 'X', 'Tooltip', 'Remove this filter');
            obj.removeButton.VerticalAlignment = 'top';
            obj.removeButton.Layout.Row = 1;
            obj.removeButton.Layout.Column = [5, 6];
            obj.removeButton.ButtonPushedFcn = @obj.removeButtonCallback;    

            obj.addAfterButton = uibutton(obj.filterLayout, 'Text', '+ >', 'Tooltip', 'Add filter right');
            obj.addAfterButton.VerticalAlignment = 'top';
            obj.addAfterButton.Layout.Row = 1;
            obj.addAfterButton.Layout.Column = [9, 10];
            obj.addAfterButton.ButtonPushedFcn = @obj.addAfterButtonCallback;    

        end
        function                     removeButtonVisibility(obj, visible)
            obj.removeButton.Visible = visible;
        end
        function                     setRow(obj, row)
            % Set absolute row in parent layout
            obj.filterLayout.Layout.Row = row;
        end
        function row =               getRow(obj)
            row = obj.filterLayout.Layout.Row;
        end
        function                     setColumn(obj, col, gridCol)
            % Set absolute column in parent layout
            obj.filterLayout.Layout.Column = col;
            obj.setGridColumn(gridCol);
        end
        function col =               getColumn(obj)
            col = obj.filterLayout.Layout.Column;
        end
        function                     setGridColumn(obj, gridCol)
            obj.Column = gridCol;
        end
        function gridCol =           getGridColumn(obj)
            gridCol = obj.Column;
        end
        function                     deltaRow(obj, deltaRow)
            obj.setRow(obj.getRow() + deltaRow);
        end
        function                     deltaColumn(obj, deltaCol)
            obj.setColumn(obj.getColumn() + deltaCol, obj.getGridColumn() + deltaCol);
        end
        function postFilteredTable = postFilterTable(obj, dataTable, varargin)
            if ~isempty(varargin) && ~isnan(varargin{1})
                seed = varargin{1};
                rng(seed);
            end
            val = obj.getPostFilterValue;
            tableHeight = height(dataTable);
            switch obj.postFilterMode.Value
                case '1st sequential N'
                    % Select the first N sequential table rows
                    val = min([val, tableHeight]);
                    postFilteredTable = dataTable(1:val, :);
                case 'Rand. sequential N'
                    % Select N sequential table rows starting at a random row
                    val = min([val, max([tableHeight-val-1, 0])]);
                    start = randi(tableHeight-val);
                    postFilteredTable = dataTable(start:start+val, :);
                case 'Random N'
                    % Select N random table rows
                    val = min([val, tableHeight]);
                    idx = randsample(tableHeight, val);
                    postFilteredTable = dataTable(idx, :);
                case 'All'
                    % Select all table rows
                    postFilteredTable = dataTable;
            end
        end
        function filterText =        getFilterText(obj)
            % Get filter text as is
            filterText = obj.filterText.Value;
        end
        function filterString =      getFilterString(obj)
            % Get filter text with newlines and whitespace cleaned up
            filterString = strtrim(strjoin(obj.getFilterText(), ' '));
        end
        function                     setFilterString(obj, filterString)
            obj.filterText.Value = filterString;
        end
        function filterCommand =     getFilterCommand(obj, dataTable)
            tableName = inputname(2);
            filterTexts = obj.getFilterText();
            filterString = obj.getFilterString();
            if isempty(filterString)
                % If no filters, select all rows
                filterTexts = {':'};
            end
            filterCommand = '{';
            for k = 1:length(filterTexts)
                filterText = filterTexts{k};
                if isempty(strtrim(filterText))
                    continue;
                end
                filterCommand = [filterCommand, tableName, '(', filterText, ', :), '];
            end
            filterCommand = [filterCommand, '}'];
        end
        function filteredTables =    filterTable(obj, dataTable, varargin)
            % Return a cell array of filtered tables, one table per filter
            % provided.
            if ~isempty(varargin)
                % Add other custom variables to temporary workspace
                otherFilterVars = varargin{1};
                otherFilterVarNames = fieldnames(otherFilterVars);
                for k = 1:length(otherFilterVarNames)
                    otherFieldName = otherFilterVarNames{k};
                    assignin('caller', otherFieldName, otherFilterVars.(otherFieldName));
                end
                if length(varargin) >= 2
                    seed = varargin{2};
                else
                    seed = NaN;
                end
            end
            assignin('caller', 'dataTable', dataTable);
            % Select certain data table field names for filtering.
            filterString = obj.getFilterString();
            fieldNames = dataTable.Properties.VariableNames;
            fieldNamesSelected = fieldNames(cellfun(@(pattern)contains(filterString, pattern), fieldNames));
            % Assign each filtered field to variables
            forbiddenFieldNames = {'dataTable'};
            for j = 1:length(fieldNamesSelected)
                fieldName = fieldNamesSelected{j};
                % Make sure we don't overwrite necessary variables
                if ~any(strcmp(fieldName, forbiddenFieldNames))
                    fieldData = dataTable.(fieldName);
                    assignin('caller', fieldName, fieldData);
                else
                    error(['Using field name ', fieldName, ' it is forbidden for namespace collision reasons.'])
                end
            end
            % Create random selection function
            % Filter all the field data field to variables
%            disp(['Filtering data with filter: ', filterString])
            filteredTables = evalin('caller', obj.getFilterCommand(dataTable));
            totals = cellfun(@height, filteredTables);
            maxTotal = max(totals);
            obj.totalLabel.Text = [' / ', num2str(maxTotal)];
            if length(filteredTables) > 1
                obj.totalLabel.Tooltip = ['Multiple filtered lengths: ', join(arrayfun(@num2str, totals, 'UniformOutput', false), ', ')];
            else
                obj.totalLabel.Tooltip = '';
            end
            for k = 1:length(filteredTables)
                filteredTables{k} = obj.postFilterTable(filteredTables{k}, seed);
            end
        end
        function postFilterValue =   getPostFilterValue(obj)
            postFilterValue = obj.postFilterValue.Value;
        end
        function                     changePostFilterValue(obj, thrower, event)
            notify(obj,'FilterChanged');
        end
        function                     changePostFilterMode(obj, thrower, event)
            if strcmp(obj.postFilterMode.Value, 'All')
                obj.postFilterValue.Enable = 'off';
            else
                obj.postFilterValue.Enable = 'on';
            end
            notify(obj,'FilterChanged');
        end
        function                     changeFilterValue(obj, thrower, event)
            notify(obj,'FilterChanged');
        end
        function                     addBeforeButtonCallback(obj, thrower, event)
            notify(obj, 'AddBefore');
        end
        function                     addAfterButtonCallback(obj, thrower, event)
            notify(obj, 'AddAfter');
        end
        function                     removeButtonCallback(obj, thrower, event)
            notify(obj, 'Remove');
        end
        function                     delete(obj)
            delete(obj.filterText);
            delete(obj.postFilterMode);
            delete(obj.postFilterValue);
            delete(obj.NLabel);
            delete(obj.totalLabel);
            delete(obj.addBeforeButton);
            delete(obj.addAfterButton);
            delete(obj.removeButton);
            delete(obj.filterLayout);
        end
    end
    events
        FilterChanged
        AddBefore
        AddAfter
        Remove
    end
end