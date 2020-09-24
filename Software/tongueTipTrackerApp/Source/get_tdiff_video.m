function [tdiff_sp, tdiff_vid, result] = get_tdiff_video(sessionVideoRoots, FPGADataRoots)
result = true;
for sessionNum=1:numel(sessionVideoRoots)
    videoList = dir([sessionVideoRoots{sessionNum},'\*.avi']);
    try
    for videoNum=1:numel(videoList)
        [~, videoName, ~] = fileparts(videoList(videoNum).name);
        videoNameParts = strsplit(videoName);
        dateParts = videoNameParts(5:7);
        hours = str2num(dateParts{1});
        minutes = str2num(dateParts{2});
        seconds = str2num(dateParts{3});
        trial_time(videoNum) = hours/24 + minutes/(24*60)+seconds/(24*60*60);
    end
    catch e
        disp(e)
        result='Failed to parse the video timestamp. Make sure videos are saved with the correct video timestamp format.';
        tdiff_sp = [];
        tdiff_vid = [];
        return
    end
    tdiff_vid{sessionNum} = diff(trial_time);
    clear trial_time
end

for sessionNum=1:numel(FPGADataRoots)
    try
        load(fullfile(FPGADataRoots{sessionNum},'lick_struct.mat'), 'lick_struct');
    catch e
        result = ['Failed to load lick_struct.mat at ', fullfile(FPGADataRoots{sessionNum},'lick_struct.mat')];
    end
        
    tdiff_sp{sessionNum} = diff([lick_struct.real_time]);
end

% %% remove everything below
% dirlist = rdir('Top*');
% for i = 1:numel(dirlist) 
%     name = dirlist(i).name;
%     split_name1 = strsplit(name,'p');
%     split_name2 = strsplit(split_name1{2},'.');
%     split_name1{2} = strcat(sprintf('%03d',str2num(split_name2{1})-28),'.mat');
%     
%     movefile(name,strcat(split_name1{1},'p',split_name1{2}));
% end