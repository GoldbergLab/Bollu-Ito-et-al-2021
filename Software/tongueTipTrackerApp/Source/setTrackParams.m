%--------------------------------------------------------------------------
% generates a structure containing the free parameters for the tongue tip
% tracking code. Currently, changes must be hard-coded within this file,
% but future iterations will (hopefully) allow changes programmatically
%--------------------------------------------------------------------------

function parameters = setTrackParams()

%% define parameters

% min number of pixels in mask or voxels in recon. to analyze frame
N_pix_min = 5 ; 
N_vox_min = 5 ; 

% normalized initial guess vector with which to compare voxel coordinates
init_vec_1 = (sqrt(2)/2)*[0, 1, -1] ; % NB: should try to automate this guess

% angle thresholds for defining search cone
theta_max_1 = pi/4 ; % radians
theta_max_2 = pi/12 ; 

% distance percentile level for which to consider points 
dist_prctile_1 = 75 ;
dist_prctile_2 = [] ; % at this point in the current code, we're already at the boundary

% transformation to apply to top image to match bottom image
im_shift = 5 ; % amount to translate top image by. based on spout comparison
im_scale_user = 1.0 ; % scale top image. ***only used when code fails to estimate scaling

% structural element used to erode pixels/voxels (and thus find boundary voxels)
sphere_se = strel('sphere',1) ; 
disk_se_radius = 4 ; % starting radius for S.E. used to combine broken bot mask
solidity_thresh = 0.95 ; % if solidity less than this, take convex hull (trying to deal with spout occlusion)

% minimum duration of lick bout to consider
min_bout_duration = 3 ; % frames

% settings for filtering kinematic data
filter_type = 'butter' ; 
filter_order = 3 ; 
filter_hpf = 50 ; % Hz (half power frequency of low-pass filter)
Fs = 1000 ; %Hz (sampling rate of video)

% method for segmenting tongue trajectories (based on area vs volume
% expansion)
seg_type = 'vol' ; %or 'area' 

% plotting preferences
view_az = 112 ; 
view_el = 8 ; 
line_width_thick = 2 ; 
line_width_thin = 1 ; 
marker_size_tiny = 0.5 ; 
marker_size_small = 5 ; 
marker_size_large = 10 ; 
hull_color = 0.7*[1 1 1] ; % color and transparency for tongue outline 
hull_alpha = 0.2 ;  %0.2
figPosition = [] ; % I use the position for full screen on one monitor here
axis_trim = 40 ; % amount to trim 3D plot (full) axes by
FPS = 10 ; % frame rate for movie making

% flags for plotting, saving, etc.
plotFlag1 = false ; % create movie showing tongue tracking w/ voxels and images?
plotFlag2 = false ; % plot 3D trajectory, speed, curvature, and torsion?
savePlotsFlag = false ;
saveDataFlag = false ; 
verboseFlag = false ; % print out frame count?

%% store parameters in structure
% initialize structure
parameters = struct() ; 

parameters.N_pix_min = N_pix_min ; 
parameters.N_vox_min = N_vox_min ; 

parameters.init_vec_1 = init_vec_1 ; 

parameters.theta_max_1 = theta_max_1 ; 
parameters.theta_max_2 = theta_max_2 ; 

parameters.dist_prctile_1 = dist_prctile_1 ; 
parameters.dist_prctile_2 = dist_prctile_2 ; 

parameters.im_shift = im_shift ; 
parameters.im_scale_user = im_scale_user ; 

parameters.sphere_se = sphere_se; 
parameters.disk_se_radius = disk_se_radius; 
parameters.solidity_thresh = solidity_thresh ; 

parameters.min_bout_duration = min_bout_duration ; 

parameters.filter_type = filter_type ;
parameters.filter_order = filter_order ;
parameters.filter_hpf = filter_hpf ;
parameters.Fs = Fs ; 

parameters.seg_type = seg_type ; 

parameters.view_az = view_az ; 
parameters.view_el = view_el ; 
parameters.line_width_thick = line_width_thick ; 
parameters.line_width_thin = line_width_thin ; 
parameters.marker_size_tiny = marker_size_tiny ; 
parameters.marker_size_small = marker_size_small ; 
parameters.marker_size_large = marker_size_large ; 
parameters.hull_color = hull_color ; 
parameters.hull_alpha = hull_alpha ; 
parameters.figPosition = figPosition ; 
parameters.axis_trim = axis_trim ; 
parameters.FPS = FPS ; 

parameters.plotFlag1 = plotFlag1 ; 
parameters.plotFlag2 = plotFlag2 ; 
parameters.savePlotsFlag = savePlotsFlag ; 
parameters.saveDataFlag = saveDataFlag ; 
parameters.verboseFlag = verboseFlag ; 

end