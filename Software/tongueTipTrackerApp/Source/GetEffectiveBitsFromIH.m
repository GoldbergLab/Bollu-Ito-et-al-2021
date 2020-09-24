function [ effectiveBits ] = GetEffectiveBitsFromIH(ih)

if (ih.biClrImportant == 0)
    if (Is16BitHeader(ih))
        effectiveBits = uint32(16);
    else
        effectiveBits = uint32(8);
    end
else
    effectiveBits = uint32(log2(ih.biClrImportant));
end

end

