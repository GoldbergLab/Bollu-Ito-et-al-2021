function [out_xy] = centerofmass_kin(dirlist,fiducial)

%Takes in BW image masks and gives out centroids of each frame
%as a structure

for i=1:numel(dirlist)
    img_stack = load(dirlist(i).name);
    img_stack = img_stack.mask_pred;
    img_stack = permute(img_stack,[2 3 1]);
    
    for j=1:size(img_stack,3)
         
         temp = regionprops(img_stack(:,:,j),'centroid','Area','Pixellist');
         if numel(temp) == 1                 
            centroid_dist_vect = (temp.Centroid-fiducial);
            centroid_dist = (sum(centroid_dist_vect.^2)).^(0.5) ;                      
            
            dist_vect = temp.PixelList-repmat(fiducial,size(temp.PixelList,1),1);
            dist_vect = (dist_vect(:,1).^2 + dist_vect(:,2).^2).^(0.5);
            far_index = find(dist_vect == max(dist_vect));
            
            temp_centroids(j).Centroid = temp.Centroid;
            temp_centroids(j).Area = temp.Area;
            temp_centroids(j).centroid_dist = centroid_dist;
            temp_centroids(j).farthest = temp.PixelList(far_index,:);
            temp_centroids(j).farthest_dist = max(dist_vect);            
            
         elseif numel(temp) > 1
             if sum([temp.Area]>200)>0
                 region_ind = find([temp.Area] == max([temp.Area]));
                 PixelList = temp(region_ind).PixelList;
                 areas = temp(region_ind).Area;
                 
                 centroid_out = temp(region_ind).Centroid;
                 centroid_dist_vect = (centroid_out-fiducial);
                 centroid_dist = (sum(centroid_dist_vect.^2)).^(0.5) ;
                 
                 temp_centroids(j).Centroid = centroid_out;
                 temp_centroids(j).Area = areas;
                 temp_centroids(j).centroid_dist = centroid_dist;
                 
                 dist_vect = PixelList-repmat(fiducial,size(PixelList,1),1);
                 dist_vect = (dist_vect(:,1).^2 + dist_vect(:,2).^2).^(0.5);
                 far_index = find(dist_vect == max(dist_vect));
                 
                 temp_centroids(j).farthest = PixelList(far_index,:);
                 temp_centroids(j).farthest_dist = max(dist_vect);
             else
                 temp_centroids(j).Centroid = [NaN NaN];
                 temp_centroids(j).Area = [NaN];
                 temp_centroids(j).farthest = [NaN NaN];
                 temp_centroids(j).farthest_dist = [NaN];
                 temp_centroids(j).centroid_dist = [NaN];
             end
         else
            temp_centroids(j).Centroid = [NaN NaN];
            temp_centroids(j).Area = [NaN];
            temp_centroids(j).farthest = [NaN NaN];
            temp_centroids(j).farthest_dist = [NaN];
            temp_centroids(j).centroid_dist = [NaN];
         end
    end    
    
    out = [temp_centroids.Centroid];
       
    out_xy{i,1} = reshape(out,2,numel(out)/2);
    out_xy{i,2} = [temp_centroids.Area];
    out_xy{i,3} = {temp_centroids.farthest};
    out_xy{i,4} = [temp_centroids.farthest_dist];
    out_xy{i,5} = [temp_centroids.centroid_dist];
    
    clear temp_centroids;
end

