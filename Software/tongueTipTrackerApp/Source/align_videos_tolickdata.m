function [vid_ind_arr, result] = align_videos_tolickdata(sessionVideoRoots,sessionDataRoots,sessionFPGARoots,time_aligned_trial)
% result is either true if the processing completed successfully or a cell array of char arrays describing the error.
result = true;
vid_ind_arr = [];

for sessionNum = 1:numel(sessionVideoRoots)
    videoList = rdir(fullfile(sessionVideoRoots{sessionNum},'*.avi'));
    try
        load(fullfile(sessionFPGARoots{sessionNum},'lick_struct.mat'));
    catch e
        if ~iscell(result)
            result = {};
        end
        result = [result, ['Error: Could not find lick_struct.mat for the session', sessionDataRoots{sessionNum}, '. Make sure to get lick segmentation and kinematics first.']];
        continue;
    end
    
    %Time aligned Trial
    tal = time_aligned_trial;
    
    %% Get Times of all the videos
        vid_real_time = [];
    for videoNum=1:numel(videoList)        
        name_cells = strsplit(videoList(videoNum).name,'\');
        name_cells = strsplit(name_cells{end});
        trial_time = str2num(name_cells{5})/24+str2num(name_cells{6})/(24*60)+str2num(name_cells{7})/(24*60*60);
        vid_real_time(videoNum) = trial_time;
    end
    
    %% Align Time stamps
    spout_time = mod(lick_struct(tal(sessionNum,2)).real_time,1);
    vid_time = vid_real_time(tal(sessionNum,1));
    
    tdiff = (spout_time - vid_time);
    
    vid_real_time = vid_real_time + tdiff;
    
    spout_time_vect = [lick_struct.real_time];
    spout_time_vect = mod(spout_time_vect,1);
    
    %% find corresponding spout trials
    vid_index = [];
    for videoNum=1:numel(vid_real_time)        
        [min_val(videoNum),vid_index(videoNum)] = min(abs(spout_time_vect-vid_real_time(videoNum)));        
        if min_val(videoNum)>2*10^(-5)
            vid_index(videoNum) = nan;
        end
    end 
        
    try
        load(fullfile(sessionDataRoots{sessionNum},'t_stats.mat'),'t_stats')
    catch e
        if ~iscell(result)
            result = {};
        end
        result = [result, ['Error: Could not find t_stats.mat for the session', sessionDataRoots{sessionNum}, '. Make sure to process FPGA data first.']];
        continue
    end

    l_sp_struct = lick_struct;    
    vid_ind_arr{sessionNum} = vid_index;
    
    %% Assign Type of Lick   
    t_stats = assign_lick_type(t_stats,l_sp_struct,vid_index);
    
    %% Save the Struct
    save(fullfile(sessionDataRoots{sessionNum},'t_stats.mat'),'t_stats','l_sp_struct','vid_index');

end