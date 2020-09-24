classdef(Sealed) PhConConst
    % Use cast when using these constants
    
    properties(Constant)
        PHCONHEADERVERSION = 770    % Call PhRegisterClientEx(...,PHCONHEADERVERSION) using this value
        % has to be changed only here; it is the third component of the Phantom files version
        %*****************************************************************************%
        
        MAXCAMERACNT = 63       % maximum count of cameras
        % including the "preview" cine
        MAXERRMESS = 256        % maximum size of error messages for
        %PhGetErrorMessage function
        
        MAXIPSTRSZ = 16         %Maximum IP string length
        %*****************************************************************************%
        
        % Predefined cines
        CINE_DEFAULT = -2		% The number of the default cine
        CINE_CURRENT = -1		% The cine number used to request live images
        CINE_PREVIEW = 0		% The number of the preview cine
        CINE_FIRST = 1          % The number of the first cine when emulating
        % a single cine camera
        %*****************************************************************************%
        
        % Selection codes in the functions PhGet(),  PhSet()
        % 1. Camera current status information
        gsHasMechanicalShutter = 1025
        gsHasBlackLevel4 = 1027
        gsHasCardFlash = 1051
        gsHas10G = 2000
        %*****************************************************************************%
        
        % 2. Capabilities
        gsSupportsInternalBlackRef = 1026
        gsSupportsImageTrig	= 1040
        gsSupportsCardFlash	= 1050
        gsSupportsMagazine = 8193
        gsSupportsHQMode = 8194
        gsSupportsGenlock =	8195
        gsSupportsEDR =	8196
        gsSupportsAutoExposure = 8197
        gsSupportsTurbo = 8198
        gsSupportsBurstMode = 8199
        gsSupportsShutterOff = 8200
        gsSupportsDualSDIOutput = 8201
        gsSupportsRecordingCines = 8202
        gsSupportsV444 = 8203
        gsSupportsInterlacedSensor = 8204
        gsSupportsRampFRP =	8205
        gsSupportsOffGainCorrections = 8206
        %*****************************************************************************%
        
        % 3. Camera current parameters
        gsSensorTemperature	= 1028
        gsCameraTemperature	= 1029
        gsThermoElectricPower =	1030
        gsSensorTemperatureThreshold = 1031
        gsCameraTemperatureThreshold = 1032
        
        gsVideoPlayCine = 1033
        gsVideoPlaySpeed = 1034
        gsVideoOutputConfig	= 1035
        
        gsMechanicalShutter	= 1036
        
        gsImageTrigThreshold = 1041
        gsImageTrigAreaPercentage = 1042
        gsImageTrigSpeed = 1043
        gsImageTrigMode = 1044
        gsImageTrigRect = 1045
        
        gsAutoProgress = 1046
        gsAutoBlackRef = 1047
        
        gsCardFlashSizeK = 1052
        gsCardFlashFreeK = 1053
        gsCardFlashError = 1054
        
        gsIPAddress	= 1070
        gsEthernetAddress = 1055
        gsEthernetMask = 1056
        gsEthernetBroadcast = 1057
        gsEthernetGateway = 1058
        
        gsLensFocus	= 1059
        gsLensAperture = 1060
        gsLensApertureRange = 1061
        gsLensDescription = 1062
        gsLensFocusInProgress = 1063
        gsLensFocusAtLimit = 1064
        
        gsGenlock = 1065
        gsGenlockStatus	= 1066
        
        gsTurboMode	= 1068
        gsModel	= 1069
        
        gsMaxPartitionCount = 1071
        %*****************************************************************************%
        
        % Selection codes in the functions PhCineGet(), PhCineSet()
        cgsVideoTone = 4097
        
        cgsName	= 4098
        
        cgsVideoMarkIn = 4099
        cgsVideoMarkOut	= 4100
        
        cgsIsRecorded = 4101
        cgsHqMode = 4102
        
        cgsBurstCount = 4103
        cgsBurstPeriod	= 4104
        
        cgsLensDescription = 4105
        cgsLensAperture	= 4106
        cgsLensFocalLength = 4107
        
        cgsShutterOff = 4108
        
        cgsTriggerTime = 4109
        
        cgsTrigTC = 4110
        cgsPbRate = 4111
        cgsTcRate = 4112
        
        % Image processing
        cgsWb = 5100
        cgsBright = 5101
        cgsContrast = 5102
        cgsGamma = 5103
        cgsGammaR = 5109
        cgsGammaB = 5110
        cgsSaturation = 5104
        cgsHue = 5105
        cgsPedestalR = 5106
        cgsPedestalG = 5107
        cgsPedestalB = 5108
        cgsFlare = 5111
        cgsChroma = 5112
        cgsTone	= 5113
        cgsUserMatrix =	5114
        cgsEnableMatrices = 5115
        %*****************************************************************************%
        
        % PhGetVersion constants
        GV_CAMERA	= 1
        GV_FIRMWARE	= 2
        GV_FPGA		= 3
        GV_PHCON    = 4
        GV_CFA		= 5
        GV_KERNEL	= 6
        GV_MAGAZINE	= 7
        %*****************************************************************************%
        
        % PhGetAuxData selection codes
        GAD_TIMEXP  = 1001    % both image time and exposure
        GAD_TIME = 1002
        GAD_EXPOSURE = 1003
        GAD_RANGE1 = 1004    % range data
        GAD_BINSIG = 1005    % image binary signals multichannels multisample
        % 8 samples and or channels per byte
        GAD_ANASIG       =  1006    % image analog signals multichannels multisample
        % 2 bytes per sample
        GAD_SMPTETC	= 1007	% SMPTE time code block (see TC)
        GAD_SMPTETCU = 1008	% SMPTE unpacked time code block (see TCU)
        %*****************************************************************************%
        
        % PhSetDllsOptions selectors
        DO_IGNORECAMERAS = 1
        %*****************************************************************************%
        
        % Set logging options - set the masks for selective dumps from Phantom dlls
        % Use them as selection codes for the function PhSetDllsLogOption
        SDLO_PHANTOM = 100
        SDLO_PHCON   = 101
        SDLO_PHINT	 = 102
        SDLO_PHFILE  =103
        SDLO_PHSIG	 = 104
        SDLO_PHSIGV	 = 105
        SDLO_TORAM	 = 106
        %*****************************************************************************%
        
        % Get logging options - get the current settings
        % Use them as selection codes for the function PhGetDllsLogOption
        GDLO_PHANTOM	= 200
        GDLO_PHCON      = 201
        GDLO_PHINT      = 202
        GDLO_PHFILE     = 203
        GDLO_PHSIG      = 204
        GDLO_PHSIGV     = 205
        GDLO_TORAM      = 206
        %*****************************************************************************%
        
        % Fill the requested data by simulated values
        SIMULATED_AUXDATA = hex2dec('80000000');
        %*****************************************************************************%
        
        % Constants for the PhNVMContRec function
        % NVM = Flash memory (NonVolatileMemory used for persistent cine store)
        NVCR_CONT_REC	=	hex2dec('00000001')  % Enable continuous recording to NVM mode
        NVCR_APV		=	hex2dec('00000002')  % Enable the automatic playback to video
        NVCR_REC_ONCE	=	hex2dec('00000004')  % Enable the record once mode
        %*****************************************************************************%
        
        % SyncImaging field in ACQUIPARAMS
        SYNC_INTERNAL	=	0		% Free-run of camera
        SYNC_EXTERNAL	=	1		% Locks to the FSYNC input
        SYNC_LOCKTOIRIG	=	2		% Locks to IRIG timecode
        %*****************************************************************************%
        
        % Color Filter Array used on the sensor
        % In mixed multihead system the gray heads have also some of the msbit set (see XX_GRAY below)
        CFA_NONE		=	0		% gray sensor
        CFA_VRI		=		1		% gbrg%rggb
        CFA_VRIV6		=	2		% bggr%grbg
        CFA_BAYER		=	3		% gb%rg
        CFA_BAYERFLIP	=	4		% rg%gb
        CFA_MASK		=	hex2dec('ff')	% only lsbyte is used for cfa code, the rest is for multiheads
        %*****************************************************************************%
        
        % These masks combined with  CFA_VRIV6  describe a mixed (gray&color) image (Phantom v6)
        TL_GRAY = hex2dec('80000000')    % Top left head of v6 multihead system is gray
        TR_GRAY = hex2dec('40000000')    % Top right head of v6 multihead system is gray
        BL_GRAY = hex2dec('20000000')    % Bottom left head of v6 multihead system is gray
        BR_GRAY = hex2dec('10000000')    % Bottom right head of v6 multihead system is gray
        %*****************************************************************************%
        
        ALLHEADS_GRAY = hex2dec('F0000000')    %(TL_GRAY|TR_GRAY|BL_GRAY|BR_GRAY)
        %*****************************************************************************%
        
        % Analog and digital video output
        VIDEOSYS_NTSC	      = 0		% USA analog system
        VIDEOSYS_PAL          = 1		% European analog system
        
        VIDEOSYS_720P60       = 4		% Digital HDTV modes: Progressive
        VIDEOSYS_720P59DOT9   = 12
        VIDEOSYS_720P50       = 5
        VIDEOSYS_1080P30      = 20
        VIDEOSYS_1080P29DOT9  = 28
        VIDEOSYS_1080P25      = 21
        VIDEOSYS_1080P24      = 36
        VIDEOSYS_1080P23DOT9  = 44
        
        VIDEOSYS_1080I30      = 68      % Interlaced
        VIDEOSYS_1080I29DOT9  = 76
        VIDEOSYS_1080I25      = 69
        
        VIDEOSYS_1080PSF30     = 52      % Progressive split frame
        VIDEOSYS_1080PSF29DOT9 = 60
        VIDEOSYS_1080PSF25     = 53
        VIDEOSYS_1080PSF24     = 84
        VIDEOSYS_1080PSF23DOT9 = 92
        %*****************************************************************************%
        
        %% PhCon Error Codes
        %% Informative
        ERR_Ok                          = 0
        ERR_SimulatedCamera             = 100
        ERR_UnknownErrorCode            = 101
        
        ERR_BadResolution               = 102
        ERR_BadFrameRate                = 103
        ERR_BadPostTriggerFrames        = 104
        ERR_BadExposure                 = 105
        ERR_BadEDRExposure              = 106
        
        ERR_BufferTooSmall              = 107
        ERR_CannotSetTime               = 108
        ERR_SerialNotFound              = 109
        ERR_CannotOpenStgFile           = 110
        
        ERR_UserInterrupt               = 111
        
        ERR_NoSimulatedImageFile        = 112
        ERR_SimulatedImageNot24bpp      = 113
        
        ERR_BadParam                    = 114
        ERR_FlashCalibrationNewer       = 115
        
        ERR_ConnectedHeadsChanged       = 117
        ERR_NoHead                      = 118
        ERR_NVMNotInstalled             = 119
        ERR_HeadNotAvailable            = 120
        ERR_FunctionNotAvailable        = 121
        ERR_Ph1394dllNotFound           = 122
        ERR_oldtNotFound                = 123
        ERR_BadFRPSteps                 = 124
        ERR_BadFRPImgNr                 = 125
        ERR_BadAutoExpLevel             = 126
        ERR_BadAutoExpRect              = 127
        ERR_BadDecimation               = 128
        ERR_BadCineParams               = 129
        ERR_IcmpNotAvailable            = 130
        ERR_CorrectResetLine			= 131
        ERR_CSRDoneInCamera             = 132
        ERR_ParamsChanged               = 133
        
        ERR_ParamReadOnly				= 134
        ERR_ParamWriteOnly				= 135
        ERR_ParamNotSupported			= 136
        
        ERR_IppWarning					= 137
        %*****************************************************************************%
        
        %% Serious
        ERR_NULLPointer                 = -200
        ERR_MemoryAllocation            = -201
        ERR_NoWindow                    = -202
        ERR_CannotRegisterClient        = -203
        ERR_CannotUnregisterClient      = -204
        
        ERR_AsyncRead                   = -205
        ERR_AsyncWrite                  = -206
        
        ERR_IsochCIPHeader              = -207
        ERR_IsochDBCContinuity          = -208
        ERR_IsochNoHeader               = -209
        ERR_IsochAllocateResources      = -210
        ERR_IsochAttachBuffers          = -211
        ERR_IsochFreeResources          = -212
        ERR_IsochGetResult              = -213
        
        ERR_CannotReadTheSerialNumber   = -214
        ERR_SerialNumberOutOfRange      = -215
        ERR_UnknownCameraVersion        = -216
        
        ERR_GetImageTimeOut             = -217
        ERR_ImageNoOutOfRange           = -218
        
        ERR_CannotReadStgHeader         = -220
        ERR_ReadStg                     = -221
        ERR_StgContents                 = -222
        ERR_ReadStgOffsets              = -223
        ERR_ReadStgGains                = -224
        ERR_NotAStgFile                 = -225
        ERR_StgSetupCheckSum            = -226
        ERR_StgSetup                    = -227
        ERR_StgHardAdjCheckSum          = -228
        ERR_StgHardAdj                  = -229
        ERR_StgDifferentSerials         = -230
        ERR_WriteStg                    = -231
        
        ERR_NoCine                      = -232
        ERR_CannotOpenDevice            = -233
        ERR_TimeBufferSize              = -234
        
        ERR_CannotWriteCineParams       = -236
        
        ERR_NVMError                    = -250
        ERR_NoNVM                       = -251
        
        ERR_FlashEraseTimeout           = -253
        ERR_FlashWriteTimeout           = -254
        
        ERR_FlashContents               = -255
        ERR_FlashOffsetsCheckSum        = -256
        ERR_FlashGainsCheckSum          = -257
        
        ERR_TooManyCameras              = -258
        ERR_NoResponseFromCamera        = -259
        ERR_MessageFromCamera           = -260
        
        ERR_BadImgResponse              = -261
        ERR_AllPixelsBad                = -262
        
        ERR_BadTimeResponse             = -263
        ERR_GetTimeTimeOut              = -264
        ERR_GetAudioTimeOut             = -266
        
        %%Base64 coding and decoding errors
        ERR_InBlockTooBig               = -270
        ERR_OutBufferTooSmall           = -271
        ERR_BlockNotValid               = -272
        ERR_DataAfterPadding            = -273
        ERR_InvalidSlash                = -274
        ERR_UnknownChar                 = -275
        ERR_MalformedLine               = -276
        ERR_EndMarkerNotFound           = -277
        
        ERR_NoTimeData                  = -280
        ERR_NoExposureData              = -281
        ERR_NoRangeData                 = -282
        
        ERR_NotIncreasingTime           = -283
        ERR_BadTriggerTime              = -284
        ERR_TimeOut                     = -285
        
        ERR_NullWeightsSum              = -286
        ERR_BadCount                    = -287
        ERR_CannotChangeRecordedCine    = -288
        
        ERR_BadSliceCount               = -289
        ERR_NotAvailable                = -290
        ERR_BadImageInterval            = -291
        
        ERR_BadCameraNumber             = -292
        ERR_BadCineNumber               = -293
        
        ERR_BadSyncObject               = -294
        ERR_IcmpEchoError  			    = -295
        
        ERR_MlairReadFirstPacket		= -296
        ERR_MlairReadPacket				= -297
        ERR_MlairIncorrectOrder			= -298
        
        ERR_MlairStartRecorder			= -299
        ERR_MlairStopRecorder			= -300
        ERR_MlairOpenFile				= -301
        
        ERR_CmdMutexTimeOut				= -302
        ERR_CmdMutexAbandoned			= -303
        
        ERR_UnsupportedConversion		= -304
        
        ERR_TenGigLostPacket			= -305
        
        ERR_TooManyImgReq				= -306
        
        ERR_BadImRange					= -307
        ERR_ImgBufferTooSmall			= -308
        ERR_ImgSize0					= -309
        
        ERR_IppError					= -310
        %*****************************************************************************%
        
        % Notification messages sent to your main window  -  call the notification
        % routines to process these messages
        NOTIFY_DEVICE_CHANGE = 1325            %(WM_USER+301)   WM_USER=0x0400
        NOTIFY_BUS_RESET     = 1326           %(WM_USER+302)
        
        %PhGetImage constants
        GI_INTERPOLATED = 4   % color image, RGB interpolated
        % extensions for v6 and other multihead systems
        GI_ONEHEAD = 8        % multihead system, bit=1: select image from one head
        GI_HEADMASK =  hex2dec('f0');   %head number: 0:TL 1:TR 2:BL 3:BR.. (up to 16 heads,
        %v6 has 4 heads)   -  bits 4...7 of the Options
        %extensions for v7
        %GI_BPP12				0x100   %BitsPerPixel = 12 for the requested image - not implemented, not used
        GI_BPP16 = hex2dec('200');   %BitsPerPixel = 16 for the requested image
        
        GI_PACKED = hex2dec('100');   %return the pixels as read from camera; possible packed (10 bits: 4 pixels in 5 bytes)
    end
    
    methods (Access = private)
        function out = PhConConst()
        end
    end
end

