version = "1.36"
url = "https://dl.zwoastro.com/software?app=DeveloperCameraSdk&platform=linux&region=Overseas"
deps_dir = dirname(@__FILE__)
par_dir  = abspath(joinpath(deps_dir, ".."))
lib_target_dir = joinpath(par_dir, "lib")


println("Downloading ASI SDK v$version")
# file = Downloads.download("https://dl.zwoastro.com/software?app=DeveloperCameraSdk&platform=windows86&region=Overseas")

if Sys.isunix()
    run(`curl -L "$url" -o $deps_dir/ASI_SDK.zip`)
    file = joinpath(deps_dir, "ASI_SDK.zip")
    run(`unzip -o $file -d $deps_dir`)
    sdk_file = joinpath(deps_dir, "ASI_Camera_SDK/ASI_linux_mac_SDK_V$version.tar.bz2")
    run(`tar xf $sdk_file --directory=$deps_dir`)
    lib_dir  = joinpath(deps_dir, "ASI_linux_mac_SDK_V$version", "lib")

    if Sys.islinux()
        rules_file = mv(joinpath(lib_dir, "asi.rules"), joinpath(par_dir, "asi.rules"), force=true)
        if Sys.ARCH==:x86_64
            if Sys.WORD_SIZE==64
                arch_name = "x64"
            elseif Sys.WORD_SIZE==32
                arch_name = "x86"
            end
        elseif Sys.ARCH==:aarch64
            arch_name = "armv8"
        elseif Sys.ARCH==:arm || (Sys.ARCH==:aarch && Sys.WORD_SIZE==32)
            arch_name = "armv7"
        end
        source_file = joinpath(lib_dir, arch_name, "libASICamera2.so.$version")
        target_file = joinpath(lib_target_dir, "libASICamera2.so")
        mv(source_file, target_file, force=true)
    elseif Sys.isapple()
        arch_name = "mac"
        source_file = joinpath(lib_dir, arch_name, "libASICamera2.dylib.$version")
        target_file = joinpath(lib_target_dir, "libASICamera2.dylib")
        mv(source_file, target_file, force=true)
    end
end


#extract
# if isfile(sdk_file)
#     if Sys.isunix()
#         unpack_cmd = `tar xjf $sdk_file --directory=$sdk_dir` end
#     if Sys.iswindows()
#         if isdefined(Base, :LIBEXECDIR)
#           const exe7z = joinpath(Sys.BINDIR, Base.LIBEXECDIR, "7z.exe")
#         else
#           const exe7z = joinpath(Sys.BINDIR, "7z.exe")
#         end
#         unpack_cmd = `$exe7z x -o$sdk_dir -y $sdk_file`
#     end
#     run(unpack_cmd)
# end


# elseif Sys.iswindows()
#     if isa(1, Int64)
#         source_file = joinpath(sdk_dir, "ASI SDK", "lib", "x64", "ASICamera2.dll")
#         target_file = joinpath(lib_target_dir, "ASICamera2.dll")
#         mv(source_file, target_file, force=true)
#     else
#         source_file = joinpath(sdk_dir, "ASI SDK", "lib", "x86", "ASICamera2.dll")
#         target_file = joinpath(lib_target_dir, "ASICamera2.dll")
#         mv(source_file, target_file, force=true)
#     end
# end

# cleanup
rm(joinpath(deps_dir, "ASI_SDK.zip"), force=true)
rm(joinpath(deps_dir, "ASI_Camera_SDK"), recursive=true)
rm(joinpath(deps_dir, "ASI_linux_mac_SDK_V$version"), recursive=true, force=true)

if Sys.isunix()
    rules_file = joinpath(par_dir, "asi.rules")
    println("\nPlease install the udev rules for the camera device, so that you can
    access it without root privileges. To install the rules, run
    'sudo install $rules_file /lib/udev/rules.d'
    or
    'sudo install $rules_file /etc/udev/rules.d'
    and reboot or relog and reconnect the camera. Then run
    'cat /sys/module/usbcore/parameters/usbfs_memory_mb'
    and make sure the result is 200.\n")
end
