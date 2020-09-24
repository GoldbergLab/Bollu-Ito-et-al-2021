function filepaths = findFilesByExtension(rootDir, extensions)
% Recursively search rootDir and return a list of file with one of the
%   given extensions
%
% rootDir: char array representing a directory to recursively search
% extensions: cell array of char arrays representing file extensions to
%   look for
%
% DEPRECATED - use findFilesByRegex instead.

items = dir(rootDir);
dirs = items([items.isdir]);
files = items(~[items.isdir]);

filepaths = {};
for k = 1:length(files)
    [~, ~, ext] = fileparts(files(k).name);
    if any(strcmp(ext, extensions))
        filepaths(end+1) = {fullfile(files(k).folder, files(k).name)};
    end
end

for k = 1:length(dirs)
    if ~any(strcmp(dirs(k).name, {'.', '..'}))
        dirpath = fullfile(dirs(k).folder, dirs(k).name);
        filepaths = [filepaths, findFilesByExtension(dirpath, extensions)];
    end
end