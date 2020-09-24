function is16bpp = Is16BitHeader(ih)
if (ih.biBitCount == 16 || ih.biBitCount == 48)
    is16bpp = true;
else
    is16bpp = false;
end
end
