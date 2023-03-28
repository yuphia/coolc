class List inherits A2I
{
    item: Object;
    next: List;

    init (i : Object, n : List) : List
    {
        {
            item <- i;
            next <- n;
            self;
        }
    };

    flatten() : String
    {
        let string : String <- 
                case item of
                    i : Int => i2a(i);
                    s : String => s;
                    o : Object => { abort(); "";}; // last item in { expr } is string in order to match with return type
                esac
        in
            if (isvoid next) then 
                item
            else
                item.concat (next.flatten())
        fi
    };
}

class Main inherits IO
{
    main() : Object 
    {
        let hello : String <- "Hello ",
            world : String <- "World!",
            newline : String <- "\n",
            i : Int <- 42,
            nil : List, //unintialized variable == nullptr
            list : List <- (new List).init(hello, 
                                (new List).init(world, 
                                    (new List).init(42,
                                        (new List).init(newline, nil))))
        in
            out_string (list.flatten())
    };
}