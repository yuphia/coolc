class Main inherits A2I
{
    main() : Object
    {
        (new IO).out_string(i2a(fact(a2i((new IO).ins_string().concat("\n")))))
    };

    fact (i : Int) : Int
    {
        if (i = 0) then 1 else i*fact (i-1) fi
    };
};