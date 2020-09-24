function [x_filt] = filter_and_scale(x_vect, hd)

x = reshape(x_vect,1,numel(x_vect));
x_filt = filtfilt(hd.SosMatrix,hd.scaleValues,x);