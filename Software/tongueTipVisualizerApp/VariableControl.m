classdef (HandleCompatible) VariableControl < handle
    properties
        variableLayout      matlab.ui.container.GridLayout
        variableText        matlab.ui.control.TextArea
        Row                 double
        addBeforeButton     matlab.ui.control.Button
        addAfterButton      matlab.ui.control.Button
        removeButton        matlab.ui.control.Button
    end
    methods  %(Access = public)
        function obj =            VariableControl(parentLayout, column, row, text)
            if ~exist('text', 'var')
                text = '';
            end
            % Create GridLayout
            obj.variableLayout = uigridlayout(parentLayout);

            obj.variableLayout.ColumnWidth = {'1x', '7x'};
            obj.variableLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x'};

            obj.variableLayout.ColumnSpacing = 1;
            obj.variableLayout.RowSpacing = 1;
            obj.variableLayout.Padding = [1 1 1 1];
            obj.variableLayout.Scrollable = 'on';
            obj.variableLayout.Layout.Row = row;
            obj.variableLayout.Layout.Column = column;
           
            obj.variableText = uitextarea(obj.variableLayout, 'FontName', 'Lucida Console', 'Value', text);
            obj.variableText.Layout.Row = [1, 5];
            obj.variableText.Layout.Column = 2;
            obj.variableText.ValueChangedFcn = @obj.changeVariablesValue;
            
            obj.addBeforeButton = uibutton(obj.variableLayout, 'Text', ['/\', newline, '+'], 'Tooltip', 'Add variable control above');
            obj.addBeforeButton.VerticalAlignment = 'top';
            obj.addBeforeButton.Layout.Row = 1;
            obj.addBeforeButton.Layout.Column = 1;
            obj.addBeforeButton.ButtonPushedFcn = @obj.addBeforeButtonCallback;    

            obj.removeButton = uibutton(obj.variableLayout, 'Text', 'X', 'Tooltip', 'Remove this variable control');
            obj.removeButton.VerticalAlignment = 'top';
            obj.removeButton.Layout.Row = 3;
            obj.removeButton.Layout.Column = 1;
            obj.removeButton.ButtonPushedFcn = @obj.removeButtonCallback;    

            obj.addAfterButton = uibutton(obj.variableLayout, 'Text', ['+', newline, '\/'], 'Tooltip', 'Add variable control below');
            obj.addAfterButton.VerticalAlignment = 'top';
            obj.addAfterButton.Layout.Row = 5;
            obj.addAfterButton.Layout.Column = 1;
            obj.addAfterButton.ButtonPushedFcn = @obj.addAfterButtonCallback;    

        end
        function                  removeButtonVisibility(obj, visible)
            obj.removeButton.Visible = visible;
        end
        function                  setRow(obj, row, gridRow)
            % Set absolute row in parent layout
            obj.variableLayout.Layout.Row = row;
            obj.setGridRow(gridRow);
        end
        function row =            getRow(obj)
            row = obj.variableLayout.Layout.Row;
        end
        function                  setColumn(obj, col)
            % Set absolute column in parent layout
            obj.variableLayout.Layout.Column = col;
        end
        function col =            getColumn(obj)
            col = obj.variableLayout.Layout.Column;
        end
        function gridRow =        getGridRow(obj)
            gridRow = obj.Row;
        end
        function                  setGridRow(obj, gridRow)
            obj.Row = gridRow;
        end
        function                  deltaRow(obj, deltaRow)
            obj.setRow(obj.getRow() + deltaRow, obj.getGridRow() + deltaRow);
        end
        function                  deltaColumn(obj, deltaCol)
            obj.setColumn(obj.getColumn() + deltaCol);
        end
        function variableText = getVariableText(obj)
            variableText = obj.variableText.Value;
        end
        function variableString = getVariableString(obj)
            variableString = strtrim(strjoin(obj.getVariableText(), ' '));
        end
        function                  setVariableString(obj, variableString)
            obj.variableText.Value = variableString;
        end
        function                  changeVariablesValue(obj, thrower, event)
            notify(obj,'VariablesChanged');
        end
        function                  addBeforeButtonCallback(obj, thrower, event)
            notify(obj, 'AddBefore');
        end
        function                  addAfterButtonCallback(obj, thrower, event)
            notify(obj, 'AddAfter');
        end
        function                  removeButtonCallback(obj, thrower, event)
            notify(obj, 'Remove');
        end
        function                  delete(obj)
            delete(obj.variableText);
            delete(obj.addBeforeButton);
            delete(obj.addAfterButton);
            delete(obj.removeButton);
            delete(obj.variableLayout);
        end
    end
    events
        VariablesChanged
        AddBefore
        AddAfter
        Remove
    end
end