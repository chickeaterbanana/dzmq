module dzmq.context;

import deimos.zmq.zmq;

mixin template OptionGetSet(alias Member, alias Get, alias Set)
{
    void SetOption(int option, int val)
    {
        Set(Member, option, val);
    }

    int GetOption(int option)
    {
        return Get(Member, option);
    }
}

class ZMQContext
{
public:
    this()
    {
        mContext = zmq_ctx_new();
    }

    ~this()
    {
        zmq_ctx_destroy(mContext);
    }

    mixin OptionGetSet!(mContext, zmq_ctx_get, zmq_ctx_set);

private:
    void* mContext;

}


unittest
{
    auto c = new ZMQContext;
    assert(c.GetOption(ZMQ_IO_THREADS) == ZMQ_IO_THREADS_DFLT);
    c.SetOption(ZMQ_IO_THREADS, 2);
    assert(c.GetOption(ZMQ_IO_THREADS) == 2);
}
