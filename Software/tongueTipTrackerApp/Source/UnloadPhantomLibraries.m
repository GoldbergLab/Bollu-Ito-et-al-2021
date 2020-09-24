function UnloadPhantomLibraries()

% unloads phcon
if (libisloaded('phcon'))
    unloadlibrary('phcon');
end
% unloads phint
if (libisloaded('phint'))
    unloadlibrary ('phint');
end
% unloads phfile
if (libisloaded('phfile'))
    unloadlibrary ('phfile');
end

end

