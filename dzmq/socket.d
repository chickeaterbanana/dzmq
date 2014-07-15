module dzmq.socket;

import deimos.zmq.zmq;
import dunit.toolkit;
import dzmq.context;
import dzmq.error;
import dzmq.message;
import std.conv;
import std.stdio;
import std.string;
import std.traits;


// TODO: expose these directly?
// int zmq_send(void* s, const void* buf, size_t len, int flags);
// int zmq_recv(void* s, void* buf, size_t len, int flags);

// int zmq_socket_monitor(void* s, const char* addr, int events);

class ZMQSocket
{
    this(ZMQContext context, int type)
    {
        mSocket = ZMQEnforce(zmq_socket(context.mContext, type));
    }

    ~this()
    {
        zmq_close(mSocket);
    }

    void bind(string addr)
    {
        ZMQEnforce(zmq_bind(mSocket, toStringz(addr)));
    }

    void connect(string addr)
    {
        ZMQEnforce(zmq_connect(mSocket, toStringz(addr)));
    }

    void unbind(string addr)
    {
        ZMQEnforce(zmq_unbind(mSocket, toStringz(addr)));
    }

    void disconnect(string addr)
    {
        ZMQEnforce(zmq_disconnect(mSocket, toStringz(addr)));
    }

    void send(T)(const T data, size_t size, int flags = 0) if (isPointer!T)
    {
        ZMQEnforce(zmq_send(mSocket, cast(void*)data, size, flags));
    }

    void send(T)(const T data, int flags) if (isArray!T)
    {
        this.send(data.ptr, data.length, flags);
    }

    void send(T)(const T data, int flags = 0) if (isScalarType!T || is(T == struct))
    {
        ubyte[] value = new ubyte[data.sizeof];
        value[0..data.sizeof] = (cast(ubyte*)&data)[0..data.sizeof];
        this.send(value, flags);
    }

    void send(ZMQMessage msg, int flags = 0)
    {
        ZMQEnforce(zmq_sendmsg(mSocket, &msg.mMessage, flags));
    }

    void recv(T)(T output, size_t size, int flags = 0) if (isPointer!T)
    {
        void *data = cast(void*)(new ubyte[size]);
        ZMQEnforce(zmq_recv(mSocket, data, size, flags));
        output[0..size] = (cast(T)data)[0..size];
    }

    void recv(T)(T output, int flags = 0) if (isArray!T)
    {
        this.recv(output.ptr, output.length, flags);
    }

    void recv(T)(out T output, int flags = 0) if (isScalarType!T || is(T == struct))
    {
        this.recv(&output, output.sizeof, flags);
    }

    void recv(ZMQMessage msg, int flags = 0)
    {
        ZMQEnforce(zmq_recvmsg(mSocket, &msg.mMessage, flags));
    }

    // Define Get/SetSockOpt for an option
    enum DefineOption(T, string name, int id, T test_val) =
        DefineOptionGet!(T, name, id) ~
        DefineOptionSet!(T, name, id) ~
        "unittest
        {
            auto ctx = new ZMQContext;
            auto s = new ZMQSocket(ctx, ZMQ_REQ);
            " ~ fullyQualifiedName!(T) ~ " val = " ~ to!string(test_val) ~ ";
            s." ~ name ~ "(val);
            s." ~ name ~ "().assertEqual(val);
        }";

    enum DefineOptionGet(T, string name, int id) =
        "@property " ~ fullyQualifiedName!(T) ~ " " ~ name ~ "()" ~ "
        {
            return getSockOpt!(" ~ fullyQualifiedName!(T) ~ ")(" ~ to!string(id) ~ ");
        }";

    enum DefineOptionSet(T, string name, int id) =
        "@property void " ~ name ~ "(" ~ fullyQualifiedName!(T) ~ " val)
        {
            setSockOpt(" ~ to!string(id) ~ ", val);
        }";

    mixin(DefineOption!(int, "SendHWM", ZMQ_SNDHWM, 500));
    mixin(DefineOption!(int, "RecvHWM", ZMQ_RCVHWM, 500));
    mixin(DefineOption!(ulong, "Affinity", ZMQ_AFFINITY, 1));
    mixin(DefineOption!(int, "Rate", ZMQ_RATE, 200));
    mixin(DefineOption!(int, "RecoveryInterval", ZMQ_RECOVERY_IVL, 8000));
    mixin(DefineOption!(int, "SendBufferSize", ZMQ_SNDBUF, 1024));
    mixin(DefineOption!(int, "RecvBufferSize", ZMQ_RCVBUF, 1024));
    mixin(DefineOption!(int, "Linger", ZMQ_LINGER, 0));
    mixin(DefineOption!(int, "ReconnectInterval", ZMQ_RECONNECT_IVL, 200));
    mixin(DefineOption!(int, "MaxReconnectInterval", ZMQ_RECONNECT_IVL_MAX, 1000));
    mixin(DefineOption!(int, "Backlog", ZMQ_BACKLOG, 200));
    mixin(DefineOption!(long, "MaxMessageSize", ZMQ_MAXMSGSIZE, 1024));
    mixin(DefineOption!(int, "MulticastHops", ZMQ_MULTICAST_HOPS, 3));
    mixin(DefineOption!(int, "RecvTimeout", ZMQ_RCVTIMEO, 1000));
    mixin(DefineOption!(int, "SendTimeout", ZMQ_SNDTIMEO, 1000));
    mixin(DefineOption!(int, "IPV4Only", ZMQ_IPV4ONLY, 0));
    mixin(DefineOption!(int, "DelayAttachOnConnect", ZMQ_DELAY_ATTACH_ON_CONNECT, 1));
    mixin(DefineOption!(int, "TCPKeepAlive", ZMQ_TCP_KEEPALIVE, 1));
    mixin(DefineOption!(int, "TCPKeepAliveIdle", ZMQ_TCP_KEEPALIVE_IDLE, 1000));
    mixin(DefineOption!(int, "TCPKeepAliveCount", ZMQ_TCP_KEEPALIVE_CNT, 1000));
    mixin(DefineOption!(int, "TCPKeepAliveInterval", ZMQ_TCP_KEEPALIVE_INTVL, 1000));

    // TODO: tests?
    mixin(DefineOptionGet!(int, "SocketType", ZMQ_TYPE));
    mixin(DefineOptionGet!(int, "RecvMore", ZMQ_RCVMORE));
    mixin(DefineOptionGet!(int, "Fd", ZMQ_FD));
    mixin(DefineOptionGet!(int, "Events", ZMQ_EVENTS));
    mixin(DefineOptionGet!(char[], "LastEndpoint", ZMQ_LAST_ENDPOINT));

    // TODO: Tests fail. Types are wrong I think...
    // mixin(DefineOption!(byte[], "Subscribe", ZMQ_SUBSCRIBE, [0, 5]));
    // mixin(DefineOption!(byte[], "Unsubscribe", ZMQ_UNSUBSCRIBE, [6, 7, 8]));
    // mixin(DefineOption!(byte[], "Identity", ZMQ_IDENTITY, [1]));
    // mixin(DefineOption!(byte, "RouterMandatory", ZMQ_ROUTER_MANDATORY, 1));
    // mixin(DefineOption!(int, "XPUBVerbose", ZMQ_XPUB_VERBOSE, 1));
    // mixin(DefineOption!(char[], "TCPAcceptFilter", ZMQ_TCP_ACCEPT_FILTER, ['a', 'b', 'c']));

private:
    void setSockOpt(T)(int option, T val)
    {
        ZMQEnforce(zmq_setsockopt(mSocket, option,
                                  &val, val.sizeof));
    }

    T getSockOpt(T)(int option)
    {
        T val;
        size_t len = val.sizeof;
        ZMQEnforce(zmq_getsockopt(mSocket, option, &val, &len));
        return val;
    }


package:
    void* mSocket;

}

unittest
{
    auto ctx = new ZMQContext;
    auto req = new ZMQSocket(ctx, ZMQ_REQ);
    auto rep = new ZMQSocket(ctx, ZMQ_REP);
    rep.bind("tcp://*:8001");
    req.connect("tcp://127.0.0.1:8001");
    req.send(12345);
    int x;
    rep.recv(x);
    x.assertEqual(12345);

    auto m = new ZMQMessage("abcd");
    rep.send(m);
    auto n = new ZMQMessage(4);
    req.recv(n);
    alias char[4] four_str;
    (*n.getData!four_str()).assertEqual(*m.getData!four_str());
    (*n.getData!four_str()).assertEqual("abcd");
}

void zmqProxy(ZMQSocket frontend, ZMQSocket backend)
{
    ZMQEnforce(zmq_proxy(frontend.mSocket, backend.mSocket, null));
}


void zmqProxy(ZMQSocket frontend, ZMQSocket backend, ZMQSocket capture)
{
    ZMQEnforce(zmq_proxy(frontend.mSocket, backend.mSocket, capture.mSocket));
}
