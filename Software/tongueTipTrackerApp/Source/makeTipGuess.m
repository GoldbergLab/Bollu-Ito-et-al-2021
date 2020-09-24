%--------------------------------------------------------------------------
% Function to estimate the rough position of the tongue tip based on
% checking voxel coordinates with 2 criteria:
%   - angle between given point and initial vector estimate is small
%   - distance between given point and centroid is sufficiently large
%
%   INPUTS:
%       -coords = voxel coordinates
%       -centroid = centroid coordinates
%       -init_vec = guess vector that the points will be dotted with
%       -theta_max = largest acceptable angle for point from init_vec
%       -dist_prctile = take only the points in the top (100-dist_prctile)
%       percent of distance from centroid
%
%   OUTPUT:
%       -tip_guess = guess for tip position in coordinates
%       -tip_guess_hat = normalized vector from centroid to tip
%--------------------------------------------------------------------------

function [tip_guess, tip_guess_hat, candidate_coords, cand_coords_idx] = ...
    makeTipGuess(coords, centroid, init_vec, theta_max, dist_prctile)

% take distance between coordinates and center.
N_rows = size(coords,1) ; 
centroid_dist_vec = coords - repmat(centroid,N_rows,1) ;
% take dot product with direction guess, normalize to get angle
dot_test = dot(centroid_dist_vec, repmat(init_vec,N_rows,1),2) ;
dot_test_norms = myNorm(centroid_dist_vec) ;
dot_test_cos = dot_test./dot_test_norms ;

% check angle
if isempty(theta_max)
    cos_max = -1 ; 
else
    cos_max = cos(theta_max) ;
end
dir_points_idx = (dot_test_cos > cos_max) ; 

% now check distance
weight_vec = abs(init_vec) ; 
dist_vec_norms = myNorm(centroid_dist_vec.*repmat(weight_vec,N_rows,1)) ; 
if isempty(dist_prctile)
    dist_thresh = 0 ;
else
    dist_thresh = prctile(dist_vec_norms,dist_prctile) ;
end
distal_points_idx = (dist_vec_norms > dist_thresh) ;

% points that are both far enough away and pointing in right direction
cand_coords_idx = dir_points_idx & distal_points_idx ;
candidate_coords = coords(cand_coords_idx,:) ;

% tip guess is the average of these points
tip_guess = mean(candidate_coords, 1) ;
tip_guess_vec = tip_guess - centroid ;
tip_guess_hat = tip_guess_vec./norm(tip_guess_vec) ;

end