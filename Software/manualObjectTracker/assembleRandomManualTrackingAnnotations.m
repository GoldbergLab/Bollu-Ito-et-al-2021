function assembleRandomManualTrackingAnnotations(prerandomizedAnnotationFilepath, baseDirectory, saveFilepath)
% Takes a file containing video names and a corresponding random selection 
%   of frame numbers to annotate, and generates a video file composed of
%   the randomly selected frames, as well as an ROI .mat file composed of
%   the corresponding ROI annotations

% prerandomizedAnnotationFilepath:  File containing randomized video and frame
%                                       number selections
% baseDirectory:                    Base directory in which to recursively search for videos
% saveFilepath:                     File path to use to save collected randomized
%                                       frames and ROI annotations. An
%                                       extension is not required.
%
% Written by Brian Kardon bmk27@cornell.edu 2018

[saveFiledir, ~, ~] = fileparts(saveFilepath);
if ~exist(saveFiledir, 'dir')
    disp(['Creating save file directory: ', saveFiledir])
    mkdir(saveFiledir);
end

% Load file containing list of video filepaths that were annotated
s = load(prerandomizedAnnotationFilepath);
manualTrackingList = s.manualTrackingList;

% Retrieve information about the video files
numVideos = length(manualTrackingList);
numFrames = sum(cellfun(@length, {manualTrackingList.frameNumbers}));
videoDataSize = loadVideoDataSize(fullfile(manualTrackingList(1).videoPath, manualTrackingList(1).videoFilename));
numROIs = 2;

% Initialize output data struct
outputStruct.videoFile = 'Assembled from various videos. See originalVideoPaths field for the video that corresponds to each frame';
outputStruct.videoSize = [videoDataSize(1:2), numFrames];
outputStruct.ROIData = [];
outputStruct.manualObjectTrackerVersion = 'Assembled from various ROI files.';
outputStruct.originalFrameNumbers = [];
outputStruct.originalVideoPaths = {};

% Preallocate video data
selectedVideoData = zeros([videoDataSize(1:2), numFrames], 'uint8');
frameNumberCount = 0;

% Loop over each video
for k = 1:numVideos
    disp(['Gathering info from video ', num2str(k), ' of ', num2str(numVideos)]);
    frameNumbers = manualTrackingList(k).frameNumbers;
    videoFilename = manualTrackingList(k).videoFilename;
    videoFilepath = fullfile(manualTrackingList(k).videoPath, manualTrackingList(k).videoFilename);

    % Load video from current video filename
    videoData = loadVideoData(videoFilepath);

    % Extract selected frames from video and add them to the video data
    selectedVideoData(:, :, frameNumberCount+1:frameNumberCount+length(frameNumbers)) = videoData(:, :, frameNumbers);

    % Locate ROI file to load for this video
    ROIRegexp = translateVideoNameToROIRegexp(videoFilename);
    ROIFiles = findFilesByRegex(baseDirectory, ROIRegexp);
    if isempty(ROIFiles)
        disp(['Warning, no ROI file found for video', videoFilename])
        ROIFile = [];
        usersCurrent = {};
    else
        if length(ROIFiles) > 1
            disp(['Warning, multiple ROI files matched video', videoFilename])
        end
        ROIFile = ROIFiles{1};
        % Load current ROI data
        a = load(ROIFile);
        outputStructCurrent = a.outputStruct;
        usersCurrent = fields(outputStructCurrent.ROIData);
    end

    % Check what users are present in the current ROI data, and if they
    %   aren't present in the combined data, preallocate blank data for them
    for j = 1:length(usersCurrent)
        userCurrent = usersCurrent{j};
        if ~isfield(outputStruct.ROIData, userCurrent)
            outputStruct.ROIData.(userCurrent) = createNewUserROIData(numFrames, numROIs);
        end
    end

    % Update the originalFrameNumbers and originalVideoPaths fields with
    %   the new data
    outputStruct.originalFrameNumbers = [outputStruct.originalFrameNumbers, frameNumbers];
    outputStruct.originalVideoPaths = [outputStruct.originalVideoPaths, repmat(videoFilename, [1, length(frameNumbers)])];

    % Extract the ROI annotations for the selected frames from the ROI file
    for j = 1:numel(usersCurrent)
        user = usersCurrent{j};
        outputStruct.ROIData.(user).xPoints(:,frameNumberCount+1:frameNumberCount+length(frameNumbers)) = outputStructCurrent.ROIData.(user).xPoints(:, frameNumbers);
        outputStruct.ROIData.(user).yPoints(:,frameNumberCount+1:frameNumberCount+length(frameNumbers)) = outputStructCurrent.ROIData.(user).yPoints(:, frameNumbers);
        outputStruct.ROIData.(user).xFreehands(:,frameNumberCount+1:frameNumberCount+length(frameNumbers)) = outputStructCurrent.ROIData.(user).xFreehands(:, frameNumbers);
        outputStruct.ROIData.(user).yFreehands(:,frameNumberCount+1:frameNumberCount+length(frameNumbers)) = outputStructCurrent.ROIData.(user).yFreehands(:, frameNumbers);
        outputStruct.ROIData.(user).absent(:,frameNumberCount+1:frameNumberCount+length(frameNumbers)) = outputStructCurrent.ROIData.(user).absent(:, frameNumbers);
    end
    frameNumberCount = frameNumberCount + length(frameNumbers);
end

% Strip extension from saveFilename
[savePath, saveName, ~] = fileparts(saveFilepath);
saveFilepath = fullfile(savePath, saveName);

% Save selected video
saveVideoData(selectedVideoData, [saveFilepath, '.avi']);
% Save selected ROI annotations
save([saveFilepath, '.mat'], 'outputStruct');

function ROIregexp = translateVideoNameToROIRegexp(videoFilename)
[~, vname, ~] = fileparts(videoFilename);
% Strip cue and laser info just in case
%vname = regexprep(vname, '(_C[0-9]+L?)', '');
ROIregexp = [regexptranslate('escape', vname), '.*\.mat'];

function userROIData = createNewUserROIData(numFrames, numROIs)
% Create blank data structures to hold user ROI data
[userROIData.xPoints, userROIData.yPoints] = createBlankROIs(numFrames, numROIs);
[userROIData.xFreehands, userROIData.yFreehands] = createBlankROIs(numFrames, numROIs);
[userROIData.xProj, userROIData.zProj] = createBlankROIs(numFrames, 1);
userROIData.absent = createBlankAbsentData(numFrames, numROIs);

function [x, y] = createBlankROIs(numFrames, numROIs)
% Create blank datastructure for holding a set of ROIs
if numFrames > 0
    x{numROIs, numFrames} = [];
    y{numROIs, numFrames} = [];
else
    x = {};
    y = {};
end

function blankAbsentData = createBlankAbsentData(numFrames, numROIs)
% Create blank datastructure for holding ROI absent data
if numFrames > 0
    blankAbsentData(numROIs, numFrames) = false;
else
    blankAbsentData = [];
end
