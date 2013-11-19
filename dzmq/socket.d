module dzmq.socket;

import deimos.zmq.zmq;
import dunit.toolkit;
import dzmq.context;
import dzmq.error;
import dzmq.message;
import std.string;


// TODO: expose these directly?
// int zmq_send(void* s, const void* buf, size_t len, int flags);
// int zmq_recv(void* s, void* buf, size_t len, int flags);

// int zmq_setsockopt(void* s, int option, const void* optval, size_t optvallen);
// int zmq_getsockopt(void* s, int option, void* optval, size_t *optvallen);
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

    void send(T)(const T data, int flags = 0)
    {
        ZMQEnforce(zmq_send(mSocket, cast(void*)&data, data.sizeof, flags));
    }

    void send(ZMQMessage msg, int flags = 0)
    {
        ZMQEnforce(zmq_sendmsg(mSocket, &msg.mMessage, flags));
    }

    void recv(T)(out T output, int flags = 0)
    {
        ZMQEnforce(zmq_recv(mSocket, cast(void*)&output, output.sizeof, flags));
    }

    void recv(ZMQMessage msg, int flags = 0)
    {
        ZMQEnforce(zmq_recvmsg(mSocket, &msg.mMessage, flags));
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

    auto m = new ZMQMessage(toStringz("abcd"));
    rep.send(m);
    auto n = new ZMQMessage(4);
    req.recv(n);
    alias char[4] four_str;
    (*n.getData!four_str()).assertEqual(*m.getData!four_str());
}
