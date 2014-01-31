module dzmq.tools;
import std.traits;

void *toVoidPointer(T)(const T value) if (isPointer!T)
{
    return cast(void*)value;
}

void *toVoidPointer(T)(const T value) if (isArray!T)
{
    return cast(void*)(value.ptr);
}

void *toVoidPointer(T)(const T value) if (is(T == int) ||
    is(T == byte) || is(T == float) || is(T == double) ||
    is(T == ubyte) || is(T == struct))
{
    ubyte[] data = new ubyte[value.sizeof];
    data[0..value.sizeof] = (cast(ubyte*)&value)[0..value.sizeof];
    return cast(void*)(data.ptr);
}
