function filepaths = findFilesByRegex(rootDir, regex, varargin)
% Search rootDir (recursively if desired) and return a list of files that 
%   match the regex
%
% rootDir: char array representing a directory to recursively search
% regex: char array representing a file regex to match
% matchPath (optional): boolean flag, apply regex to path as well as name, 
%   default false
% recurse (optional): boolean flag, apply regex recursively to 
%   subdirectories as well, default true
% includeFolders (optional) boolean flag, include folders in results, 
%   default false.
% includeFiles (optional) boolean flag, include regular files in results, 
%   default true.

if nargin>2
    matchPath = varargin{1};
else
    matchPath = false;
end
if nargin>3
    recurse = varargin{2};
else
    recurse = true;
end
if nargin>4
    includeFolders = varargin{3};
else
    includeFolders = false;
end
if nargin>5
    includeFiles = varargin{4};
else
    includeFiles = true;
end

files = dir(rootDir);
% Exclude dot directores - '.' and '..'
files = files(~cellfun(@isDotDir, {files.name}));

dirs = files([files.isdir]);
if ~includeFolders
    % Exclude directories
    files = files(~[files.isdir]);
end
if ~includeFiles
    % Exclude regular files
    files = files([files.isdir]);
end

filepaths = {};
for k = 1:length(files)
    [path, name, ext] = fileparts(files(k).name);
    if matchPath
        matchName = fullfile(files(k).folder, files(k).name);
    else
        matchName = [name, ext];
    end
    if regexp(matchName, regex)
        filepaths(end+1) = {fullfile(files(k).folder, files(k).name)};
    end
end

if recurse
    for k = 1:length(dirs)
        if ~any(strcmp(dirs(k).name, {'.', '..'}))
            dirpath = fullfile(dirs(k).folder, dirs(k).name);
            filepaths = [filepaths, findFilesByRegex(dirpath, regex, matchPath, recurse, includeFolders, includeFiles)];
        end
    end
end

