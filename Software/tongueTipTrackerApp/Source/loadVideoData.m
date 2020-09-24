function videoData = loadVideoData(videoFilename, varargin)
%This currently works with grayscale avi and tif files

if nargin > 1
    makeGrayscale = varargin{1};
else
    makeGrayscale = true;
end

[~, ~, ext] = fileparts(videoFilename);

verbose = true;

if strcmp(ext, '.tif')
    % Check if file is a .tif file
    if verbose
        disp('Loading as .tif file')
    end
    tiffInfo = imfinfo(videoFilename);
    numFrames = length(tiffInfo);
    width = tiffInfo(1).Width;
    height = tiffInfo(1).Height;
    videoData = zeros([height, width, numFrames]);
    for k = 1:numFrames
        videoData(:, :, k) = imread(videoFilename, k);
    end
else
    try
        if verbose
            disp('Loading using read method with VideoReader')
        end
        video = VideoReader(videoFilename);
        videoData = read(video);
    catch
        try
            if verbose
                disp('Loading using read method with VideoReader and native option')
            end
            video = VideoReader(videoFilename);
            videoDataStruct = read(video, [1, video.NumberOfFrames], 'native');
            videoData = zeros([size(videoDataStruct(1).cdata), length(videoDataStruct)]);
            for k = 1:length(videoDataStruct)
                videoData(:, :, k) = videoDataStruct(k).cdata;
            end
        catch
            try
                if verbose
                    disp('Loading using read method with VideoReader and native option with Inf as end frame')
                end
                video = VideoReader(videoFilename);
                %    disp('Attempting to load video with method #1');
                videoDataStruct = read(video, [1, Inf], 'native');
                videoData = zeros([size(videoDataStruct(1).cdata), length(videoDataStruct)]);
                for k = 1:length(videoDataStruct)
                    videoData(:, :, k) = videoDataStruct(k).cdata;
                end
            catch
                if verbose
                    disp('Loading using VideoReader.readFrame and native option')
                end
                video = VideoReader(videoFilename);
                videoData = zeros(video.Height, video.Width, int32(video.Duration * video.FrameRate));
                frameNum = 1;
                while hasFrame(video)
                    videoData(:, :, frameNum) = video.readFrame('native').cdata;
                    frameNum = frameNum + 1;
                end
            end
        end
    end
end

% Get rid of duplicate RGB channels
videoDataSize = size(videoData);
if length(videoDataSize) == 4 && videoDataSize(3) == 1
    % For some reason we have a singleton dimension - let's get rid of it
    videoData = squeeze(videoData);
end
if length(videoDataSize) == 4 && videoDataSize(3) == 3 && makeGrayscale
    % third dimension is probably color channels
    videoData = squeeze(videoData(:, :, 1, :));
end