function [ HRES, pixels, IH ] = PhGetCineImage( CH, imRng, BufferSize )

pixels = zeros(BufferSize, 1, 'uint8');
pPixel = libpointer('uint8Ptr', pixels);
pImRng = libpointer('tagIMRANGE', libstruct('tagIMRANGE', imRng));
pIH = libpointer('tagIH', get(libstruct('tagIH')));
[HRES, dummyAll] = calllib('phfile', 'PhGetCineImage', CH, pImRng, pPixel, uint32(BufferSize), pIH);
OutputError(HRES);
pixels = pPixel.Value;
IH = pIH.Value;

end