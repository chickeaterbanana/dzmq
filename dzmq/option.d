module dzmq.option;

mixin template OptionGetSet(alias Member, alias Get, alias Set)
{
    void setOption(int option, int val)
    {
        ZMQEnforce(Set(Member, option, val));
    }

    int getOption(int option)
    {
        return ZMQEnforce(Get(Member, option));
    }
}
