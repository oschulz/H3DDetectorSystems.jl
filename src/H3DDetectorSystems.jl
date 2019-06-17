# This file is a part of H3DDetectorSystems.jl, licensed under the MIT License (MIT).

__precompile__(true)

module H3DDetectorSystems

using Sockets

using ArraysOfArrays
using BufferedStreams

include("polaris_data.jl")
include("datastream.jl")
include("polaris_detector.jl")

end # module
