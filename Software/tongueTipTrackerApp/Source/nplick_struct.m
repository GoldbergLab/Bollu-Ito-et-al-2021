function [nl_struct,raster_struct, result] = nplick_struct(dirlist_root, varargin)
    % Result is either a logical true if the process completed successfully or a char array describing the error
    result = true;

    if nargin < 2
        plotOutput = false;
    else
        plotOutput = varargin{1};
    end

    try
        dirlist = rdir(strcat(dirlist_root,'\comb\*.mat'));
    catch e
        result = ['nplick_struct could''nt find combined/converted files in ', dirlist_root, '. Make sure you combine/convert FPGA files first using ppscript'];
    end

    for i=1:numel(dirlist)     
       load(dirlist(i).name,'working_buff','start_frame','real_time');
              
       y = [medfilt1(working_buff(:,5),3)];
       
       nl_struct(i).start_frame = start_frame;       
       nl_struct(i).np_pairs = sensor_on_off_times(working_buff(:,2));
       nl_struct(i).dispense = sensor_on_off_times(working_buff(:,3));
       nl_struct(i).laser_on = sensor_on_off_times(working_buff(:,4));
       nl_struct(i).lick_pairs = sensor_on_off_times(y);         
       nl_struct(i).rw_live = sensor_on_off_times(working_buff(:,6));             
       nl_struct(i).real_time = real_time;
       
       temperature = working_buff(:,1);
       
       try
           nl_struct(i).rw_cue = sensor_on_off_times(working_buff(:,7));
           if numel(nl_struct(i).rw_cue)>0               
               rw_cue_onset = nl_struct(i).rw_cue(:,1);                                             
               for j=1:numel(rw_cue_onset)
               %% Determine if Rw_Cue has a Laser On    
                   try
                       if sum(abs(nl_struct(i).laser_on(:,1)-rw_cue_onset(j))<5)>0
                           nl_struct(i).laser_cue(j) = 1;
                       else
                           nl_struct(i).laser_cue(j) = 0;
                       end
                   catch
                       nl_struct(i).laser_cue(j) = 0;
                   end
               %% Determine Temperature within the Rw_Cue
               try
                   nl_struct(i).temp(j) = mean(temperature(rw_cue_onset(j):(rw_cue_onset(j)+1300)));
               catch
                   temp_error=1;
               end
               end                   
           end        
       catch
       end       
    end
save(strcat(dirlist_root,'\nl_struct.mat'),'nl_struct');
    
% raster_struct = 1;
       [rw_lick_onset,laser_index,ind_difflow,ili,iri,dispense_onset] = raster_lick(nl_struct,plotOutput);
       
       raster_struct.rw_lick = rw_lick_onset;
       raster_struct.laser_index = laser_index;
       raster_struct.ind_difflow = ind_difflow;
       raster_struct.ili = ili;
       
       rw_lick_nl = rw_lick_onset(laser_index==0);
       rw_dispense_nl = dispense_onset(laser_index==0);
       
       for j=1:length(rw_lick_nl)
           if sum(rw_lick_nl{j}>0 & rw_lick_nl{j}<1300)>0
                rw_lick_resp(j) = 1;
           else
                rw_lick_resp(j) = 0;
           end                      
       end
       
       for j=1:length(rw_dispense_nl)
           if sum(rw_dispense_nl{j}>0)>0
               disp_resp(j) = 1;
           else
               disp_resp(j) = 0;
           end                      
       end
       
       raster_struct.rw_lick_resp = rw_lick_resp;
       
       raster_struct.iri = iri;
       raster_struct.iri_with_resp = iri(rw_lick_resp == 1);
       if plotOutput
           figure;plot(1:numel(raster_struct.iri_with_resp),raster_struct.iri_with_resp/1000,'bx');
           ylim([-2 15]);

           y = filtfilt(ones(1,1)/1,1,rw_lick_resp);
           figure;plot(y)
           ylim([0 1.2]);
           title('Lick Response to cue');
           xlabel('Trial Number');
           ylabel('Responded');

           y1 = filtfilt(ones(5,1)/5,1,disp_resp);
           figure;plot(y1)
           ylim([0 1.2]);
           title('Rewarded on Cue');

           c = raster_struct.laser_index;
           d(c==0)=1;
           figure;plot(cumsum(d));
           ylabel('Control Trials');
           xlabel('Total Trials');
       end

       lick_struct = make_rw_struct(nl_struct);
       
save(strcat(dirlist_root,'\raster_struct.mat'),'raster_struct');
save(strcat(dirlist_root,'\lick_struct.mat'),'lick_struct');
   