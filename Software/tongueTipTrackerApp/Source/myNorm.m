function y = myNorm(x) 
% calculates the norm of each row of x
y = sum(x.^2,2).^0.5 ;
return
