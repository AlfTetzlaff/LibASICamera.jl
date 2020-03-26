# version = v"1.14.1119"
version = v"1.14.1227"
deps_dir = dirname(@__FILE__)
par_dir  = abspath(joinpath(deps_dir, ".."))
sdk_dir  = joinpath(deps_dir, "sdk_v$version")
lib_target_dir = joinpath(par_dir, "lib")
lib_dir  = joinpath(sdk_dir, "lib")
lib_x64_dir = joinpath(lib_dir, "x64")
lib_x86_dir = joinpath(lib_dir, "x86")
lib_mac_dir = joinpath(lib_dir, "mac")


if Sys.islinux() || Sys.isapple()
    sdk_file = joinpath(deps_dir, "ASI_linux_mac_SDK_V$version.tar.bz2")
    if !isfile(sdk_file)
        @info "Downloading ASI_linux_mac_SDK_V$version.tar.bz2 from astronomy-imaging-camera.com (ZWO)"
        download("https://astronomy-imaging-camera.com/software/ASI_linux_mac_SDK_V$version.tar.bz2", sdk_file)
    end
elseif Sys.iswindows()
    sdk_file = joinpath(deps_dir, "ASI_Windows_SDK_V$version.zip")
    if !isfile(sdk_file)
        @info "Downloading ASI_Windows_SDK_V$version.zip from astronomy-imaging-camera.com (ZWO)"
        download("https://astronomy-imaging-camera.com/software/ASI_Windows_SDK_V$version.zip", sdk_file)
    end
end


if !isdir(sdk_dir) mkdir(sdk_dir) end
if !isdir(lib_target_dir) mkdir(lib_target_dir) end

#extract
if isfile(sdk_file)
    if Sys.isunix()
        unpack_cmd = `tar xjf $sdk_file --directory=$sdk_dir` end
    if Sys.iswindows()
        if isdefined(Base, :LIBEXECDIR)
          const exe7z = joinpath(Sys.BINDIR, Base.LIBEXECDIR, "7z.exe")
        else
          const exe7z = joinpath(Sys.BINDIR, "7z.exe")
        end
        unpack_cmd = pipeline(`$exe7z x $sdk_file -y -so`,`$exe7z x -si -y -ttar -o$sdk_dir`)
    end
    run(unpack_cmd)
end


# copy extracted library file to lib subfolder
if Sys.islinux()
    mv(joinpath(lib_dir, "asi.rules"), joinpath(deps_dir, "..", "asi.rules"), force=true)
    if isa(1, Int64)
        source_file = joinpath(lib_x64_dir, "libASICamera2.so.$version")
        target_file = joinpath(lib_target_dir, "libASICamera2.so")
        mv(source_file, target_file, force=true)
    else
        source_file = joinpath(lib_x86_dir, "libASICamera2.so.$version")
        target_file = joinpath(lib_target_dir, "libASICamera2.so")
        mv(source_file, target_file, force=true)
    end

elseif Sys.isapple()
    source_file = joinpath(lib_mac_dir, "libASICamera2.dylib.$version")
    target_file = joinpath(lib_target_dir, "libASICamera2.dylib")
    mv(source_file, target_file, force=true)

elseif Sys.iswindows()
    if isa(1, Int64)
        source_file = joinpath(lib_x64_dir, "ASICamera2.dll")
        target_file = joinpath(lib_target_dir, "ASICamera2.dll")
        mv(source_file, target_file, force=true)
    else
        source_file = joinpath(lib_x86_dir, "ASICamera2.dll")
        target_file = joinpath(lib_target_dir, "ASICamera2.dll")
        mv(source_file, target_file, force=true)
    end
end

# cleanup
rm(sdk_file)
rm(sdk_dir, recursive=true)

if Sys.isunix()
    rules_file = joinpath(par_dir, "asi.rules")
    println("\nPlease install the udev rules for the camera device, so that you can
    access it without root privileges. To install the rules, run
    'sudo install $rules_file /lib/udev/rules.d'\n")
end
