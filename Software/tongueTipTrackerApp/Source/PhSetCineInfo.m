function [ HRES ] = PhSetCineInfo( CH, InfName, pInfVal )

[HRES, dummyAll] = calllib('phfile','PhSetCineInfo', CH, uint32(InfName), pInfVal);
OutputError(HRES);

end

