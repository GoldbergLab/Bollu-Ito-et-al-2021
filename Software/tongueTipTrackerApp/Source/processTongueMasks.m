%--------------------------------------------------------------------------
% function to take masks of the tongue output by NN and process them for
% reconstruction. This includes:
%   -removing any noise
%   -attempting to connect masks if broken
%   -translating/scaling top image so tongue tip matches in both images
%   -calculating region properties of masks
%--------------------------------------------------------------------------

function [bot_frame, top_frame, bot_s, top_s, im_shift, im_scale] = ...
    processTongueMasks(bot_frame, top_frame, params, top_dim, centroid_avoid)
%--------------------------------------------------------------------------
%% load params
N_pix_min = params.N_pix_min ; % if masks have fewer pixels than this, ignore

im_shift = params.im_shift ; % amount to translate top image by. based on spout comparison
im_scale_user = params.im_scale_user ; % scale top image. code tries to estimate this

se_radius_start = params.disk_se_radius ; % radius for S.E. used to connect mask 
solidity_thresh = params.solidity_thresh ; % minimum solidity for doing convHull

top_height = top_dim(1) ; 
top_width = top_dim(2) ; 
%--------------------------------------------------------------------------
%% pre-process images

% remove any small specs from images
bot_frame = bwareaopen(bot_frame,N_pix_min) ;
top_frame = bwareaopen(top_frame,N_pix_min) ;

%---------------------------------------------
% need to deal with differences between size and shift of images
bot_s = regionprops(bot_frame,'BoundingBox','Centroid','Area') ;
top_s = regionprops(top_frame,'BoundingBox','Centroid','Area',...
    'ConvexImage','Solidity') ;

% if there is more than one connected component in image...

% remove the component due to IR light
% centroid_avoid = [138;84];
if length(top_s) > 1 && numel(centroid_avoid)
    centroid_list = [top_s.Centroid];
    centroid_list = reshape(centroid_list,2,numel(centroid_list)/2);
    
    centroid_list(1,:) = centroid_list(1,:) - centroid_avoid(1);
    centroid_list(2,:) = centroid_list(2,:) - centroid_avoid(2);
    
    sum_cent_dist = sum(centroid_list.^2,1);
    index_cent = sum_cent_dist<100;
    
    ind_list = find(~index_cent);
    if ind_list
        CC = bwconncomp(top_frame);
        L = labelmatrix(CC);
        top_frame = ismember(L,ind_list);
    end
    %top_s = top_s(~index_cent);
    top_s = regionprops(top_frame,'BoundingBox','Centroid','Area',...
    'ConvexImage','Solidity') ;
end

se_radius = se_radius_start ;
while (length(top_s) > 1) && (se_radius < 10)
    se = strel('disk',se_radius) ;
    top_frame = imclose(top_frame,se) ;
    top_s = regionprops(top_frame,'BoundingBox','Centroid','Area',...
        'ConvexImage','Solidity');
    se_radius = se_radius + 1 ;
end
areas = [top_s.Area] ;
[~, max_ind] = max(areas) ;
top_s = top_s(max_ind) ;

se_radius = se_radius_start ;
while (length(bot_s) > 1) && (se_radius < 20)
    se = strel('disk',se_radius) ;
    bot_frame = imclose(bot_frame,se) ;
    bot_s = regionprops(bot_frame,'BoundingBox','Centroid','Area') ;
    se_radius = se_radius + 1 ;
end
areas = [bot_s.Area] ;
[~, max_ind] = max(areas) ;
bot_s = bot_s(max_ind) ;

%------------------------------------------------------------------
%%% under construction %%%

% try to fill in occluded areas in top image (bottom image cannot
% be assumed to be convex, since it has dimple
%{
if top_s.Solidity < solidity_thresh
    bbox = top_s.BoundingBox ;
    convex_im = top_s.ConvexImage ;
    bbox = round(bbox) ;
    
    top_frame_convHull = false(size(top_frame)) ;
    top_frame_convHull(bbox(2):(bbox(2)+bbox(4)-1),...
        bbox(1):(bbox(1)+bbox(3)-1)) = convex_im ;
    
    top_frame = top_frame_convHull ;
    top_s = regionprops(top_frame,'BoundingBox','Centroid','Area') ;
end
%}
%---------------------------------------------
%% determine scale for top image
% (find difference in right x coordinate of bounding box for the two 
%   objects. scale the top image so it matches)
try
    bot_bbox_edge = bot_s.BoundingBox(1) + bot_s.BoundingBox(3) ;
    top_bbox_edge = top_s.BoundingBox(1) + top_s.BoundingBox(3) ;
    
    im_scale = 1 + (bot_bbox_edge - (top_bbox_edge + im_shift)) / ...
        (top_bbox_edge + im_shift) ;
catch
    im_scale = im_scale_user ;
end

%---------------------------------------------
%% perform translation/scaling to make tip regions match

top_frame = imtranslate(top_frame,[im_shift, 0]) ;
top_frame = imresize(top_frame, im_scale) ;

if (size(top_frame,1) > top_height) || (size(top_frame,2) > top_width)
    top_frame = top_frame(1:top_height, 1:top_width) ;
elseif (size(top_frame,1) < top_height) || ...
        (size(top_frame,2) < top_width)
    top_frame_tmp = false(top_height, top_width) ;
    top_frame_tmp(1:size(top_frame,1),1:size(top_frame,2)) = top_frame;
    top_frame = top_frame_tmp ;
end

top_s = regionprops(top_frame,'BoundingBox','Centroid','Area') ;

end