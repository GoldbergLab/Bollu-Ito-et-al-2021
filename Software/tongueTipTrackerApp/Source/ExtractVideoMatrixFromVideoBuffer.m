function [ vid ] = ExtractVideoMatrixFromVideoBuffer( pixels, IH, nFrames, bps )

%extract image from image buffer pPixels
vidSizeInBytes = (IH.biBitCount/8)*IH.biWidth*IH.biHeight*nFrames;
pixels = pixels(1:vidSizeInBytes);
imWidthInBytes = (IH.biBitCount/8)*IH.biWidth;
if (Is16BitHeader(IH))
    pixels = typecast(pixels, 'uint16');
    imDataWidth = imWidthInBytes/2;
else
    imDataWidth = imWidthInBytes;
end
%reshape as a matrix
%frameSize = IH.biHeight*imDataWidth;
vid = reshape(pixels, imDataWidth, IH.biHeight, nFrames);
% Transpose images
vid = permute(vid, [2, 1, 3]);
% Flip up/down
vid = flip(vid, 1);
if (bps>8 && bps<16)
    vid = bitshift(vid,16-bps);
end

end

