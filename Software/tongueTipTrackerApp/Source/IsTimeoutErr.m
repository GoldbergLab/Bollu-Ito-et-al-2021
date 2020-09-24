function isTimeOut = IsTimeoutErr(errCode)

switch(errCode)
    case PhConConst.ERR_TimeOut
        isTimeOut = true;
    case PhConConst.ERR_GetImageTimeOut
        isTimeOut = true;
    case PhConConst.ERR_GetTimeTimeOut
        isTimeOut = true;
    case PhConConst.ERR_GetAudioTimeOut
        isTimeOut = true;
    case PhConConst.ERR_NoResponseFromCamera
        isTimeOut = true;
    otherwise
        isTimeOut = false;
end

end