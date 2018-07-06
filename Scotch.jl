module Scotch

mutable struct Graph
end

mutable struct Strat
end

mutable struct File
end

mutable struct Ordering
end

function version()
    ver = Cint[0]
    rel = Cint[0]
    pat = Cint[0]
    ccall((:SCOTCH_version, "libscotch.dylib"), Void, 
            (Ptr{Cint}, Ptr{Cint}, Ptr{Cint}), 
            pointer(ver), pointer(rel), pointer(pat))
    return (ver[1], rel[1], pat[1])
end

function graphAlloc()
    graph = ccall((:SCOTCH_graphAlloc, "libscotch.dylib"), Ptr{Graph}, ())
    if graph == C_NULL
        error("Error in graphAlloc")
    end
    return graph
end

   # err += SCOTCH_graphInit(graph);
   # err += SCOTCH_graphLoad(graph, file, baseval, flagval);
function graphInit(graph::Ptr{Graph})
    err = ccall((:SCOTCH_graphInit, "libscotch.dylib"), Cint, 
                (Ptr{Graph},), 
                graph)
    err == 0 || error("Error in graphInit")
    return
end

function graphLoad(graph::Ptr{Graph}, filename, baseval::Integer, flagval::Integer)
    m = "r"
    file = ccall((:fopen, "libc"), Ptr{File}, 
             (Ptr{Char}, Ptr{Char}),
             pointer(filename), pointer(m))
    file != C_NULL || error("Error in graphInit, fopen")
    err = ccall((:SCOTCH_graphLoad, "libscotch.dylib"), Cint,
                (Ptr{Graph}, Ptr{File}, Cint, Cint),
                graph, file, Cint(baseval), Cint(flagval))
    err == 0 || error("Error in graphInit")
    return 
end

function graphSize(graph::Ptr{Graph})
    nv = Cint[0]
    ne = Cint[0]
    ccall((:SCOTCH_graphSize, "libscotch.dylib"), Void,
               (Ptr{Graph}, Ptr{Cint}, Ptr{Cint}),
               graph, pointer(nv), pointer(ne)) 
    return (nv[1], ne[1])
end

# Strategy
function stratAlloc()
    strat = ccall((:SCOTCH_stratAlloc, "libscotch.dylib"), Ptr{Strat}, ())
    strat != C_NULL || error("Error in stratAlloc")
    return strat
end

function stratInit(strat::Ptr{Strat})
    err = ccall((:SCOTCH_stratInit, "libscotch.dylib"), Cint,
                (Ptr{Strat},),
                strat)
    err == 0 || error("Error in stratInit")
    return
end

function stratGraphOrder(strat::Ptr{Strat}, st::String)
    err = ccall((:SCOTCH_stratGraphOrder, "libscotch.dylib"), Cint,
                (Ptr{Strat}, Ptr{Char}),
                strat, pointer(st))
    err == 0 || error("Error in stratGraphOrder")
    return
end

function graphOrder(graph::Ptr{Graph}, strat::Ptr{Strat})
    (nv, ne) = graphSize(graph)
    permtab = Array{Cint, 1}(nv)
    peritab = Array{Cint, 1}(nv)
    cblkptr = Array{Cint, 1}(1)
    rangtab = Array{Cint, 1}(nv + 1)
    treetab = Array{Cint, 1}(nv)
    err = ccall((:SCOTCH_graphOrder, "libscotch.dylib"), Cint,
            (Ptr{Graph}, Ptr{Strat}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}), 
            graph,       strat,      pointer(permtab), pointer(peritab), pointer(cblkptr), pointer(rangtab), pointer(treetab))
    err == 0 || error("Error in graphOrder")
    return (permtab, peritab, cblkptr[1], rangtab, treetab)
end

function orderAlloc()
    optr = ccall((:SCOTCH_orderAlloc, "libscotch.dylib"), Ptr{Ordering}, ())
    optr != C_NULL || error("Error in orderAlloc")
    return optr
end

function graphOrderInit(graph::Ptr{Graph}, ordering::Ptr{Ordering}, permtab::Array{Cint,1}, peritab::Array{Cint,1}, cblkptr::Cint, rangtab::Array{Cint,1}, treetab::Array{Cint,1})
    err = ccall((:SCOTCH_graphOrderInit, "libscotch.dylib"), Cint,
                (Ptr{Graph}, Ptr{Ordering}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}),
                graph, ordering, pointer(permtab), pointer(permtab), &cblkptr, pointer(rangtab), pointer(treetab))
    err == 0 || error("Error in graphOrderInit")
    return
end

end # module Scotch



