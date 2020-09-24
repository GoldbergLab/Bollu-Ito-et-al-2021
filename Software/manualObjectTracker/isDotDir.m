function isDotDir = isDotDir(path)
[~, name, ext] = fileparts(path);
filename = [name, ext];
isDotDir = any(strcmp(filename, {'.', '..'}));
