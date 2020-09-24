function [ HRES ] = PhGetCineInfo( CH, InfName, pInfVal)
% pInfVal is a libpointer to the desired information

[HRES, dummyAll] = calllib('phfile','PhGetCineInfo', CH, uint32(InfName), pInfVal);
OutputError(HRES);

end

