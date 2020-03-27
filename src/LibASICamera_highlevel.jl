include(joinpath(@__DIR__, "LibASICamera_types.jl"))
include(joinpath(@__DIR__, "LibASICamera_ccalls.jl"))

"""
    ASICamera

The struct which contains information about the camera.
Has fields .info and .control_caps.
"""
struct ASICamera
    info::ASI_CAMERA_INFO
    control_caps::Vector{ASI_CONTROL_CAPS}
end


"""
    allocate_buffer(width::Integer, height::Integer, img_type::ASI_IMG_TYPE)

Allocates an image buffer for the camera to write to.

# Args:
    width: Image width
    height: Image height
    img_type: One of
        -ASI_IMG_RAW8
        -ASI_IMG_Y8
        -ASI_IMG_RAW16
        -ASI_IMG_RAW24

# Returns:
    A zero-initialized array of the appropriate shape.

# Throws:
    ASIWrapperError if an unsupported image type is given.
"""
function allocate_buffer(width::Integer, height::Integer, img_type::ASI_IMG_TYPE)
    if img_type==ASI_IMG_RAW8 || img_type==ASI_IMG_Y8
        return zeros(UInt8, width, height)
    elseif img_type==ASI_IMG_RAW16
        return zeros(UInt16, width, height)
    elseif img_type==ASI_IMG_RAW24
        return zeros(UInt8, width, height, 3)
    else
        throw(ASIWrapperError("Image type $img_type not implemented."))
    end
end

# This allows to use an ellipsis: allocate_buffer(get_roi_format(cam)...)
allocate_buffer(width::Integer, height::Integer, unused, img_type::ASI_IMG_TYPE) =
    allocate_buffer(width, height, img_type)


"""
    get_num_connected_cameras()

This function returns the count of connected cameras and should be called first.
"""
get_num_connected_cameras() = ASIGetNumOfConnectedCameras()


"""
    get_camera_property(id::Integer)

Fetches the camera properties for a given ID.

# Args:
    id: Camera id

# Returns:
    ASI_CAMERA_INFO object

# Throws:
    ASIError in case of failure
"""
function get_camera_property(id::Integer)
    camera_info = _ASI_CAMERA_INFO()
    err = ASIGetCameraProperty(camera_info, id)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
    return ASI_CAMERA_INFO(camera_info) # convert to human-readable type
end

get_camera_property(cam::ASICamera) = get_camera_property(cam.info.CameraID)


"""
    open_camera(id::Integer)

Opens the ASI camera connection.

Open the camera before any interaction with the camera,
this will not affect the camera which is capturing.
Then you must call init_camera() to perform any actions.

# Args:
    id: Camera ID

# Throws:
	ASIError
"""
function open_camera(id::Integer)
    err = ASIOpenCamera(id)
    if err != ASI_SUCCESS
        print("[ERROR] Could not connect to camera. Make sure you can access the camera without being root by calling
        \"sudo install asi.rules /lib/udev/rules.d\" from the lib subdir of the SDK
        and then relogging / rebooting.")
        throw(ASIError(err))
    end
end

open_camera(cam::ASICamera) = open_camera(cam.info.CameraID)


"""
    init_camera(id::Integer)

Initialize the camera. Needs to be called before capturing any data.

# Args:
    id: Camera id

# Throws:
    ASIError
"""
function init_camera(id::Integer)
    err = ASIInitCamera(id)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
end

init_camera(cam::ASICamera) = init_camera(cam.info.CameraID)


"""
    close_camera(id::Integer)

Closes the ASI camera connection.

# Args:
    id: Camera id

# Throws:
	ASIError
"""
function close_camera(id::Integer)
    err = ASICloseCamera(id)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
end

close_camera(cam::ASICamera) = close_camera(cam.info.CameraID)


"""
    get_control_caps(id::Integer)

Returns the control properties available for this camera.

The camera needs to be open.

# Args:
    id: Camera id

# Returns:
    Vector of ASI_CONTROL_CAPS structs.

# Throws:
    ASIError
"""
function get_control_caps(id::Integer)
    num_controls = Ref{Cint}(0)

    err = ASIGetNumOfControls(id, num_controls)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end

    control_caps = Vector{ASI_CONTROL_CAPS}(undef, num_controls.x)

    for i in 1:num_controls.x
        cap = _ASI_CONTROL_CAPS()
        err = ASIGetControlCaps(id, i-1, cap)
        if err != ASI_SUCCESS
            throw(ASIError(err))
        end
        control_caps[i] = ASI_CONTROL_CAPS(cap) # convert to human-readable type
    end

    return control_caps
end

get_control_caps(cam::ASICamera) = get_control_caps(cam.info.CameraID)


"""
    get_connected_devices()

Returns a list of the connected devices.
"""
function get_connected_devices()
    num_cameras = get_num_connected_cameras()
    if num_cameras == 0
        throw(ASIWrapperError("No cameras found."))
    end

    cameras = Vector{ASICamera}(undef, num_cameras)
    for i in 0:num_cameras-1
        open_camera(i)
        init_camera(i)
        info = get_camera_property(i)
        control_caps = get_control_caps(i)
        cameras[i+1] = ASICamera(info, control_caps)
    end
    return cameras
end


"""
    get_control_value(id::Integer, control_type::ASI_CONTROL_TYPE)

Fetches the current setting of the control value, e.g. exposure or gain.

# Args:
    id: Camera id
    control_type: The control type to fetch, e.g. exposure or gain.

# Returns:
    A tuple (value, is_auto)

# Throws:
    ASIError
"""
function get_control_value(id::Integer, control_type::ASI_CONTROL_TYPE)
    value = Ref{Clong}(0)
    auto  = Ref{Bool}(false)
    err = ASIGetControlValue(id, control_type, value, auto)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
    return (value.x, auto.x)
end

get_control_value(cam::ASICamera, control_type::ASI_CONTROL_TYPE) = get_control_value(cam.info.CameraID, control_type)


"""
    set_control_value(id::Integer, control_type::ASI_CONTROL_TYPE, value, auto::Bool=false)

Sets a control (e.g. exposure) to the given value. Automatically sets the
minimum or maximum if the given value is out of bounds.

# Args:
    id: Camera id
    control_type: The control type to set, e.g. exposure or gain.
    value: The value to which the control is set.
    auto: Whether or not the control should be automatically set.
        Check if this is supported for the given control beforehand.

# Throws:
    ASIError
"""
function set_control_value(id::Integer, control_type::ASI_CONTROL_TYPE, value, auto::Bool=false)
    err = ASISetControlValue(id, control_type, value, auto)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
end

set_control_value(cam::ASICamera, control_type::ASI_CONTROL_TYPE, value, auto::Bool=false) = set_control_value(cam.info.CameraID, control_type, value, auto)

set_gain(id, gain, auto=false)              = set_control_value(id, ASI_GAIN, gain, auto)
set_exposure(id, exposure_μs, auto=false)   = set_control_value(id, ASI_EXPOSURE, exposure_μs, auto)
set_gamma(id, gamma, auto=false)            = set_control_value(id, ASI_GAMMA, gamma, auto)
set_bandwidth(id, bandwidth, auto=false)    = set_control_value(id, ASI_BANDWIDTHOVERLOAD, bandwidth, auto)
set_flip(id, flip)                              = set_control_value(id, ASI_FLIP, flip)
set_autoexp_max_gain(id, val)                   = set_control_value(id, ASI_AUTO_MAX_GAIN, val)
set_autoexp_max_exp(id, exposure_ms)            = set_control_value(id, ASI_AUTO_MAX_EXP, exposure_ms)
set_autoexp_target_brightness(id, brightness)   = set_control_value(id, ASI_AUTO_MAX_BRIGHTNESS, brightness)
set_highspeed_mode(id, active)                  = set_control_value(id, ASI_HIGH_SPEED_MODE, active)
# ...

get_temperature(id)                             = get_control_value(id, ASI_TEMPERATURE)[1] * 0.1

"""
    get_status(id::Integer)

Returns the status of all camera parameters.
"""
function get_status(id::Integer)
    control_caps = get_control_caps(id)
    ret = []
    for t in control_caps
        push!(ret, (t.Name, get_control_value(id, t.ControlType)[1]))
    end
    return ret
end

get_status(cam::ASICamera) = get_status(cam.info.CameraID)


"""
    set_roi_format(id::Integer, width, height, binning, img_type::ASI_IMG_TYPE)

Sets the region of interest (roi). Do so before capturing.

The width and height are the values *after* binning, i.e. you need to set the
width to 640 and the height to 480 if you want to run at 640x480 @ BIN2.

ASI120's data size must be a multiple of 1024 which means width*height%1024==0.

# Args:
    id: Camera id
    width: ROI width
    height: ROI height
    binning: The binning mode; 2 means to read out 2x2 pixels together. Check
        which binning values are supported in the ASI_CAMERA_INFO struct of the
        camera struct or by calling get_camera_property(id).

# Throws:
    ASIError
"""
function set_roi_format(id::Integer, width, height, binning, img_type::ASI_IMG_TYPE)
    if width%8 != 0
        throw("Width must be a multiple of 8.")
    end
    if height%2 != 0
        throw("Height must be a multiple of 2.")
    end
    if (width*height)%1024 != 0 && get_camera_property(id).Name in ["ZWO ASI 120MM", "ZWO ASI 120MC"]
        throw("Width times height must be a multiple of 2.")
    end
    err = ASISetROIFormat(id, width, height, binning, img_type)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
end

set_roi_format(cam::ASICamera, width, height, binning, img_type::ASI_IMG_TYPE) = set_roi_format(cam.info.CameraID, width, height, binning, img_type)


"""
    get_roi_format(id::Integer)

Fetches the current region of interest settings.
"""
function get_roi_format(id::Integer)
    width = Ref{Cint}(0)
    height = Ref{Cint}(0)
    binning = Ref{Cint}(false)
    img_type = Ref{ASI_IMG_TYPE}(ASI_IMG_RAW8)
    err = ASIGetROIFormat(id, width, height, binning, img_type)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
    return (width.x, height.x, binning.x, img_type.x)
end

get_roi_format(cam::ASICamera) = get_roi_format(cam.info.CameraID)


"""
    set_roi_start(id::Integer, startx, starty)

Sets the position of the top-left corner of the region of interest.

You can call this while the camera is streaming to move the ROI. By default,
the ROI will be centered. In binned mode, the start values are relative to the
binned sensor size.

# Throws:
    ASIError
"""
function set_roi_start(id::Integer, startx, starty)
    err = ASISetStartPos(id, startx, starty)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
end

set_roi_start(cam::ASICamera, startx, starty) = set_roi_start(cam.info.CameraID, startx, starty)


"""
    get_roi_start(id::Integer)

Returns the region of interest start position (start_x, start_y).
"""
function get_roi_start(id::Integer)
    startx = Ref{Cint}(0)
    starty = Ref{Cint}(0)
    err = ASIGGetStartPos(id, startx, starty)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
    return (startx[], starty[])
end

get_roi_start(cam::ASICamera) = get_roi_start(cam.info.CameraID)


"""
    get_dropped_frames(id::Integer)

Returns the number of dropped frames.

Frames are dropped when the USB is bandwidth is low or the
harddisk write speed is slow. The count is reset to 0 after capturing stops.
"""
function get_dropped_frames(id::Integer)
    dropped_frames = Ref{Cint}(0)
    err = ASIGetDroppedFrames(id, dropped_frames)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
end

get_dropped_frames(cam::ASICamera) = get_dropped_frames(cam.info.CameraID)


"""
"""
function enable_dark_subtract(id::Integer, path)
    err = ASIEnableDarkSubtract(id, path)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
end

enable_dark_subtract(cam::ASICamera) = enable_dark_subtract(cam.info.CameraID)


"""
"""
function disable_dark_subtract(id::Integer)
    err = ASIDisableDarkSubtract(id)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
end

disable_dark_subtract(cam::ASICamera) = disable_dark_subtract(cam.info.CameraID)


"""
    start_video(id::Integer)

Start video capture.

# Throws:
    ASIError
"""
function start_video(id::Integer)
    err = ASIStartVideoCapture(id)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
end

start_video(cam::ASICamera) = start_video(cam.info.CameraID)


"""
    stop_video(id::Integer)

Stops a running video capture.

# Throws:
    ASIError
"""
function stop_video(id::Integer)
    err = ASIStopVideoCapture(id)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
end

stop_video(cam::ASICamera) = stop_video(cam.info.CameraID)


"""
    get_video_data!(id::Integer, buffer, timeout_ms)

Writes a video frame to the given buffer. Make sure the buffer is large
enough to fit the frame. Call this as fast as possible in a loop and check
whether the return value equals ASI_SUCCESS.

# Args:
    id: Camera id
    buffer: A buffer to write the video frame to.
    timeout_ms: Time to wait for a frame. Recommendation: 2 * exposure_μs + 500 ms <- inconsistent units?!

# Returns:
    An ASI_ERROR_CODE, which should be ASI_SUCCESS.
"""
function get_video_data!(id::Integer, buffer, timeout_ms=500)
    return ASIGetVideoData(id, buffer, sizeof(buffer), Int32(round(timeout_ms)))
end

get_video_data!(cam::ASICamera, buffer, timeout_ms) = get_video_data!(cam.info.CameraID, buffer, timeout_ms)


"""
    pulse_guide_on(id::Integer, direction::ASI_GUIDE_DIRECTION)

Activates the pulse guide in the given direction.

# Args:
    id: Camera id
    direction: Guiding direction; call 'instances(ASI_GUIDE_DIRECTION)'

# Throws:
    ASIError
"""
function pulse_guide_on(id::Integer, direction::ASI_GUIDE_DIRECTION)
    err = ASIPulseGuideOn(id, direction)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
end

pulse_guide_on(cam::ASICamera) = pulse_guide_on(cam.info.CameraID)


"""
    pulse_guide_off(id::Integer, direction::ASI_GUIDE_DIRECTION)

Deactivates the pulse guide in the given direction.

# Args:
    id: Camera id
    direction: Guiding direction; call 'instances(ASI_GUIDE_DIRECTION)' for options.

# Throws:
    ASIError
"""
function pulse_guide_off(id::Integer, direction::ASI_GUIDE_DIRECTION)
    err = ASIPulseGuideOff(id, direction)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
end

pulse_guide_off(cam::ASICamera) = pulse_guide_off(cam.info.CameraID)


"""
    start_exposure(id::Integer, is_dark=false)

Starts an exposure. All relevant parameters (exposure time, gain) have to be
set beforehand by calling set_control_value(...) or e.g. set_gain(...).
"""
function start_exposure(id::Integer, is_dark=false)
    err = ASIStartExposure(id, is_dark)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
end

start_exposure(cam::ASICamera, is_dark=false) = start_exposure(cam.info.CameraID, is_dark)


"""
    stop_exposure(id::Integer)

Stops an ongoing exposure.
"""
function stop_exposure(id::Integer)
    err = ASIStopExposure(id)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
end

stop_exposure(cam::ASICamera) = stop_exposure(cam.info.CameraID)


"""
    get_exp_status(id::Integer)

Returns the status of an ongoing exposure.
See 'instances(ASI_EXP_STATUS)'.

# Throws:
    ASIError
"""
function get_exp_status(id::Integer)
    status = Ref{ASI_EXPOSURE_STATUS}(ASI_EXP_IDLE)
    err = ASIGetExpStatus(id, status)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
    return status[]
end

get_exp_status(cam::ASICamera) = get_exp_status(cam.info.CameraID)


"""
    get_data_after_exp!(id::Integer, buffer)

Fetches the data after a successful exposure and writes it into buffer.
"""
function get_data_after_exp!(id::Integer, buffer)
    err = ASIGetDataAfterExp(id, buffer, sizeof(buffer))
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
end

get_data_after_exp!(cam::ASICamera, buffer) = get_data_after_exp!(cam.info.CameraID, buffer)


"""
    get_id(id::Integer)

Returns the camera id stored in flash, only available for USB3 cameras.
"""
function get_id(id::Integer)
    camera_id = ASI_ID()
    err = ASIGetID(id, camera_id)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
end

get_id(cam::ASICamera) = get_id(cam.info.CameraID)


"""
    capture_still(id::Integer)

Captures a still image. You have to set gain, exposure etc. beforehand using
set_control_value(...).

# Returns:
    An array containing the image.

# Throws:
    ASIWrapperError if the image format is not supported by the wrapper, or
    ASIError in other unfortunate cases
"""
function capture_still(id::Integer)
    exposure_μs, _ = get_control_value(id, ASI_EXPOSURE)
    width, height, binning, img_type = get_roi_format(id)

    buffer = allocate_buffer(width, height, img_type)

    start_exposure(id, false)
    sleep(0.05)
    # option 2: wait almost the entire exposure time instead of polling
    # sleep(exposure_μs/1000*0.9)

    while get_exp_status(id) == ASI_EXP_WORKING
        sleep(0.01)
    end

    if get_exp_status(id) == ASI_EXP_SUCCESS
        get_data_after_exp!(id, buffer)
        return buffer[end:-1:1, :]
    else
        throw("Exposure failed")
    end
end

capture_still(cam::ASICamera) = capture_still(cam.info.CameraID)


"""
    get_gain_offset(id::Integer)

Get the presets for offset and gain values at different "sweet spots".

# Args:
    id: Camera id

# Returns:
    A dictionary containing:
        1. The offset at highest dynamic range
        2. The offset at unity gain
        3. The gain with lowest readout noise
        4. The offset with lowest readout noise

# Throws:
    ASIError
"""
function get_gain_offset(id::Integer)
    offset_highest_dr = Ref{Cint}(0)  # Offset at highest dynamic range
    offset_unity_gain = Ref{Cint}(0)  # Offset at unity gain
    gain_lowest_rn    = Ref{Cint}(0)  # Gain at lowest readout noise
    offset_lowest_rn  = Ref{Cint}(0)  # Offset at lowest readout noise

    err = ASIGetGainOffset(id, offset_highest_dr, offset_unity_gain, gain_lowest_rn, offset_lowest_rn)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end

    return Dict(["offset_highest_dr" => offset_highest_dr[],
                 "offset_unity_gain" => offset_unity_gain[],
                 "gain_lowest_rn" => gain_lowest_rn[],
                 "offset_lowest_rn" => offset_lowest_rn[]])
end

get_gain_offset(cam::ASICamera) = get_gain_offset(cam.info.CameraID)


"""
    get_sdk_version()

Returns the SDK version.
"""
function get_sdk_version()
    return unsafe_string(ASIGetSDKVersion())
end


"""
    get_supported_modes(id::Integer)

Returns the supported camera modes, only need to call when the
IsTriggerCam in the CameraInfo is true.

# Throws:
    ASIError
"""
function get_supported_modes(id::Integer)
    supported_modes = ASI_SUPPORTED_MODE()

    err = ASIGetCameraSupportMode(id, supported_modes)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end

    return [m for m in supported_modes.SupportedCameraModes if m > ASI_MODE_END]
end

get_supported_modes(cam::ASICamera) = get_supported_modes(cam.info.CameraID)


"""
    get_camera_mode(id::Integer)

Get the current camera mode, only needed to call when the IsTriggerCam
in the CameraInfo is true.
"""
function get_camera_mode(id::Integer)
    mode = Ref{ASI_CAMERA_MODE}(ASI_MODE_END)

    err = ASIGetCameraMode(id, mode)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end

    return mode[]
end

get_camera_mode(cam::ASICamera) = get_camera_mode(cam.info.CameraID)


"""
    set_camera_mode(id::Integer, mode::ASI_CAMERA_MODE)

Set the camera mode, only needed to call when the IsTriggerCam
in the CameraInfo is true.
"""
function set_camera_mode(id::Integer, mode::ASI_CAMERA_MODE)
    err = ASISetCameraMode(id, mode)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
end

set_camera_mode(cam::ASICamera) = set_camera_mode(cam.info.CameraID)


"""
    send_soft_trigger(id::Integer, start::ASI_BOOL)

From original docs: Send a softTrigger. For edge trigger, it only need to set
true which means send a rising trigger to start exposure. For level trigger,
it need to set true first means start exposure, and set false means stop
exposure. Only needed to call when the IsTriggerCam in the CameraInfo is true.
"""
function send_soft_trigger(id::Integer, start::ASI_BOOL)
    err = ASISendSoftTrigger(id, start)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
end

send_soft_trigger(cam::ASICamera) = send_soft_trigger(cam.info.CameraID)


"""
    get_serial_number(id::Integer)

Returns the camera serial number.
"""
function get_serial_number(id::Integer)
    sn = ASI_SN()

    err = ASIGetSerialNumber(id, sn)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end

    return unsafe_string(sn.id)
end

get_serial_number(cam::ASICamera) = get_serial_number(cam.info.CameraID)


"""
    set_trigger_output_config(id::Integer, pin::ASI_TRIG_OUTPUT_PIN, high::ASI_BOOL, delay, duration)

Configure the output pin (A or B) of Trigger port. If duration <= 0,
this output pin will be closed. Only need to call when the IsTriggerCam
in the CameraInfo is true.

# Args:
    id: Camera id
    pin: Select the pin for output
    high: If true, the selected pin will output a high level as a signal
					when it is effective.
    delay: The delay between the camera receiving a trigger signal and the
            output of the valid level. From 0 μs - 2,000,000,000 μs.
    duration: The duration of the valid level output. Same range as delay.

"""
function set_trigger_output_config(id::Integer, pin::ASI_TRIG_OUTPUT_PIN, high::ASI_BOOL, delay_μs, duration_μs)
    err = ASISetTriggerOutputIOConf(id, pin, high, delay_μs, duration_μs)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end
end

set_trigger_output_config(cam::ASICamera) = set_trigger_output_config(cam.info.CameraID)


"""
    get_trigger_output_config(id::Integer)

Get the output pin configuration, only needed to call when the IsTriggerCam
in the CameraInfo is true.
"""
function get_trigger_output_config(id::Integer)
    pin = ASI_TRIG_OUTPUT_NONE
    high = ASI_FALSE
    delay = Ref{Clong}(0)
    duration = Ref{Clong}(0)

    err = ASIGetTriggerOutputIOConf(id, pin, high, delay, duration)
    if err != ASI_SUCCESS
        throw(ASIError(err))
    end

    return Dict(["pin" => pin,
                 "high" => high,
                 "delay" => delay,
                 "duration" => duration])
end

get_trigger_output_config(cam::ASICamera) = get_trigger_output_config(cam.info.CameraID)


# """
#     capture_video(id)
#
# Starts capturing a video in a while loop, displaying it in a Makie scene.
#
# Args:
#     id: Camera object or int
#
# Throws:
#     An error when the camera returns an image type which is unsupported by this package.
# """
# function capture_video(id)
#     # Camera stuff setup
#     exposure_μs, _ = get_control_value(id, ASI_EXPOSURE)
#     width, height, binning, img_type = get_roi_format(id)
#
#     buffer = allocate_buffer(width, height, img_type)
#
#     # Makie scene setup
#     scene = Scene() #resolution = (size(buffer,2),size(buffer,1)))
#     im = image!(scene, buffer, show_axis = false, scale_plot = false, colorrange=(0,255))[end]
#     display(scene)
#
#     function video_loop()
#         while isopen(scene)
#             get_video_data!(cam, buffer, 0.2*exposure_μs+500)
#             im[1] = buffer[end:-1:1, :]  # flip x axis for some reason...
#             yield()
#         end
#     end
#
#     start_video(id)
#
#     try
#         video_loop()
#     catch err
#         rethrow(err)
#     finally
#         stop_video(id)
#     end
#
#     return nothing
# end
#
# capture_video(cam::ASICamera, callback::Function) = capture_video(cam.info.CameraID, callback)
