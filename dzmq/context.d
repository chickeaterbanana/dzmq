module dzmq.context;

import deimos.zmq.zmq;
import dunit.toolkit;
import dzmq.error;
import dzmq.option;
import std.exception;

class ZMQContext
{
public:
    this()
    {
        mContext = ZMQEnforce!(void*)(zmq_ctx_new(), null);
    }

    ~this()
    {
        ZMQEnforce(zmq_ctx_destroy(mContext));
    }

    mixin OptionGetSet!(mContext, zmq_ctx_get, zmq_ctx_set);

package:
    void* mContext;

}


unittest
{
    auto c = new ZMQContext;
    c.getOption(ZMQ_IO_THREADS).assertEqual(ZMQ_IO_THREADS_DFLT);
    c.setOption(ZMQ_IO_THREADS, 2);
    c.getOption(ZMQ_IO_THREADS).assertEqual(2);
}

unittest
{
    auto c = new ZMQContext;
    assertThrown!ZMQException(c.getOption(123));
    assertThrown!ZMQException(c.setOption(99, 0));
}
