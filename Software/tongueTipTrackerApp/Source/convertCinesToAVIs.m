function convertCinesToAVIs(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% convertCinesToAVIs: Batch convert Vision Research Phantom ".cine" video files
%   to AVI files, optionally taking advantage of multicore processor
%   architecture.
% usage:  
%   convertCinesToAVIs(files)
%   convertCinesToAVIs(files, parallelize)
%   convertCinesToAVIs(files, parallelize, msgQueue)
%
% where,
%    files is either a cell array of file paths to videos to convert or
%       a struct array of files like that returned by the dir() function
%    parallelize is an optional boolean parameter indicating whether or not
%       to convert videos in parallel to take advantage of multicore 
%       processor architectures. Default is true.
%    msgQueue is an optional DataQueue for sending progress messages to the 
%       calling function
%
% See also: convertCineToAVI

% Version: 1.0
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tic
p = inputParser;
addRequired(p, 'files');
addOptional(p, 'parallelize', true);
addOptional(p, 'queue', []);
parse(p, varargin{:});
files = p.Results.files;
parallelize = p.Results.parallelize;
queue = p.Results.queue;

switch class(files)
    case 'struct'
        % Probably a file list struct like the one that dir() returns
        fileNames = {files.name};
        fileDirs = {files.folder};
        filePaths = {};
        for k = 1:numel(fileNames)
            filePaths{k} = fullfile(fileDirs{k}, fileNames{k});
        end
    case 'cell'
        % Probably already an array of file paths as char arrays
        filePaths = files;
end
% If no queue given, create a dummy queue
if isempty(queue)
    queue = parallel.pool.DataQueue();
    afterEach(queue, @disp);
end

if parallelize
    pool = gcp();

    numWorkers = pool.NumWorkers;
    send(queue, ['Converting cines to avis in parallel using ', num2str(numWorkers), ' workers'])

    videoGroups = dealArray(1:numel(filePaths), numWorkers);
    parfor k = 1:numWorkers
        % If there are N workers and M videos, each worker loops over a
        %   chunk of at most M/N videos.
        LoadPhantomLibraries(); RegisterPhantom(true);
        videoGroup = videoGroups{k};
        for j = 1:numel(videoGroup)
            videoIndex = videoGroup(j);
            send(queue, ['Converting file #', num2str(videoIndex ), ': ', filePaths{videoIndex}])
            convertCineToAVI(filePaths{videoIndex})
        end
        UnregisterPhantom(); UnloadPhantomLibraries();
    end
else
    send(queue, 'Converting cines to avis without parallelization')
    LoadPhantomLibraries(); RegisterPhantom(true);
    for k = 1:numel(filePaths)
        send(queue, ['Converting file #', num2str(k), ': ', filePaths{k}])
        convertCineToAVI(filePaths{k});
    end
    UnregisterPhantom(); UnloadPhantomLibraries();
end
toc

end