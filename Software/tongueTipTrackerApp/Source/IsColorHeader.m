function isColor = IsColorHeader(ih)
if (ih.biBitCount == 8 || ih.biBitCount == 16)
    isColor = false;
else
    isColor = true;
end
end
