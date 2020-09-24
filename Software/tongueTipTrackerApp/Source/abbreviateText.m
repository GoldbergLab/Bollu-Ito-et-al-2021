function abbreviatedText = abbreviateText(text, maxLen)
    if numel(text) > maxLen
        halfWidth = floor((maxLen-3)/2);
        abbreviatedText = [text(1:halfWidth), '...', text(end-halfWidth:end)];
    else
        abbreviatedText = text;
    end