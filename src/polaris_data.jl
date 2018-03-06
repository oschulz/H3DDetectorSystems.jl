# This file is a part of H3DPolaris.jl, licensed under the MIT License (MIT).


struct PolarisEvents
    evt_no::Vector{Int32}               # Event number
    evt_nhits::Vector{Int32}            # Number of hits
    evt_t::Vector{Int64}                # Event time, nanoseconds
    evt_issync::Vector{Bool}            # True is sync event
    hit_detno::Vector{Vector{Int32}}    # Detector number
    hit_x::Vector{Vector{Int32}}        # Position in µm,
    hit_y::Vector{Vector{Int32}}        # Position in µm,
    hit_z::Vector{Vector{Int32}}        # Position in µm,
    hit_edep::Vector{Vector{Int32}}     # Energy deposition in eV
    hit_t::Vector{Vector{Int64}}        # Hit time, nanoseconds
end

export PolarisEvents

PolarisEvents() = PolarisEvents(
    Vector{Int32}(), Vector{Int32}(), Vector{Int64}(), Vector{Bool}(),
    Vector{Vector{Int32}}(), Vector{Vector{Int32}}(), Vector{Vector{Int32}}(),
    Vector{Vector{Int32}}(), Vector{Vector{Int32}}(), Vector{Vector{Int64}}()
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
        evtno = if !isempty(data.events.evt_no)
            last(data.events.evt_no)
        else
            zero(eltype(data.events.evt_no))
        end

        hitno = if !isempty(data.hits.hitno)
            last(data.hits.hitno)
        else
            zero(eltype(data.hits.hitno))
        end

        hit_detno = Vector{Int32}()
        hit_x = Vector{Int32}()
        hit_y = Vector{Int32}()
        hit_z = Vector{Int32}()
        hit_edep = Vector{Int32}()
        hit_t = Vector{Int64}()

        while !eof(input)
            nhits_tmp = ntoh(read(input, UInt8))
            evtno += 1

            resize!(hit_detno, 0)
            resize!(hit_x, 0)
            resize!(hit_y, 0)
            resize!(hit_z, 0)
            resize!(hit_edep, 0)
            resize!(hit_t, 0)

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

                    push!(hit_detno, hit.detno)
                    push!(hit_x, hit.x)
                    push!(hit_y, hit.y)
                    push!(hit_z, hit.z)
                    push!(hit_edep, hit.edep)
                    push!(hit_t, t)

                    push!(hits.evtno, evtno)
                    push!(hits.hitno, hitno)
                    push!(hits.t, t)
                    push!(hits.detno, hit.detno)
                    push!(hits.x, hit.x)
                    push!(hits.y, hit.y)
                    push!(hits.z, hit.z)
                    push!(hits.edep, hit.edep)
                end
            end

            push!(events.evt_no, evtno)
            push!(events.evt_nhits, nhits)
            push!(events.evt_t, t)
            push!(events.evt_issync, issync)
            push!(events.hit_detno, hit_detno)
            push!(events.hit_x, hit_x)
            push!(events.hit_y, hit_y)
            push!(events.hit_z, hit_z)
            push!(events.hit_edep, hit_edep)
            push!(events.hit_t, hit_t)
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
