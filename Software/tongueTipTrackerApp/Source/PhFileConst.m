classdef(Sealed) PhFileConst
    % Use cast to desired type when using these constants
    properties(Constant)
        %% Cine File Codes
        MIFILE_RAWCINE	=	0
        MIFILE_CINE     =	1
        MIFILE_JPEGCINE	=	2
        MIFILE_AVI      =	3
        MIFILE_TIFCINE	=   4
        MIFILE_MPEG     =	5
        MIFILE_MXFPAL	=   6
        MIFILE_MXFNTSC	=   7
        MIFILE_QTIME	=   8
        %*****************************************************************************%
        
        
        %% Image File Codes
        SIFILE_WBMP24	=   -1
        SIFILE_WBMP8	=	-2
        SIFILE_WBMP4	=   -3
        SIFILE_OBMP4	=   -4
        SIFILE_OBMP8	=   -5
        SIFILE_OBMP24	=   -6
        SIFILE_TIF1     =	-7
        SIFILE_TIF8     =	-8
        SIFILE_TIF12	=	-9
        SIFILE_TIF16	=	-10
        SIFILE_PCX1     =	-11
        SIFILE_PCX8     =	-12
        SIFILE_PCX24	=	-13
        SIFILE_TGA8     =	-14
        SIFILE_TGA16	=	-15
        SIFILE_TGA24	=	-16
        SIFILE_TGA32	=   -17
        SIFILE_LEAD		=	-18
        SIFILE_LEAD1JFIF=	-19
        SIFILE_LEAD2JFIF=	-20
        SIFILE_LEAD1JTIF=   -21
        SIFILE_LEAD2JTIF=   -22
        SIFILE_JPEG     =	-23
        SIFILE_JTIF     =	-24
        SIFILE_RAW      =	-25
        SIFILE_DNG		=	-26
        SIFILE_DPX		=	-27
        %*****************************************************************************%
        
        
        %% Time Formats
        TF_LT			=		0			%% Local Time
        TF_UT			=		1			%% Universal Time
        TF_SMPTE		=		2			%% SMPTE TimeCode
        
        %% Time Format Flags (For PhPrintTime use)
        PPT_FULL			=	hex2dec('000');		%% Full time
        PPT_DATE_ONLY		=	hex2dec('100');		%% Date Only
        PPT_TIME_ONLY		=	hex2dec('200');		%% Time Only
        PPT_FRAC_ONLY		=	hex2dec('300');		%% Fractions Only
        PPT_ATTRIB_ONLY     =	hex2dec('400');		%% Attributes Only
        %*****************************************************************************%
        
        UC_VIEW		=			1	%% Use case - view
        UC_SAVE		=			2   %% Use case - save
        %*****************************************************************************%
        
        
        %% PhGetCineInfo% PhSetCineInfo selectors
        GCI_CFA                 =	0
        GCI_FRAMERATE           =	1
        GCI_EXPOSURE            =	2
        GCI_AUTOEXPOSURE        =	3
        GCI_REALBPP             =	4
        GCI_CAMERASERIAL        =	5
        GCI_HEADSERIAL0         =	6
        GCI_HEADSERIAL1         =	7
        GCI_HEADSERIAL2         =	8
        GCI_HEADSERIAL3         =	9
        GCI_TRIGTIMESEC         =	10
        GCI_TRIGTIMEFR          =	11
        GCI_ISFILECINE          =	12
        GCI_IS16BPPCINE         =	13
        GCI_ISCOLORCINE         =	14
        GCI_ISMULTIHEADCINE     =	15
        GCI_EXPOSURENS          =   16
        GCI_EDREXPOSURENS       =	17
        GCI_FRAMEDELAYNS        =   19
        
        GCI_FROMFILETYPE		=   20
        GCI_COMPRESSION         =   21
        GCI_CAMERAVERSION		=   22
        GCI_ROTATE				=   23
        GCI_IMWIDTH             =   24
        GCI_IMHEIGHT			=   25
        GCI_IMWIDTHACQ			=	26
        GCI_IMHEIGHTACQ         =	27
        GCI_POSTTRIGGER         =	28
        GCI_IMAGECOUNT			=	29
        GCI_TOTALIMAGECOUNT     =	30
        GCI_TRIGFRAME			=	31
        GCI_AUTOEXPLEVEL		=	32
        GCI_AUTOEXPTOP			=	33
        GCI_AUTOEXPLEFT         =	34
        GCI_AUTOEXPBOTTOM		=	35
        GCI_AUTOEXPRIGHT		=	36
        GCI_RECORDINGTIMEZONE	=	37
        GCI_FIRSTIMAGENO        =   38
        GCI_FIRSTMOVIEIMAGE     =   39
        GCI_CINENAME			=	40
        GCI_TIMEFORMAT			=	41
        
        GCI_FRPSTEPS			=	100
        GCI_FRP1X				=	101
        GCI_FRP1Y				=	102
        GCI_FRP2X				=	103
        GCI_FRP2Y				=	104
        GCI_FRP3X				=	105
        GCI_FRP3Y				=	106
        GCI_FRP4X				=	107
        GCI_FRP4Y				=	108
        GCI_WRITEERR			=	109
        
        GCI_LENSDESCRIPTION		=	110
        GCI_LENSAPERTURE		=	111
        GCI_LENSFOCALLENGTH		=	112
        
        GCI_WB					=	200
        GCI_WBVIEW				=	201
        GCI_WBISMETA			=	230
        GCI_BRIGHT				=	202
        GCI_CONTRAST			=	203
        GCI_GAMMA				=	204
        GCI_GAMMAR				=	223
        GCI_GAMMAB				=	224
        GCI_SATURATION			=	205
        GCI_HUE                 =	206
        GCI_FLIPH				=	207
        GCI_FLIPV				=	208
        GCI_FILTERCODE			=	209
        GCI_IMFILTER			=	210
        GCI_INTALGO             =	211
        GCI_PEDESTALR			=	212
        GCI_PEDESTALG			=	213
        GCI_PEDESTALB			=	214
        GCI_FLARE				=	225
        GCI_CHROMA				=	226
        GCI_TONE				=	227
        GCI_ENABLEMATRICES		=	228
        GCI_USERMATRIX			=	229
        GCI_RESAMPLEACTIVE		=	215
        GCI_RESAMPLEWIDTH		=	216
        GCI_RESAMPLEHEIGHT		=	217
        GCI_CROPACTIVE			=	218
        GCI_CROPRECTANGLE		=	219
        GCI_OFFSET16_8			=	220
        GCI_GAIN16_8			=	221
        GCI_DEMOSAICINGFUNCPTR	=	222
        
        GCI_VFLIPVIEWACTIVE     =	300
        
        GCI_MAXIMGSIZE			=	400
        
        GCI_FRPIMGNOARRAY		=	450
        GCI_FRPRATEARRAY		=	451
        GCI_FRPSHAPEARRAY		=	452
        
        GCI_TRIGTC				=	470
        GCI_TRIGTCU             =	471
        GCI_PBRATE				=	472
        GCI_TCRATE				=	473
        
        GCI_SAVERANGE			=	500
        GCI_SAVEFILENAME		=	501
        GCI_SAVEFILETYPE		=	502
        GCI_SAVE16BIT			=	503
        GCI_SAVEPACKED			=	504
        GCI_SAVEXML             =	505
        GCI_SAVESTAMPTIME		=	506
        
        GCI_SAVEAVIFRAMERATE		=	520
        GCI_SAVEAVICOMPRESSORLIST	=	521
        GCI_SAVEAVICOMPRESSORINDEX	=	522
        
        GCI_SAVEDPXLSB				=	530
        GCI_SAVEDPXTO10BPS			=	531
        GCI_SAVEDPXDATAPACKING		=	532
        GCI_SAVEDPX10BITLOG         =	533
        GCI_SAVEDPXEXPORTLOGLUT     =	534
        GCI_SAVEDPX10BITLOGREFWHITE =	535
        GCI_SAVEDPX10BITLOGREFBLACK =	536
        GCI_SAVEDPX10BITLOGGAMMA	=	537
        GCI_SAVEDPX10BITLOGFILMGAMMA=	538
        
        GCI_SAVEQTPLAYBACKRATE		=	550
        
        GCI_SAVECCIQUALITY			=	560
        
        GCI_UNCALIBRATEDIMAGE		=	600
        GCI_NOPROCESSING			=	601
        GCI_BADPIXELREPAIR			=	602
        %*****************************************************************************%
        
        
        MAXCOMPRCNT				=		64		%% Maximum compressor count
    end
    
    methods (Access = private)
        function out = PhFileConst()
        end
    end
end

