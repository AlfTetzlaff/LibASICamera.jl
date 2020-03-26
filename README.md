# LibASICamera.jl

A julia wrapper for the ASI Camera interface.

Please note that this is my first julia project, so suggestions for improvements are welcome!

## Installation

To install this package, spin um julia, hit the ']' key to enter the package manager, the type:

```
add LibASICamera
```

The ZWO ASI SDK will be downloaded in the background. Please note that (on Linux) you have to install the udev rules for the cameras which you find in the [SDK](https://astronomy-imaging-camera.com/software-drivers).

In your terminal, run:

```
sudo install /path/to/asi.rules /lib/udev/rules.d
```

The wrapper was written and tested on Linux. In principle it should work on Windows and Mac as well, but I couldn't test it so far.

You can then connect the camera and run partial tests on functionality by typing in the package manager:

```
test LibASICamera
```

## Usage

Get the connected devices and open them:

```
devices = get_connected_devices()
cam = devices[1]
```

Query information about the camera, like resolution or pixel size:

```
@show get_camera_property(cam)
#or
@show cam.info
```

Get the parameters, which can be controlled or queried by the user, like gain, exposure or temperature:

```
@show get_control_caps(cam)
# or
@show cam.control_caps
```

Get and set a control value, for some, special shorthand functions exist:

```
value, is_auto_controlled = get_control_value(cam, ASI_GAIN)
set_control_value(cam, ASI_GAIN, value, is_auto_controlled)
set_gain(cam, value)
get_temperature(cam)
```

## Still image

Take a still image:

```
set_gain(cam, 30)  # example values
set_exposure(cam, 500)
img = capture_still(cam)
```

## Video

Take a video using Makie:

```
using LibASICamera
using Makie

devices = get_connected_devices()
cam = devices[1]
set_gain(cam, 30, true)  # example values
set_exposure(cam, 500, true)


function capture_video(cam::ASICamera)
    # Camera stuff setup
    width, height, binning, img_type = get_roi_format(cam)
    buffer = allocate_buffer(width, height, img_type)

    # Makie scene setup
    colorrange = img_type == ASI_IMG_RAW16 ? 2^16-1 : 255
    scene = Scene()
    img = image!(scene, buffer, show_axis = false, scale_plot = false,          colorrange=(0,colorrange))[end]
    display(scene)

    function video_loop()
        err = ASI_SUCCESS
        while isopen(scene) && err == ASI_SUCCESS
            err = get_video_data!(cam, buffer, 5000)
            img[1] = buffer[end:-1:1, :]  # for some reason we have to flip x
            yield()
        end
        println(err)
    end

    start_video(cam)
    video_loop()
    stop_video(cam)
end

@async t = capture_video(cam)

stop_video(cam)

# Always close the camera at the end
close_camera(cam)
```

The above example runs the video capturing asynchronously in the main _thread_. You might notice that the REPL input gets sluggish under certain circumstances (exposure times, bandwidth settings and depending on your hardware). This can be resolved by moving the video capturing to another _process_ using Distributed.jl:

```
using Distributed
addprocs(1)
@everywhere using LibASICamera
@everywhere using Makie


@everywhere function capture_video(cam::ASICamera)
    ...
end

@everywhere devices = get_connected_devices()
@everywhere cam = devices[1]

# set gain and exposure from worker #2
remotecall_fetch(set_gain, 2, cam, 30, true)
remotecall_fetch(set_exposure, 2, cam, 500, true)

# launches capture in another process :-)
remotecall(capture_video, 2, cam)

# note that the values for worker 1 and 2 may differ, use only one!
v1 = remotecall_fetch(get_control_value, 1, cam, ASI_EXPOSURE)
v2 = remotecall_fetch(get_control_value, 2, cam, ASI_EXPOSURE)

v1 == v2

# Always close the camera at the end
close_camera(cam)
```

If you encounter any issues, don't hesitate to ask!
