function videoData = loadVideoClip(videoFilename, startFrame, endFrame)
% Load a portion of a video into memory
%
% Arguments:
% videoFilename:    A char array representing a filename where a video can be
%                       found
% startFrame:       An integer representing the first frame of the video to
%                       include
% endFrame:         An integer representing the last frame of the video to
%                       include
%
% Returns:
% videoData:        A WxHxN array of numbers representing a video with frame
%                       width W, frame height H, and N frames.
%

video = VideoReader(videoFilename);
videoDataStruct = read(video, [startFrame, endFrame], 'native');
videoData = zeros([size(videoDataStruct(1).cdata), length(videoDataStruct)]);
for k = 1:length(videoDataStruct)
    videoData(:, :, k) = videoDataStruct(k).cdata;
end
% Get rid of duplicate RGB channels
videoDataSize = size(videoData);
if length(videoDataSize) == 4 && videoDataSize(3) == 3
    % third dimension is probably color channels
    videoData = squeeze(videoData(:, :, 1, :));
end