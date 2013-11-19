module dzmq.option;

mixin template OptionGetSet(alias Member, alias Get, alias Set)
{
    void SetOption(int option, int val)
    {
        ZMQEnforce(Set(Member, option, val));
    }

    int GetOption(int option)
    {
        return ZMQEnforce(Get(Member, option));
    }
}
