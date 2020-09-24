function manualTrackingList = generateRandomManualTrackingList(videoBaseDirectories, videoRegex, extensions, numAnnotations, saveFilepath, varargin)
% Recursively searches videoBaseDirectory for videos that match the
%   identifyingVideoStrings and extensions, and generates a file containing
%   video names and a corresponding random selection of frame numbers to annotate.
% Arguments:
% videoBaseDirectories:     A base directory in which to recursively search
%                           for videos, or a cell array of base directories to search.
% videoRegex:               A char array representing a regular expression to use to select video files
%                               OR 
%                           number indicating how many random videos to select from the directory 
%                               OR
%                           0 to use all the videos found
% extensions:               A char array containing a file extension (ex:
%                               '.avi') or a cell array of char arrays
%                               containing file extensions.
% numAnnotations:           total number of random frame numbers to pick from the pool of videos
% saveFilepath:             file path in which to save annotation data
% clipDirectory (optional): A directory to save video clips around each frame
% clipRadius (optional):    The # of frames on either side of selected
%                           frame to include in the clip. Default = 10
% recursiveSearch (optional):  Should video directory be searched recursively (including subfolders)? Default false.
%
% Returns:
% manualTrackingList:       The list of video filenames and frame numbers
%                               that is both returned and saved to file
if length(varargin) >= 1
    clipDirectory = varargin{1};
    if length(varargin) >= 2
        clipRadius = varargin{2};
    else
        clipRadius = 10;
    end
else
    clipDirectory = '';
    clipRadius = 0;
end
if length(varargin) >= 3
    recursiveSearch = varargin{3};
else
    recursiveSearch = false;
end
disp('recursiveSearch:')
disp(recursiveSearch)
if ~iscell(videoBaseDirectories)
    videoBaseDirectories = {videoBaseDirectories};
end    

% Find files that match extension and regex
disp('Finding matching files with correct extension...');
vfps = cellfun(@(videoBaseDirectory)findFilesByExtension(videoBaseDirectory, extensions, recursiveSearch), videoBaseDirectories, 'UniformOutput', false);
videoFilepaths = sort([vfps{:}]);
if isempty(videoFilepaths)
    disp(strjoin([{'Warning, no files found for video identifier'}, extensions], ' '))
end
if ischar(videoRegex)
    % Find files that match one or more of the identifyingVideoStrings
    videoFilepaths = videoFilepaths(~cellfun(@isempty, regexp(videoFilepaths, videoRegex)));
elseif isnumeric(videoRegex)
    % Number rather than cell array is passed as identifyingVideoStrings
    if videoRegex > 0
        % If number is not 0, randomly sample that # of videos
        videoFilepaths = sort(datasample(videoFilepaths, videoRegex, 'Replace',false));
    end
else
    warndlg('Warning, invalid videoRegex provided. Exiting.');
    return
end
disp(['...done. Found ', num2str(length(videoFilepaths)), ' files.']);

% Determine the length of (# of frames in) each video
disp('Determining video lengths...');
videoLengths = zeros(1, length(videoFilepaths));
numClips = length(videoFilepaths);

invalidIndices = [];
for k = 1:numClips
    disp(['Determining length of video #', num2str(k), ' of ', num2str(numClips)])
    videoFilepath = videoFilepaths{k};
    try
        videoSize = loadVideoDataSize(videoFilepath);
        if videoSize(3) <= 2*clipRadius
            invalidIndices(end+1) = k;
        end
    catch ME
        invalidIndices(end+1) = k;
    end
    videoLengths(k) = videoSize(3); % - 2*clipRadius;
end

if ~isempty(invalidIndices)
    disp(['Warning: Could not find any readable data for the following ', num2str(length(invalidIndices)), ' videos:']);
    disp(videoFilepaths(invalidIndices)');
    videoLengths(invalidIndices) = [];
    videoFilepaths(invalidIndices) = [];
end

if numClips == 0
    error('Error - no valid videos found with those parameters. Check the root directory, try changing the file regex, and make sure the extension is valid - it should include a ''.''.')
end

% Assemble a list of all possible frames from all videos
disp('Assembling potential frame list...');
% Format: [[videoIndex_k, frameNumber_j], ...]
% So, allFrameList(1,:) = all the video indices'
% and allFrameList(2,:) = all the frame numbers
allFrameList = [];
for k = 1:numClips
    nextFrameList = [];
    nextFrameList(1, 1:videoLengths(k)-2*clipRadius) = k;
    nextFrameList(2, :) = (1+clipRadius):(videoLengths(k)-clipRadius);
    allFrameList = [allFrameList, nextFrameList];
end

% Select random frames from all frame list
disp('Selecting random frames...');
sampledFrameList = datasample(allFrameList, numAnnotations, 2, 'Replace', false);

if ~isempty(clipDirectory)
    % If we're doing clips, there will be one video per frame
    numClips = size(sampledFrameList, 2);
end

% Preallocate manualTrackingList
manualTrackingList(numClips).videoFilename = '';
manualTrackingList(numClips).videoPath = '';
manualTrackingList(numClips).frameNumbers = [];

disp('Extracting data...');
for k = 1:numClips
    disp(['Completed frame ', num2str(k), ' of ', num2str(length(sampledFrameList))]);
    videoIndex = sampledFrameList(1, k);
    frameNumber = sampledFrameList(2, k);
    videoFilepath = videoFilepaths{videoIndex};
    [videoPath, videoName, videoExtension] = fileparts(videoFilepath);
    videoFilename = [videoName, videoExtension];

    if ~isempty(clipDirectory)
        % We're creating and using clips instead of existing whole videos
        % Construct alternate name/path for clip to be saved
        videoPath = clipDirectory;
        videoFilename = [videoName, '_clipF', num2str(frameNumber), 'R', num2str(clipRadius), videoExtension];
        videoPathname = fullfile(videoPath, videoFilename);
        % Load video clip data
        videoClipData = loadVideoClip(videoFilepath, frameNumber - clipRadius, frameNumber + clipRadius);
        disp(['Saving clip as ', videoPathname]);
        % Save clip to disk
        saveVideoData(uint8(videoClipData), videoPathname);
        frameNumber = clipRadius + 1;
        videoIndex = k;
    end
    
    % Record selected frame data in struct
    manualTrackingList(videoIndex).videoFilename = videoFilename;
    manualTrackingList(videoIndex).videoPath = videoPath;
    manualTrackingList(videoIndex).frameNumbers(end+1) = frameNumber;
end

if ~isempty(saveFilepath)
    save(saveFilepath, 'manualTrackingList');
end