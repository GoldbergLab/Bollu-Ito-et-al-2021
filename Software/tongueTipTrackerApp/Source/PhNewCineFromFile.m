function [ HRES, CH ] = PhNewCineFromFile( fileName )

pCH = libpointer('voidPtrPtr');
[HRES, dummyAll] = calllib('phfile','PhNewCineFromFile', fileName, pCH);
OutputError(HRES);
CH = pCH.Value;

end

