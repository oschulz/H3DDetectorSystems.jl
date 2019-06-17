# This file is a part of H3DDetectorSystems.jl, licensed under the MIT License (MIT).

struct PolarisEventHeader
    timestamp::UInt64     # Event timestamp
end


function Base.read(src::IO, ::Type{PolarisEventHeader})
    timestamp = ntoh(read(src, UInt64))

    PolarisEventHeader(timestamp)
end



struct PolarisHit
    detno::Int32 # Detector number
    x::Int32  # Position in µm,
    y::Int32  # Position in µm,
    z::Int32  # Position in µm,
    edep::Int32 # Energy deposition in eV
end


function Base.read(src::IO, ::Type{PolarisHit})
    detno = ntoh(read(src, UInt8))
    x = ntoh(read(src, Int32)) # µm,
    y = ntoh(read(src, Int32)) # µm,
    z = ntoh(read(src, Int32)) # nm, zero at anode
    edep = ntoh(read(src, Int32)) # eV

    PolarisHit(detno, x, y, z, edep)
end



struct PolarisSyncHeader
    n::Int64
end

function Base.read(src::IO, ::Type{PolarisSyncHeader})
    n = ntoh(read(src, UInt8))  # number of PolarisSyncValue entries to follow
    PolarisSyncHeader(n)
end



struct PolarisSyncValue
    x::UInt64
end


function Base.read(src::IO, ::Type{PolarisSyncValue})
    x = ntoh(read(src, Int64))
    PolarisSyncValue(x)
end
