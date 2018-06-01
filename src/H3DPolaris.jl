# This file is a part of H3DPolaris.jl, licensed under the MIT License (MIT).

__precompile__(true)

module H3DPolaris

using BufferedStreams
using CompressedStreams

include("polaris_data.jl")
include("datastream.jl")
include("polaris_detector.jl")

end # module
