# This file is a part of H3DPolaris.jl, licensed under the MIT License (MIT).

struct PolarisEventHeader
    nhits::Int32    # Event multiplicity (number of interactions)
    ts_s::Int32     # Event time, seconds
    ts_ms::Int32    # Event time, milliseconds
end

export PolarisEventHeader

Base.time(header::PolarisEventHeader) = header.ts_s + header.ts_ms * 1E-3


function Base.read(src::IO, ::Type{PolarisEventHeader})
    nhits = ntoh(read(src, UInt8))  # multiplicity, number of interactions
    ts_s = ntoh(read(src, UInt32))
    ts_ms = ntoh(read(src, UInt32))

    PolarisEventHeader(nhits, ts_s, ts_ms)
end



struct PolarisHit
    detno::Int32 # Detector number
    x::Int32  # Position in µm,
    y::Int32  # Position in µm,
    z::Int32  # Position in µm,
    edep::Int32 # Energy deposition in eV
end

export PolarisHit


function Base.read(src::IO, ::Type{PolarisHit})
    detno = ntoh(read(src, UInt8))
    x = ntoh(read(src, Int32)) # µm,
    y = ntoh(read(src, Int32)) # µm,
    z = ntoh(read(src, Int32)) # nm, zero at anode
    edep = ntoh(read(src, Int32)) # eV

    PolarisHit(detno, x, y, z, edep)
end
