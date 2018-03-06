# This file is a part of H3DPolaris.jl, licensed under the MIT License (MIT).


struct PolarisEvents
    evtno::Vector{Int32}    # Event number
    t::Vector{Int64}        # Event time, nanoseconds
    nhits::Vector{Int32}    # Detector number
    issync::Vector{Bool}    # True is sync event
end

export PolarisEvents

PolarisEvents() = PolarisEvents(
    Vector{Int32}(), Vector{Int32}(), Vector{Int32}(), Vector{Bool}()
)



struct PolarisHits
    evtno::Vector{Int32}    # Event number
    hitno::Vector{Int32}    # Hit number within the event
    t::Vector{Int64}        # Event time, nanoseconds
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

    time_in_s(timestamp::UInt64) = Int64(timestamp) * 10

    try
        evtno = if !isempty(data.events.evtno)
            last(data.events.evtno)
        else
            zero(eltype(data.events.evtno))
        end

        hitno = if !isempty(data.hits.hitno)
            last(data.hits.hitno)
        else
            zero(eltype(data.hits.hitno))
        end

        while !eof(input)
            nhits_tmp = ntoh(read(input, UInt8))
            evtno += 1

            nhits = Int(0)
            t = Int64(-1)
            issync = false

            if nhits_tmp == 122
                issync = true
                synchdr = read(input, PolarisSyncHeader)
                (synchdr.n < 2) && error("Invalid sync event in data stream, missing timestamp")
                for i in 1:synchdr.n
                    syncvalue = read(input, PolarisSyncValue)
                    if i == 2
                        t = time_in_s(syncvalue.x)
                    end
                end
                assert(t >= 0)
            else
                nhits = Int(nhits_tmp)
                evthdr = read(input, PolarisEventHeader)
                t = time_in_s(evthdr.timestamp)
                for i in 1:nhits
                    hit = read(input, PolarisHit)
                    hitno += 1

                    push!(hits.evtno, evtno)
                    push!(hits.hitno, hitno)
                    push!(hits.t, t)
                    push!(hits.detno, hit.detno)
                    push!(hits.x, hit.x)
                    push!(hits.y, hit.y)
                    push!(hits.z, hit.z)
                    push!(hits.edep, hit.edep)
                end
                info("TrigEvt at t = $(t * 1E-9)")
            end

            push!(events.evtno, evtno)
            push!(events.t, t)
            push!(events.nhits, nhits)
            push!(events.issync, issync)
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
