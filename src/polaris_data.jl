# This file is a part of H3DPolaris.jl, licensed under the MIT License (MIT).


struct PolarisEvents
    evtno::Vector{Int32}    # Event number
    t::Vector{Int64}        # Event time, milliseconds
    nhits::Vector{Int32}    # Detector number
end

export PolarisEvents

PolarisEvents() = PolarisEvents(
    Vector{Int32}(), Vector{Int32}(), Vector{Int32}()
)



struct PolarisHits
    evtno::Vector{Int32}    # Event number
    hitno::Vector{Int32}    # Hit number within the event
    t::Vector{Int64}        # Event time, milliseconds
    detno::Vector{Int32}    # Detector number
    x::Vector{Int32}        # Position in µm,
    y::Vector{Int32}        # Position in µm,
    z::Vector{Int32}        # Position in µm,
    edep::Vector{Int32}     # Energy deposition in eV
end

export PolarisHits

PolarisHits() = PolarisHits(
    Vector{Int32}(), Vector{Int32}(), Vector{Int32}(),
    Vector{Int32}(), Vector{Int32}(), Vector{Int32}(),
    Vector{Int32}(), Vector{Int32}()
)


struct PolarisData
    events::PolarisEvents
    hits::PolarisHits
end

export PolarisData

PolarisData() = PolarisData(PolarisEvents(), PolarisHits())



function Base.read!(input::IO, data::PolarisData)
    events = data.events
    hits = data.hits

    try
        evtno = if !isempty(data.events.evtno)
            last(data.events.evtno)
        else
            zero(eltype(data.events.evtno))
        end

        while !eof(input)
            evthdr = read(input, PolarisEventHeader)
            evtno += 1

            t = evthdr.ts_s * 10^3 + evthdr.ts_ms

            for i in 1:evthdr.nhits
                hit = read(input, PolarisHit)
                push!(hits.evtno, evtno)
                push!(hits.hitno, i)
                push!(hits.t, t)
                push!(hits.detno, hit.detno)
                push!(hits.x, hit.x)
                push!(hits.y, hit.y)
                push!(hits.z, hit.z)
                push!(hits.edep, hit.edep)
            end

            push!(events.evtno, evtno)
            push!(events.t, t)
            push!(events.nhits, evthdr.nhits)
        end
    catch err
        if isa(err, EOFError)
            info("Input was truncated.")
        else
            rethrow()
        end
    end
    data
end


Base.read(input::IO, ::Type{PolarisData}) = read!(input, PolarisData())


function Base.read(filename::AbstractString, ::Type{PolarisData})
    open(CompressedFile(filename)) do input
        read(input, PolarisData)
    end
end
