function [ message ] = OutputError( errCode )

if (errCode<0 && ~IsTimeoutErr(errCode))
    [message] = PhGetErrorMessage( errCode );
    warning(['Phantom error: ' message]);
%elseif (errCode>0 && errCode~=PhConConst.ERR_SimulatedCamera)%warning
%     [message] = PhGetErrorMessage( errCode );
%     warning(['Phantom warning: ' message]);
end

end


