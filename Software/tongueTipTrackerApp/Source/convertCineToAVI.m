function vid = convertCineToAVI(cineFilePath, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% convertCineToAVI: Convert a Vision Research Phantom .cine file to an .avi
%   file
% usage:  [<output args>] = <function name>(<input args>)
%
% where,
%    <arg1> is <description>
%    <arg2> is <description>
%    <argN> is <description>
%
% <long description>
%
% See also: <related functions>
% Version: <version>
% Author:  Brian Kardon
% Email:   bmk27=cornell*org, brian*kardon=google*com
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin > 1
    aviFilePath = varargin{2};
else
    [cineDir, cineName, ~] = fileparts(cineFilePath);
    aviFilePath = fullfile(cineDir, [cineName, '.avi']);
end

videoData = loadCineVideoData(cineFilePath);
% Convert videoData to uint8
switch class(videoData)
    case 'uint16'
        videoData = uint8(videoData/256);
    case 'double'
        maxPixel = max(videoData(:));
        if 0 <= maxPixel && maxPixel <= 1
            videoData = uint8(videoData * 256);
        end
end

saveVideoData(videoData, aviFilePath)