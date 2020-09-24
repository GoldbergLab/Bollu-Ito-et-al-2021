function saveVideoData(videoData, filename, varargin)
videoSize = size(videoData);
ndim = ndims(videoData);
frameNum = videoSize(ndim);

if nargin == 3
    videoType = varargin{1};
else
    if ndim == 3
        videoType = 'Grayscale AVI';
    elseif ndim == 4
        videoType = 'Uncompressed AVI';
    end
end

v = VideoWriter(filename, videoType);
open(v);
% for k = 1:videoSize(3)
%     writeVideo(v, videoData(:, :, k));
% end
if isa(videoData, 'double') && max(max(max(max(videoData)))) > 1
    videoData = uint8(videoData);
end
if ndim == 3
    videoSizeAdjusted = [videoSize(1:2), 1, videoSize(3)];
else
    videoSizeAdjusted = videoSize;
end

videoData = reshape(videoData, videoSizeAdjusted);

if ndim == 4
    disp('structifying');
    for k = 1:frameNum
        videoDataStruct(k).cdata = videoData(:, :, :, k);
        videoDataStruct(k).colormap = [];
    end
    videoData = videoDataStruct;
end

writeVideo(v, videoData);
close(v);