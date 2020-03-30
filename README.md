# <img src="/docs/LibASICamera_logo.svg?raw=true&sanitize=true" width="5%"> LibASICamera.jl

[![](https://img.shields.io/badge/docs-dev-blue)](https://alftetzlaff.github.io/LibASICamera.jl/dev/)
[![](https://img.shields.io/badge/ZWO-ASI-critical)](https://astronomy-imaging-camera.com/)

A julia wrapper for the ASI Camera interface.

Please note that this is my first julia project, so suggestions for improvements are welcome!

## Installation

To install this package, spin up julia, hit the ']' key to enter the package manager, then type:

```julia
pkg> add LibASICamera  # works, as soon as this package is registered
#or
pkg> add https://github.com/AlfTetzlaff/LibASICamera.jl
```

### Linux specific steps

The ZWO ASI SDK will be downloaded in the background. Please note that (on Linux) you have to install the udev rules for the cameras. Run

```julia
pkg> build -v LibASICamera
```

to get the command to run in order to install the udev rules.

Or in your terminal, run:

```
sudo install /path/to/asi.rules /lib/udev/rules.d
```

### Windows specific steps

Download and install the camera driver from [here](https://astronomy-imaging-camera.com/software-drivers).

### Test

The wrapper was written and tested on Linux. In principle it should work on Windows and Mac as well, but I couldn't test it so far.

You can then connect the camera and run partial tests on functionality by typing in the package manager:

```julia
pkg> test LibASICamera
```

## Usage

Get the connected devices and open them:

```julia
devices = get_connected_devices()
cam = devices[1]
```

Query information about the camera, like resolution or pixel size:

```julia
@show get_camera_property(cam)
#or
@show cam.info
```

Get the parameters, which can be controlled or queried by the user, like gain, exposure or temperature:

```julia
@show get_control_caps(cam)
# or
@show cam.control_caps
```

Get and set a control value, for some, special shorthand functions exist:

```julia
value, is_auto_controlled = get_control_value(cam, ASI_GAIN)
set_control_value(cam, ASI_GAIN, value, is_auto_controlled)
set_gain(cam, value)
get_temperature(cam)
```

## Still image

Take a still image:

```julia
set_gain(cam, 30)  # example values
set_exposure(cam, 500)
img = capture_still(cam)
```

## Video

Take a video using Makie:

```julia
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
    img = image!(scene, buffer, show_axis = false, scale_plot = false, colorrange=(0,colorrange))[end]
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

```julia
using Distributed
addprocs(1)
nprocs()

#%%
@everywhere using LibASICamera
@everywhere using Makie

#%%
@everywhere function main()
    cam = get_connected_devices()[1]
    set_exposure(cam, 500, true)
    set_gain(cam, 30)
    set_control_value(cam, ASI_BANDWIDTHOVERLOAD, 90)
    set_control_value(cam, ASI_HIGH_SPEED_MODE, false)
    set_roi_format(cam, 1280, 960, 1, ASI_IMG_RAW8)
    # set_roi_format(cam, 640, 480, 2, ASI_IMG_RAW8)
    # set_roi_format(cam, 640, 480, 1, ASI_IMG_RAW8)
    # set_roi_format(cam, 320, 240, 1, ASI_IMG_RAW8)
    # set_roi_format(cam, 168, 128, 1, ASI_IMG_RAW8)

    function capture_video(cam::ASICamera)
        # Camera stuff setup
        width, height, binning, img_type = get_roi_format(cam)
        buffer = allocate_buffer(width, height, img_type)

        # Makie scene setup
        colorrange = img_type == ASI_IMG_RAW16 ? 2^16-1 : 255
        scene = Scene()
        img = image!(scene, buffer, show_axis = false, scale_plot = false, colorrange=(0,colorrange))[end]
        t = text!(scene, "0 FPS", color=:yellow, position=(width, height), align=(:top, :right), textsize=Int(height/16))
        display(scene)

        function video_loop(cam, buffer, img, t)
            err = ASI_SUCCESS
            while isopen(scene) && err == ASI_SUCCESS
                t0 = time_ns()
                err = get_video_data!(cam, buffer, 5000)
                img[1] = buffer[end:-1:1, :]  # for some reason we have to flip x
                t1 = time_ns()
                t[end][1] = string(round(1. /(Float64(t1-t0)/1E9), digits=1), " FPS")
                yield()
            end
            println(err)
        end

        start_video(cam)
        video_loop(cam, buffer, img, t)
        stop_video(cam)
    end

    capture_video(cam)
    close_camera(cam)
end

remotecall(main, 2)
```

If you encounter any issues, don't hesitate to ask!
