# This file is a part of H3DPolaris.jl, licensed under the MIT License (MIT).


struct PolarisEvents
    evt_no::Vector{Int32}               # Event number
    evt_nhits::Vector{Int32}            # Number of hits
    evt_t::Vector{Int64}                # Event time, nanoseconds
    evt_issync::Vector{Bool}            # True is sync event
    hit_detno::VectorOfVectors{Int32}   # Detector number
    hit_x::VectorOfVectors{Int32}       # Position in µm,
    hit_y::VectorOfVectors{Int32}       # Position in µm,
    hit_z::VectorOfVectors{Int32}       # Position in µm,
    hit_edep::VectorOfVectors{Int32}    # Energy deposition in eV
    hit_t::VectorOfVectors{Int64}       # Hit time, nanoseconds
end

export PolarisEvents

PolarisEvents() = PolarisEvents(
    Vector{Int32}(), Vector{Int32}(), Vector{Int64}(), Vector{Bool}(),
    VectorOfVectors{Int32}(), VectorOfVectors{Int32}(), VectorOfVectors{Int32}(),
    VectorOfVectors{Int32}(), VectorOfVectors{Int32}(), VectorOfVectors{Int64}()
)


Base.NamedTuple(events::PolarisEvents) = (
    evt_no = events.evt_no,
    evt_t = events.evt_t,
    evt_nhits = events.evt_nhits,
    evt_issync = events.evt_issync,
    hit_edep = events.hit_edep,
    hit_t = events.hit_t,
    hit_detno = events.hit_detno,
    hit_x = events.hit_x,
    hit_y = events.hit_y,
    hit_z = events.hit_z,
)


Base.convert(::Type{NamedTuple}, events::PolarisEvents) = NamedTuple(events)


function Base.read!(
    input::IO, events::PolarisEvents;
    max_nevents::Int = typemax(Int),
    max_time::Float64 = Inf
)
    time_in_ns(timestamp::UInt64) = Int64(timestamp >> 5) * 10

    try
        evtno_offset = if !isempty(events.evt_no)
            Int(last(events.evt_no))
        else
            zero(Int)
        end

        hit_detno = Vector{Int32}()
        hit_x = Vector{Int32}()
        hit_y = Vector{Int32}()
        hit_z = Vector{Int32}()
        hit_edep = Vector{Int32}()
        hit_t = Vector{Int64}()

        start_time = time_ns()
        nevents::Int = 0

        while !eof(input) && (nevents < max_nevents) && ((time_ns() - start_time) * 1E-9 < max_time)
            nevents += 1
            nhits_tmp = ntoh(read(input, UInt8))
            evtno = nevents + evtno_offset

            # evtno % 100000 == 0 && info("Reading event $evtno")

            resize!(hit_detno, 0)
            resize!(hit_x, 0)
            resize!(hit_y, 0)
            resize!(hit_z, 0)
            resize!(hit_edep, 0)
            resize!(hit_t, 0)

            nhits::Int = 0
            t::Int64 = -1
            issync::Bool = false

            if nhits_tmp == 0
                # @debug "nhits_tmp == 0, skipping 23 bytes"
                read(input, UInt64)
                read(input, UInt64)
                read(input, UInt32)
                read(input, UInt16)
                read(input, UInt8)
            else
                if nhits_tmp == 122
                    issync = true
                    synchdr = read(input, PolarisSyncHeader)
                    (synchdr.n < 2) && @error "Invalid sync event in data stream, missing timestamp"
                    for i in 1:synchdr.n
                        syncvalue = read(input, PolarisSyncValue)
                        if i == 2
                            t = time_in_ns(syncvalue.x)
                            # @debug "sync_t" t syncvalue.x
                        end
                    end
                    @assert t >= 0
                else
                    nhits = Int(nhits_tmp)
                    (1 <= nhits <= 121) || throw(ErrorException("Invalid number of hits ($nhits) in datastream"))     
                    evthdr = read(input, PolarisEventHeader)
                    t = time_in_ns(evthdr.timestamp)
                    for i in 1:nhits
                        hit = read(input, PolarisHit)

                        push!(hit_detno, hit.detno)
                        push!(hit_x, hit.x)
                        push!(hit_y, hit.y)
                        push!(hit_z, hit.z)
                        push!(hit_edep, hit.edep)
                        push!(hit_t, t)
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
        end
    catch err
        if isa(err, EOFError)
            info("Input was truncated.")
        else
            rethrow()
        end
    end
    events
end


Base.read(input::IO, ::Type{PolarisEvents}; kwargs...) = read!(input, PolarisEvents(); kwargs...)


function Base.read(filename::AbstractString, ::Type{PolarisEvents})
    open(CompressedFile(filename)) do input
        read(BufferedInputStream(input), PolarisEvents)
    end
end
