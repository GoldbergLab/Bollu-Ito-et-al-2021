function [tip_coords, centroid_coords, volume] = getTongueTipFrameTrack(bot_mask, top_mask, params)
% current masks
bot_mask = squeeze(bot_mask);
top_mask = squeeze(top_mask);               

% main function
[tip_coords, centroid_coords, volume, top_area, bot_area, ...
    top_centroid, bot_centroid, im_scale, im_shift, coords_b,...
    t_boundary] = tongueTipTracker(top_mask, bot_mask, params);

% store results in struct
%     tip_track_frame.tip_coords = tip_coords;
%     tip_track_frame.centroid_coords = centroid_coords;
%     tip_track_frame.volumes = volume;
%     tip_track_frame.top_area = top_area;
%     tip_track_frame.bot_area = bot_area;
%     tip_track_frame.top_centroid = top_centroid;
%     tip_track_frame.bot_centroid = bot_centroid;
%     tip_track_frame.im_scale = im_scale;
%     tip_track_frame.im_shift = im_shift;
%     tip_track_frame.coords_b = coords_b;
%     tip_track_frame.t_boundary = t_boundary;

end