module dzmq.message;

import deimos.zmq.zmq;
import dunit.toolkit;
import dzmq.error;
import dzmq.option;
import dzmq.socket;
import std.traits;

// int zmq_msg_send(zmq_msg_t* msg, void* s, int flags);
// int zmq_msg_recv(zmq_msg_t* msg, void* s, int flags);

extern (C) void noop_free(void *data, void *hint) nothrow
{
}

class ZMQMessage
{
public:
    this()
    {
        ZMQEnforce(zmq_msg_init(&mMessage));
    }

    this(size_t size)
    {
        ZMQEnforce(zmq_msg_init_size(&mMessage, size));
    }

    this(ZMQMessage m)
    {
        ZMQEnforce(zmq_msg_copy(&mMessage, &m.mMessage));
    }

    this(T)(T data, size_t size) if (isPointer!T)
    {
        this(size);
        this.data()[0..size] = (cast(void*)data)[0..size];
    }

    this(T)(T data) if (isScalarType!T || is(T == struct))
    {
        ubyte[] value = new ubyte[data.sizeof];
        value[0..data.sizeof] = (cast(ubyte*)&data)[0..data.sizeof];
        this(value);
    }

    this(T)(T data) if (isArray!T)
    {
        this(data.ptr, data.length);
    }

    ~this()
    {
        ZMQEnforce(zmq_msg_close(&mMessage));
    }

    void send(ZMQSocket s, int flags = 0)
    {
        ZMQEnforce(zmq_msg_send(&mMessage, s.mSocket, flags));
    }

    void recv(ZMQSocket s, int flags = 0)
    {
        ZMQEnforce(zmq_msg_recv(&mMessage, s.mSocket, flags));
    }

    @property void* data()
    {
        return ZMQEnforce(zmq_msg_data(&mMessage));
    }

    T* getData(T)()
    {
        return cast(T*)this.data;
    }

    @property size_t size()
    {
        return ZMQEnforce(zmq_msg_size(&mMessage));
    }

    bool more()
    {
        return zmq_msg_more(&mMessage) == 1;
    }

    void setOption(int option, int val)
    {
        ZMQEnforce(zmq_msg_set(&mMessage, option, val));
    }

    int getOption(int option)
    {
        return ZMQEnforce(zmq_msg_get(&mMessage, option));
    }

package:
    zmq_msg_t mMessage;
}

unittest
{
    auto msg = new ZMQMessage;
    msg.size.assertEqual(0);
    msg.more().assertFalse();
}

unittest
{
    auto msg = new ZMQMessage(10);
    msg.size.assertEqual(10);
    msg.more().assertFalse();
}

unittest
{
    struct Temp {
        int x;
        int y;
    }
    Temp temp = {x: 1, y: 10};
    auto msg = new ZMQMessage(temp);
    msg.size.assertEqual(temp.sizeof);
    msg.more().assertFalse();
    (*msg.getData!Temp).assertEqual(temp);
}
