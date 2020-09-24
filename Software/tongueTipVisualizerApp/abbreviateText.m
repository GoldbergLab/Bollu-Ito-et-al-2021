function abbreviatedText = abbreviateText(text, maxLen, loc)
% text = a char array to abbreviate
% maxLen = the maximum length of the abbreviated char array
% loc (optional) = the position of the ellipsis as fraction of the way
% through abbreviated text. For example, 0 = at the beginning 1 = at the end, 0.5 = in
% the middle (default)

if ~exist('loc', 'var')
    loc = 0.5;
end

if loc < 0
    loc = 0;
end
if loc > 1
    loc = 1;
end

if numel(text) > maxLen
    leftLen = floor((maxLen-3)*loc);
    rightLen = maxLen - (leftLen + 3);
    abbreviatedText = [text(1:leftLen), '...', text(end-rightLen+1:end)];
else
    abbreviatedText = text;
end