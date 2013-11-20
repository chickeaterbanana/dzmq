module dzmq.util;

import deimos.zmq.zmq;
import dunit.toolkit;
import std.string;

string getZMQVersion()
{
    int major;
    int minor;
    int patch;
    zmq_version(&major, &minor, &patch);
    return format("%d.%d.%d", major, minor, patch);
}


unittest
{
    getZMQVersion().assertEqual("3.2.4");
}
