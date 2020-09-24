function [seginfo,redir_pts,rad_curv] = get_t_kinsegments(l_traj)

seginfo =[];
speed = l_traj.magspeed_t;

x_plt = l_traj.tip_x - l_traj.tip_x(1);
y_plt = l_traj.tip_y - l_traj.tip_y(1);
z_plt = l_traj.tip_z - l_traj.tip_z(1);

pos_vect = [x_plt',y_plt',z_plt'];
pos_vect_d1 = diff(pos_vect,1);
pos_vect_d2 = diff(pos_vect_d1,1);

cross_d1d2 = cross(pos_vect_d1(2:end,:),pos_vect_d2);
den_rc = sum(cross_d1d2.*cross_d1d2,2).^(0.5);
num_rc = (sum(pos_vect_d1.*pos_vect_d1,2).^(3/2));

rad_curv = num_rc(2:end)./den_rc;
rad_curv = reshape(rad_curv,1,numel(rad_curv));

[pks locs] = findpeaks(1./speed(2:end));
[pks1 locs1] = findpeaks(1./rad_curv);
dcurv = diff(1./rad_curv);

redir_pts = [];
for i=1:numel(locs1)   
    locsdiff = abs(locs-locs1(i));
    [~,rdirpt] = find(locsdiff<3);
    redir_pts = [redir_pts locs(rdirpt)];    
end

redir_pts = redir_pts(redir_pts<numel(dcurv));
redir_pts = redir_pts(abs(dcurv(redir_pts+1))>0.2);
%dcurv_pts = abs(dcurv(redir_pts+1));
redir_pts = [1 redir_pts+1 numel(x_plt)];


for i = 1:(length(redir_pts)-1)
    seginfo(i).xplt = x_plt(redir_pts(i):redir_pts(i+1));
    seginfo(i).yplt = y_plt(redir_pts(i):redir_pts(i+1));
    seginfo(i).zplt = z_plt(redir_pts(i):redir_pts(i+1)); 
    seginfo(i).dur = redir_pts(i+1)-redir_pts(i);
    seginfo(i).peakspeed = max(speed((redir_pts(i)):(redir_pts(i+1)-1)));
    seginfo(i).avgspeed = mean(speed((redir_pts(i)):(redir_pts(i+1)-1)));
    seginfo(i).pathlen = cumsum(speed((redir_pts(i)):(redir_pts(i+1)-1)));    
    seginfo(i).index = i;    
end