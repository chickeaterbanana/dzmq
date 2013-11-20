module dzmq.error;

import std.exception;

// TODO: change to use zmq_strerror
alias ErrnoException ZMQException;

T ZMQEnforce(T)(T val, T fail_val)
{
    enforce(val != fail_val, new ZMQException("ZMQ:"));
    return val;
}

T ZMQEnforce(T : real)(T val)
{
    return ZMQEnforce!T(val, -1);
}

T ZMQEnforce(T : void*)(T val)
{
    return ZMQEnforce!T(val, null);
}
