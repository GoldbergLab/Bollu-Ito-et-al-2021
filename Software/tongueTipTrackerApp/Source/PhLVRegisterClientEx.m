function [ HRES ] = PhLVRegisterClientEx(path, phConHeaderVer )

pnull = libpointer;
if (isempty(path))
    path = pnull;
end
[HRES , dummy1, dummy2] = calllib ('phcon', 'PhLVRegisterClientEx', path, pnull, phConHeaderVer);
OutputError(HRES);

end

