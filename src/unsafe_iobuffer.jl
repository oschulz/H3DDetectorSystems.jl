mutable struct UnsafeInputBuffer
	data::UnsafeArray{UInt8,1}
    ptr::Int
end


@inline Base.bytesavailable(io::UnsafeInputBuffer) = length(io.bytes) - io.ptr + 1


# Similar to Base.unsafe_read(from::GenericIOBuffer, p::Ptr{UInt8}, nb::UInt):
function Base.unsafe_read(from::UnsafeInputBuffer, p::Ptr{UInt8}, nb::UInt)
    avail = bytesavailable(from)
    adv = min(avail, nb)
    Base.unsafe_copyto!(p, pointer(from.data, ptr), adv)
    from.ptr += adv
    if nb > avail
        throw(EOFError())
    end
    nothing
end


@inline function read(from::UnsafeInputBuffer, ::Type{UInt8})
    ptr = from.ptr
    size = length(from.data)
    if ptr > size
        throw(EOFError())
    end
    @inbounds byte = from.data[ptr]
    from.ptr = ptr + 1
    return byte
end


function show(io::IO, b::UnsafeInputBuffer)
    print(io,
        "UnsafeInputBuffer(data=UInt8[...], ",
        "readable=", true, ", ",
        "writable=", false, ", ",
        "seekable=", true, ", ",
        "append=",   false, ", ",
        "size=",     length(b.data), ", ",
        "maxsize=",  length(b.data), ", ",
        "ptr=",      b.ptr, ", ",
        "mark=",     0, ")")
    )
end
