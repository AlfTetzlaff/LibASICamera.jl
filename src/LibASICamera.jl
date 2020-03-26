module LibASICamera

import Libdl
using CEnum

if Sys.isunix()
   const libASICamera2 = joinpath(@__DIR__, "../lib/libASICamera2")

elseif Sys.isapple()  # don't know if apple counts as unix
   const libASICamera2 = joinpath(@__DIR__, "../lib/libASICamera2")

elseif Sys.iswindows()
   const libASICamera2 = joinpath(@__DIR__, "../lib/ASICamera2")
end

include(joinpath(@__DIR__, "LibASICamera_highlevel.jl"))

export
   ASICamera,
   open_camera,
   close_camera,
   init_camera,
   start_exposure,
   stop_exposure,
   start_video,
   stop_video,
   allocate_buffer,
   enable_dark_subtract,
   disable_dark_subtract,
   pulse_guide_on,
   pulse_guide_off,
   send_soft_trigger,
   capture_still
   #capture_video


# export the rest
foreach(names(@__MODULE__, all=true)) do s
   if startswith(string(s), "ASI") || startswith(string(s), "set") ||startswith(string(s), "get")
       @eval export $s
   end
end

end # module
