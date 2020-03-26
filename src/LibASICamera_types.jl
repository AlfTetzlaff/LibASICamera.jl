const ASICAMERA_ID_MAX = 128

# Type and error enumerations

@cenum ASI_CONTROL_TYPE::UInt32 begin
    ASI_GAIN = 0
    ASI_EXPOSURE = 1  # Exposure time in μs
    ASI_GAMMA = 2     # 1-100, default: 50
    ASI_WB_R = 3      # white balance, red component
    ASI_WB_B = 4      # white balance, blue
    ASI_OFFSET = 5    # pixel value offset / bias
    ASI_BANDWIDTHOVERLOAD = 6  # data transfer rate percentage
    ASI_OVERCLOCK = 7
    ASI_TEMPERATURE = 8  # 10 times the actual temperature
    ASI_FLIP = 9
    ASI_AUTO_MAX_GAIN = 10  # Maximum gain when auto adjust
    ASI_AUTO_MAX_EXP = 11   # Maximum exposure time when auto adjust, μs
    ASI_AUTO_TARGET_BRIGHTNESS = 12  # Target brightness when auto adjust
    ASI_HARDWARE_BIN = 13
    ASI_HIGH_SPEED_MODE = 14
    ASI_COOLER_POWER_PERC = 15
    ASI_TARGET_TEMP = 16  # °C, don't multiply by 10
    ASI_COOLER_ON = 17
    ASI_MONO_BIN = 18  # lead to a smaller grid at software bin mode for color camera?!
    ASI_FAN_ON = 19
    ASI_PATTERN_ADJUST = 20  # currently only supported by 1600 mono camera
    ASI_ANTI_DEW_HEATER = 21
end

const ASI_BRIGHTNESS = ASI_OFFSET
const ASI_AUTO_MAX_BRIGHTNESS = ASI_AUTO_TARGET_BRIGHTNESS

@cenum ASI_BAYER_PATTERN::UInt32 begin
    ASI_BAYER_RG = 0
    ASI_BAYER_BG = 1
    ASI_BAYER_GR = 2
    ASI_BAYER_GB = 3
end

@cenum ASI_IMG_TYPE::Int32 begin
    ASI_IMG_RAW8 = 0
    ASI_IMG_RGB24 = 1
    ASI_IMG_RAW16 = 2
    ASI_IMG_Y8 = 3
    ASI_IMG_END = -1
end

@cenum ASI_GUIDE_DIRECTION::UInt32 begin
    ASI_GUIDE_NORTH = 0
    ASI_GUIDE_SOUTH = 1
    ASI_GUIDE_EAST = 2
    ASI_GUIDE_WEST = 3
end

@cenum ASI_FLIP_STATUS::UInt32 begin
    ASI_FLIP_NONE = 0
    ASI_FLIP_HORIZ = 1
    ASI_FLIP_VERT = 2
    ASI_FLIP_BOTH = 3
end

@cenum ASI_CAMERA_MODE::Int32 begin
    ASI_MODE_NORMAL = 0
    ASI_MODE_TRIG_SOFT_EDGE = 1
    ASI_MODE_TRIG_RISE_EDGE = 2
    ASI_MODE_TRIG_FALL_EDGE = 3
    ASI_MODE_TRIG_SOFT_LEVEL = 4
    ASI_MODE_TRIG_HIGH_LEVEL = 5
    ASI_MODE_TRIG_LOW_LEVEL = 6
    ASI_MODE_END = -1
end

@cenum ASI_TRIG_OUTPUT::Int32 begin
    ASI_TRIG_OUTPUT_PINA = 0
    ASI_TRIG_OUTPUT_PINB = 1
    ASI_TRIG_OUTPUT_NONE = -1
end

const ASI_TRIG_OUTPUT_PIN = ASI_TRIG_OUTPUT

@cenum ASI_ERROR_CODE::UInt32 begin
    ASI_SUCCESS = 0
    ASI_ERROR_INVALID_INDEX = 1
    ASI_ERROR_INVALID_ID = 2
    ASI_ERROR_INVALID_CONTROL_TYPE = 3
    ASI_ERROR_CAMERA_CLOSED = 4
    ASI_ERROR_CAMERA_REMOVED = 5
    ASI_ERROR_INVALID_PATH = 6
    ASI_ERROR_INVALID_FILEFORMAT = 7
    ASI_ERROR_INVALID_SIZE = 8
    ASI_ERROR_INVALID_IMGTYPE = 9
    ASI_ERROR_OUTOF_BOUNDARY = 10
    ASI_ERROR_TIMEOUT = 11
    ASI_ERROR_INVALID_SEQUENCE = 12
    ASI_ERROR_BUFFER_TOO_SMALL = 13
    ASI_ERROR_VIDEO_MODE_ACTIVE = 14
    ASI_ERROR_EXPOSURE_IN_PROGRESS = 15
    ASI_ERROR_GENERAL_ERROR = 16
    ASI_ERROR_INVALID_MODE = 17
    ASI_ERROR_END = 18
end


struct ASIError <: Exception
    code::ASI_ERROR_CODE
end

Base.showerror(io::IO, err::ASIError) = print(io, err.code)


struct ASIWrapperError <: Exception
    message::String
end

Base.showerror(io::IO, err::ASIWrapperError) = print(io, err.message)

@cenum ASI_BOOL::UInt32 begin
    ASI_FALSE = 0
    ASI_TRUE = 1
end

ASI_BOOL(b::Bool) = b ? ASI_TRUE : ASI_FALSE

@cenum ASI_EXPOSURE_STATUS::UInt32 begin
    ASI_EXP_IDLE = 0
    ASI_EXP_WORKING = 1
    ASI_EXP_SUCCESS = 2
    ASI_EXP_FAILED = 3
end


# Structs
# kept mutable for now, has to be checked
# added constructors

mutable struct _ASI_CAMERA_INFO
    Name::NTuple{64, Cchar}
    CameraID::Cint
    MaxHeight::Clong
    MaxWidth::Clong
    IsColorCam::ASI_BOOL
    BayerPattern::ASI_BAYER_PATTERN
    SupportedBins::NTuple{16, Cint}
    SupportedVideoFormat::NTuple{8, ASI_IMG_TYPE}
    PixelSize::Cdouble
    MechanicalShutter::ASI_BOOL
    ST4Port::ASI_BOOL
    IsCoolerCam::ASI_BOOL
    IsUSB3Host::ASI_BOOL
    IsUSB3Camera::ASI_BOOL
    ElecPerADU::Cfloat
    BitDepth::Cint
    IsTriggerCam::ASI_BOOL
    Unused::NTuple{16, UInt8}
end

_ASI_CAMERA_INFO() = _ASI_CAMERA_INFO(
    NTuple{64, Cchar}([0 for i in 1:64]),
    0,0,0,
    ASI_FALSE,
    ASI_BAYER_RG,
    NTuple{16, Cint}([0 for i in 1:16]),
    NTuple{8, ASI_IMG_TYPE}([ASI_IMG_END for i in 1:8]),
    0,
    ASI_FALSE,
    ASI_FALSE,
    ASI_FALSE,
    ASI_FALSE,
    ASI_FALSE,
    1.,
    0,
    ASI_FALSE,
    NTuple{16, UInt8}([0 for i in 1:16])
)

# human-readable type
struct ASI_CAMERA_INFO
    Name::String
    CameraID::Cint
    MaxHeight::Clong
    MaxWidth::Clong
    IsColorCam::ASI_BOOL
    BayerPattern::ASI_BAYER_PATTERN
    SupportedBins::Vector
    SupportedVideoFormat::Vector
    PixelSize::Cdouble
    MechanicalShutter::ASI_BOOL
    ST4Port::ASI_BOOL
    IsCoolerCam::ASI_BOOL
    IsUSB3Host::ASI_BOOL
    IsUSB3Camera::ASI_BOOL
    ElecPerADU::Cfloat
    BitDepth::Cint
    IsTriggerCam::ASI_BOOL
end

ASI_CAMERA_INFO(info::_ASI_CAMERA_INFO) = ASI_CAMERA_INFO(
    split(String([Char(c) for c in info.Name]), "\0")[1],
    info.CameraID,
    info.MaxHeight,
    info.MaxWidth,
    info.IsColorCam,
    info.BayerPattern,
    [i for i in info.SupportedBins if i > 0],
    [i for i in info.SupportedVideoFormat if i > ASI_IMG_END],
    info.PixelSize,
    info.MechanicalShutter,
    info.ST4Port,
    info.IsCoolerCam,
    info.IsUSB3Host,
    info.IsUSB3Camera,
    info.ElecPerADU,
    info.BitDepth,
    info.IsTriggerCam
)


mutable struct _ASI_CONTROL_CAPS
    Name::NTuple{64, Cchar}
    Description::NTuple{128, UInt8}
    MaxValue::Clong
    MinValue::Clong
    DefaultValue::Clong
    IsAutoSupported::ASI_BOOL
    IsWritable::ASI_BOOL
    ControlType::ASI_CONTROL_TYPE
    Unused::NTuple{32, UInt8}
end

_ASI_CONTROL_CAPS() = _ASI_CONTROL_CAPS(
    NTuple{64, Cchar}([0 for i in 1:64]),   # Name
    NTuple{128, Cchar}([0 for i in 1:128]), # Description
    0, 0, 0,    # Max, Min, Default
    ASI_FALSE,  # IsAutoSupported
    ASI_FALSE,  # IsWritable
    ASI_GAIN,   # ControlType; gain corresponds to 0
    NTuple{32, UInt8}([0 for i in 1:32])    # Unused
)

# human-readable type
struct ASI_CONTROL_CAPS
    Name::String
    Description::String
    MaxValue::Clong
    MinValue::Clong
    DefaultValue::Clong
    IsAutoSupported::ASI_BOOL
    IsWritable::ASI_BOOL
    ControlType::ASI_CONTROL_TYPE
end

ASI_CONTROL_CAPS(control_caps::_ASI_CONTROL_CAPS) = ASI_CONTROL_CAPS(
    split(String([Char(c) for c in control_caps.Name]), "\0")[1],   # Name
    split(String([Char(c) for c in control_caps.Description]), "\0")[1], # Description
    control_caps.MaxValue, control_caps.MinValue, control_caps.DefaultValue,    # Max, Min, Default
    control_caps.IsAutoSupported,  # IsAutoSupported
    control_caps.IsWritable,       # IsWritable
    control_caps.ControlType       # ControlType; gain corresponds to 0
)

# const ASI_CONTROL_CAPS = _ASI_CONTROL_CAPS

mutable struct _ASI_ID
    id::NTuple{8, Cuchar}
end

_ASI_ID() = _ASI_ID(NTuple{8, Cuchar}(zeros(Cuchar, 10)))

const ASI_ID = _ASI_ID
const ASI_SN = ASI_ID

mutable struct _ASI_SUPPORTED_MODE
    SupportedCameraModes::NTuple{16, ASI_CAMERA_MODE}
end

_ASI_SUPPORTED_MODE() = _ASI_SUPPORTED_MODE(
    NTuple{16, ASI_CAMERA_MODE}(fill(ASI_MODE_END, 16))
)

const ASI_SUPPORTED_MODE = _ASI_SUPPORTED_MODE
