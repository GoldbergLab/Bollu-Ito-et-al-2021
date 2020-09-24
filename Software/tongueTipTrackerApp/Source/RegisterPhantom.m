function [HRESULT] = RegisterPhantom(ignore_cameras)
%Register to phantom dlls
%Use this function once when you start working with phantom dlls
%ignore_cameras - if true the registration ignores the connected cameras.
%Set the option to true when you work only with files.

pDllOption = libpointer('voidPtr',int32(ignore_cameras));
PhSetDllsOption( PhConConst.DO_IGNORECAMERAS, pDllOption);
userDir = [];
%If LogAndStgFolder == [] then the Log&STG folder is the default generated in DLL's
%default log folder is \Application Data\Phantom\DLLVersion
HRESULT = PhLVRegisterClientEx(userDir, uint32(PhConConst.PHCONHEADERVERSION));
if (HRESULT<0)%if any error ocuured
	[message] = PhGetErrorMessage( HRESULT );
    error(['Register error: ' message]);
end

end

