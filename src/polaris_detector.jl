# This file is a part of H3DPolaris.jl, licensed under the MIT License (MIT).


struct PolarisDetector
    hostname::String
end

export PolarisDetector



struct PolarisDetectorInstance
    hostname::String
    data_io::TCPSocket
    control_io::TCPSocket
end

export PolarisDetectorInstance


function Base.open(device_spec::PolarisDetector)
    data_io = connect(device_spec.hostname, 11503)
    control_io = try
        connect(device_spec.hostname, 11502)
    catch err
        close(data_io)
        rethrow()
    end
    PolarisDetectorInstance(device_spec.hostname, data_io, control_io)
end


function Base.close(device::PolarisDetectorInstance)
    close(device.data_io)
    close(device.control_io)
end


function exec_dev_cmd(device::PolarisDetectorInstance, cmd::AbstractString, expected_response::AbstractString)
    @info "Sending command \"$cmd\"."
    println(device.control_io, cmd)
    resp = readline(device.control_io)
    @info "Received response \"$resp\"."
    resp != expected_response && throw(ErrorException("Device command \"cmd\" resulted in invalid/unexpected response"))
    nothing
end


@inline Base.setindex!(device::PolarisDetectorInstance, x, property::Symbol) =
    Base.setindex!(device, x, Val(property))


function Base.setindex!(device::PolarisDetectorInstance, ::Tuple{}, ::Val{:reset_index})
    exec_dev_cmd(device, "ResetIndex", "Reset sync pulse timestamp index.")
    ()
end


function Base.setindex!(device::PolarisDetectorInstance, enabled::Bool, ::Val{:sync_pulse_generation})
    if enabled
        exec_dev_cmd(device, "Start", "Start sync pulse.")
    else
        exec_dev_cmd(device, "Stop", "Stop sync pulse.")
    end
    enabled
end
