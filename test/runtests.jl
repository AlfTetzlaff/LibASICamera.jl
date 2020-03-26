using Test
using LibASICamera

devices = []
try
    devices = get_connected_devices()
catch err
    println("\nConnect the camera for testing and make sure you can access the camera
    without being root by calling \"sudo install asi.rules /lib/udev/rules.d\"
    from the lib subdir of the SDK and then relogging / rebooting.\n")
    rethrow(err)
end

@testset "$(cam.info.Name)" for cam in devices
    control_caps = get_control_caps(cam)
    @testset "set/get $(cap.Name)" for cap in control_caps
        default = cap.DefaultValue
        control_type = cap.ControlType
        if cap.IsWritable == ASI_TRUE
            set_control_value(cam, control_type, default, auto = false)
            @test default == get_control_value(cam, control_type)[1]
        end
    end

    @testset "Capture Still" begin
        @test isa(capture_still(cam), Array)
    end

    close_camera(cam)
end
