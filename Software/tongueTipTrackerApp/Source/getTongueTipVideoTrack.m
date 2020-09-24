function tip_track = getTongueTipVideoTrack(varargin)

defaultParams = setTrackParams();

p = inputParser;
addRequired(p, 'topFilePath');
addRequired(p, 'botFilePath');
addOptional(p, 'queue', []);
addParameter(p, 'params', defaultParams, @isstruct)
addParameter(p, 'verboseFlag', false, @islogical)
parse(p, varargin{:});
topFilePath = p.Results.topFilePath;
botFilePath = p.Results.botFilePath;
params = p.Results.params;
verboseFlag = p.Results.verboseFlag;
queue = p.Results.queue;

% Load the mask stacks for the top and bottom views
top_mask = importdata(topFilePath);
bot_mask = importdata(botFilePath);

N_frames = size(bot_mask,1);
% Loop over each frame and accumulate the tip tracks
tip_track.tip_coords = nan(N_frames, 3);
tip_track.centroid_coords = nan(N_frames, 3);
tip_track.frame_volume = nan(N_frames, 1);
progressReportAmount = floor(N_frames/10);
if ~isempty(queue)
    send(queue, ['    Processing masks: ', topFilePath, ' and ', botFilePath]);
end
for frame_num = 1:N_frames
    [frame_tip_coords, frame_centroid_coords, frame_volume] = getTongueTipFrameTrack(bot_mask(frame_num,:,:), top_mask(frame_num,:,:), params);
    tip_track.tip_coords(frame_num, :) = frame_tip_coords;
    tip_track.centroid_coords(frame_num, :) = frame_centroid_coords;
    tip_track.volumes(frame_num) = frame_volume;

    if verboseFlag
        if mod(frame_num, progressReportAmount) == 0
            if ~isempty(queue)
                send(queue, ['        Completed frame #', num2str(frame_num), '/', num2str(N_frames)])
            end
        end
    end
end

if ~isempty(queue)
    send(queue, ['    Completed processing masks: ', topFilePath, ' and ', botFilePath]);
end
end