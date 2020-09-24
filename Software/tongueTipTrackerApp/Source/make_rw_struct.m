function [rw_trial_struct] = make_rw_struct(nl_struct)
rw_struct_number = 1;
trial_num = 1;
rw_trial_struct = struct;
first_time = 1;

for i = 1:numel(nl_struct)
    if (isempty(nl_struct(i).rw_cue)==0)
        
        rw_cue = nl_struct(i).rw_cue;
        laser_cue = nl_struct(i).laser_cue;
        dispense = nl_struct(i).dispense;
        licks = nl_struct(i).lick_pairs;
        
        if first_time == 1
            ref_time = nl_struct(i).real_time;
            ref_frame_num = nl_struct(i).start_frame;
            first_time = 0;
        end
        
        for j =1:length(rw_cue(:,1))
            rw_trial_struct(trial_num).frame_num = nl_struct(i).start_frame;
            rw_trial_struct(trial_num).rw_cue = [rw_cue(j,1),rw_cue(j,2)];
            rw_trial_struct(trial_num).laser = laser_cue(j);
            if(isempty(dispense)==0)
                
                dispense = dispense(:,1);
                dispense_in_cue = dispense(dispense>rw_cue(j,1)&dispense<=rw_cue(j,2)+10);
                rw_trial_struct(trial_num).dispense =  dispense_in_cue-rw_cue(j,1);
                
                licks_in_cue_orig = licks(:,1);
                licks_in_cue_orig = licks_in_cue_orig(licks_in_cue_orig>rw_cue(j,1));
                licks_in_cue = licks_in_cue_orig - rw_cue(j,1);
                lick_ili = diff(licks_in_cue);
                
                try
                    retrival_licks = [licks_in_cue(1)];
                    k=1;
                    retrival_ilis=[];
                    while lick_ili(k)<300
                        retrival_licks = [retrival_licks licks_in_cue(k+1)];
                        retrival_ilis = [retrival_ilis lick_ili(k)];
                        k=k+1;
                        if k ==length(lick_ili)
                            break
                        end
                    end
                    rw_trial_struct(trial_num).rw_licks = retrival_licks;
                    rw_trial_struct(trial_num).rw_ili = retrival_ilis;
                catch
                    rw_trial_struct(trial_num).rw_licks = []; %doesnt record if only one lick(dispense)
                    rw_trial_struct(trial_num).rw_ili = [];
                end
            else
                rw_trial_struct(trial_num).dispense = [];
            end
            
            rw_trial_struct(trial_num).real_time = datenum(ref_time) + (rw_trial_struct(trial_num).frame_num-ref_frame_num)/(24*60*60) + (rw_trial_struct(trial_num).rw_cue(1))/(24*3600*1000);
            trial_num = trial_num+1;
            
        end
    end
end
end

% rw = 0;
% for i = 1:numel(nl_struct)
%     rw = rw+length(nl_struct(i).rw_cue);
% end

