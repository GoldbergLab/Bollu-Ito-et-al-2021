function tabbedText = indentText(text, indentLevel)
if ischar(text)
    tabbedText = indentString(text, indentLevel);
else
    tabbedText = cellfun(@(s)indentString(s, indentLevel), text, 'UniformOutput', false);
end

function indentedText = indentString(string, indentLevel) 
indent = repmat(char(9), [1, indentLevel]);
indentedText = [indent, string];
