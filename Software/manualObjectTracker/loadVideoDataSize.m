function videoDataSize = loadVideoDataSize(videoFilename)
%This currently works with grayscale avi and tif files

[~, ~, ext] = fileparts(videoFilename);

if strcmp(ext, '.tif')
    % Check if file is a .tif file
    tiffInfo = imfinfo(videoFilename);
    numFrames = length(tiffInfo);
    width = tiffInfo(1).Width;
    height = tiffInfo(1).Height;
    videoDataSize = [height, width, numFrames];
else
	video = VideoReader(videoFilename);
	videoDataSize = [video.Height, video.Width, video.NumberOfFrames];
end