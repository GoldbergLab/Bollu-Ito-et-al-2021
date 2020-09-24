% [pairs] = sensor_on_off_times(rawsens) generates a list of sensor 
% onset/offset pairs for example, pairs(1, 1) and pairs(1,2) will return 
% the times that a nosepoke came on and went off for the first nosepoke
% in the file
function [pairs, maxlen] = sensor_on_off_times(rawsens)
    pairs = []; maxlen = 0;
    sens_logic = ([0;rawsens;0]>0.5);
    k=1;
    if sum(sens_logic)>1
        sense_transition = diff(sens_logic); %this will show the transitions 
        b=sense_transition;
        flag=1;       
        for j=1:length(b)        
            if b(j)==1 && flag==1
                pairs(k,1) = j+1;
                pairs(k,2) = 0;
                flag=0;
            elseif b(j)==-1 && flag==0        
                pairs(k,2) = j-1;
                flag=1;
                time = pairs(k,2) - pairs(k,1);
                if time>maxlen; maxlen = time; end;
                k=k+1;
            end  
        end
    end
end