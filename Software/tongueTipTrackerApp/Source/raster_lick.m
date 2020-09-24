function [rw_lick_onset,laser_index,ind_difflow,inter_lick_interval,inter_reward_interval,disp_vect_onset] = raster_lick(nl_struct,plot_flag)

laser_index=0;
start_frame = nl_struct(1).start_frame;
rw_live =[];
lick_on =[];
laser_on = [];
np_onset = [];
dispense_onset = [];

for jj = 1:numel(nl_struct)
    mul = nl_struct(jj).start_frame-start_frame;
    if numel(nl_struct(jj).rw_live)>0
        rw_live = [rw_live;nl_struct(jj).rw_live(:,1)+1000*mul];
    end
    if numel(nl_struct(jj).lick_pairs)>0
        lick_on = [lick_on;nl_struct(jj).lick_pairs(:,1)+1000*mul];
    end
    if numel(nl_struct(jj).laser_on)>0
        laser_on = [laser_on;nl_struct(jj).laser_on(:,1)+1000*mul];
    end
    if numel(nl_struct(jj).np_pairs)>0
        np_onset = [np_onset;nl_struct(jj).np_pairs(:,1)];
    end
    if numel(nl_struct(jj).dispense)>0
        dispense_onset = [dispense_onset;nl_struct(jj).dispense(:,1)+1000*mul];
    end
end
    
    rw_live_diff = diff(rw_live);
    [rw_l_d_sorted,ind_difflow] = sort(rw_live_diff);
    %ind_difflow = 1:length(rw_live_diff);
    %[rw_l_d_sorted] = rw_live_diff;

    edges = 0:1000:14000;
    rw_live_dist = histc(rw_live_diff,edges);
    inter_reward_interval = rw_live_diff;

    %%
  
    for i=1:length(ind_difflow)
        rw_align = rw_live(i);
        rw_lick_onset{i} = lick_on(((lick_on-rw_align)>(-2000))&((lick_on-rw_align)<14000)) - rw_align;
        disp_vect_onset{i} = dispense_onset((dispense_onset-rw_align)>0 & (dispense_onset-rw_align)<1300)-rw_align;
        if numel(laser_on)>0
            if sum(abs(laser_on-rw_align)<5)>0
                laser_index(i) = 1;
            else
                laser_index(i) = 0;
            end
        else
            laser_index(i)=0;
        end
    end
    
    inter_lick_interval = diff(lick_on);
    inter_np_interval = diff(np_onset);

if plot_flag
    %% Plot the Inter-reward-interval
    figure;
    stairs(edges,rw_live_dist,'k');

    title('Inter Cue interval');
    
    jj=0;
    kk=0;
    %%
    laser_index_raster = find(laser_index==1);
    catch_index_raster = find(laser_index==0);
    
    index_catch = []; index_laser = [];
    lick_catch = []; lick_laser = [];
        
    for i=1:length(ind_difflow)
        lick_onset_plot = rw_lick_onset{ind_difflow(i)};        
        if laser_index(i) == 1
            kk=kk+1;
            index_laser = [index_laser;kk*ones(numel(lick_onset_plot),1)];
            lick_laser = [lick_laser;lick_onset_plot];
        else 
            jj = jj+1;                
            index_catch = [index_catch;jj*ones(numel(lick_onset_plot),1)];
            lick_catch = [lick_catch;lick_onset_plot];
        end        
    end
    
    try
        figure;
        plot(lick_catch,index_catch,'k.','MarkerSize',10);
        title('Control Trials Raster');
        xlim([-2000 14000]);
    catch
    end
    try
        figure;
        plot(lick_laser,index_laser,'k.','MarkerSize',10);
        title('Laser Trials Raster');
    catch
    end
     
%     figure;
%     for i=1:length(ind_difflow)
%         plot(rw_l_d_sorted,1:length(ind_difflow),'r');
%     end
    
    figure;    
    xspace = logspace(0,3.4771,100);
    %xspace = 0:5:2000;
    ili_dist= histc(inter_lick_interval,xspace)/numel(inter_lick_interval);
    stairs(xspace,ili_dist)
    title('Inter Lick Interval')
    xlabel('Time (ms)')
    ylabel('Probability');
%     figure;    
%     %xspace = logspace(0,4,100);
%     xspace = 0:10:2000;
%     np_dist= histc(inter_np_interval,xspace);
%     stairs(xspace,np_dist);
end