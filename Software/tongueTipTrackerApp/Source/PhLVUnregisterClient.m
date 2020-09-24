function [ HRES ] = PhLVUnregisterClient( )

HRES = calllib ('phcon','PhLVUnregisterClient');
OutputError(HRES);

end

