
module Scotch

# Define before execution, for instance in your /~.juliarc.jl
# const SCOTCH_LIBSCOTCH = "/Users/lcambier/Stanford/SCOTCH.jl/src/libscotch.dylib"

mutable struct Graph
end

mutable struct Strat
end

mutable struct Ordering 
end

mutable struct File # libc's File
end


function version()
    ver = Cint[0]
    rel = Cint[0]
    pat = Cint[0]
    ccall((:SCOTCH_version, SCOTCH_LIBSCOTCH), Void, 
            (Ptr{Cint}, Ptr{Cint}, Ptr{Cint}), 
            pointer(ver), pointer(rel), pointer(pat))
    return (ver[1], rel[1], pat[1])
end

function graphAlloc()
    graph = ccall((:SCOTCH_graphAlloc, SCOTCH_LIBSCOTCH), Ptr{Graph}, ())
    if graph == C_NULL
        error("Error in graphAlloc")
    end
    return graph
end

function graphInit(graph::Ptr{Graph})
    err = ccall((:SCOTCH_graphInit, SCOTCH_LIBSCOTCH), Cint, 
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
    err = ccall((:SCOTCH_graphLoad, SCOTCH_LIBSCOTCH), Cint,
                (Ptr{Graph}, Ptr{File}, Cint, Cint),
                graph, file, Cint(baseval), Cint(flagval))
    err == 0 || error("Error in graphInit")
    return 
end

function graphBuild(graph::Ptr{Graph}, A::SparseMatrixCSC{Tv, Ti}) where {Tv, Ti <: Integer}
    A.n == A.m || error("Matrix should be square")
    # Remove self loops
    vertnbr = A.n
    verttab = Ptr{Cint}(Libc.malloc(sizeof(Cint) * (vertnbr+1)))
    edgetab = Ptr{Cint}(Libc.malloc(sizeof(Cint) * length(A.rowval)))
    unsafe_store!(verttab, 1)
    k = 1
    edgenbr = 0
    for i = 1:vertnbr
        for j = A.colptr[i]:(A.colptr[i+1]-1)
            if A.rowval[j] != i
                unsafe_store!(edgetab, A.rowval[j], k)
                k += 1
                edgenbr += 1
            end
        end
        unsafe_store!(verttab, k, i+1)
    end
    # FIXME: resize edgetab to k
    err = ccall((:SCOTCH_graphBuild, SCOTCH_LIBSCOTCH), Cint,
          (Ptr{Graph}, Cint, Cint,    Ptr{Cint},  Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Cint,    Ptr{Cint},  Ptr{Cint}),
          graph,       1,    vertnbr, verttab,    C_NULL,    C_NULL,    C_NULL,    edgenbr, edgetab,    C_NULL)
    err == 0 || error("Error in graphBuild")
    return
end

function graphCheck(graph::Ptr{Graph})
    err = ccall((:SCOTCH_graphCheck, SCOTCH_LIBSCOTCH), Cint, 
                (Ptr{Graph},), 
                graph)
    err == 0 || error("Error in graphCheck")
end

function graphSize(graph::Ptr{Graph})
    nv = Cint[0]
    ne = Cint[0]
    ccall((:SCOTCH_graphSize, SCOTCH_LIBSCOTCH), Void,
               (Ptr{Graph}, Ptr{Cint}, Ptr{Cint}),
               graph, pointer(nv), pointer(ne)) 
    return (nv[1], ne[1])
end

function graphFree(graph::Ptr{Graph})
    ccall((:SCOTCH_graphFree, SCOTCH_LIBSCOTCH), Void,
          (Ptr{Graph},),
          graph)
end

function graphExit(graph::Ptr{Graph})
    ccall((:SCOTCH_graphExit, SCOTCH_LIBSCOTCH), Void,
          (Ptr{Graph},),
          graph)
end

function graphStat(graph::Ptr{Graph})
    A1 = Cint[0,0,0,0,0,0,0,0]
    A2 = Cdouble[0,0,0,0,0,0]
    @show A1, A2
    ccall((:SCOTCH_graphStat, SCOTCH_LIBSCOTCH), Void, 
          (Ptr{Graph},
           Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble},
           Ptr{Cint}, Ptr{Cint},            Ptr{Cdouble}, Ptr{Cdouble},
           Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cdouble}, Ptr{Cdouble}),
          graph,
          pointer(A1, 1), pointer(A1, 2), pointer(A1, 3), pointer(A2, 1), pointer(A2, 2),
          pointer(A1, 4), pointer(A1, 5),                 pointer(A2, 3), pointer(A2, 4), 
          pointer(A1, 6), pointer(A1, 7), pointer(A1, 8), pointer(A2, 5), pointer(A2, 6))
    @show A1, A2
    return (A1[1], A1[2], A1[3], A2[1], A2[2],
            A1[4], A1[5],        A2[3], A2[4],
            A1[6], A1[7], A1[8], A2[5], A2[6])
end


# Strategy

function stratAlloc()
    strat = ccall((:SCOTCH_stratAlloc, SCOTCH_LIBSCOTCH), Ptr{Strat}, ())
    strat != C_NULL || error("Error in stratAlloc")
    return strat
end

function stratInit(strat::Ptr{Strat})
    err = ccall((:SCOTCH_stratInit, SCOTCH_LIBSCOTCH), Cint,
                (Ptr{Strat},),
                strat)
    err == 0 || error("Error in stratInit")
    return
end

function stratGraphOrder(strat::Ptr{Strat}, st::String)
    err = ccall((:SCOTCH_stratGraphOrder, SCOTCH_LIBSCOTCH), Cint,
                (Ptr{Strat}, Ptr{Char}),
                strat, pointer(st))
    err == 0 || error("Error in stratGraphOrder")
    return
end

function stratExit(strat::Ptr{Strat})
    ccall((:SCOTCH_stratExit, SCOTCH_LIBSCOTCH), Void,
          (Ptr{Strat},),
          strat)
end

# Ordering

function graphOrder(graph::Ptr{Graph}, strat::Ptr{Strat})
    (nv, ne) = graphSize(graph)
    permtab = Array{Cint, 1}(nv)
    peritab = Array{Cint, 1}(nv)
    cblkptr = Array{Cint, 1}(1)
    rangtab = Array{Cint, 1}(nv + 1)
    treetab = Array{Cint, 1}(nv)
    err = ccall((:SCOTCH_graphOrder, SCOTCH_LIBSCOTCH), Cint,
            (Ptr{Graph}, Ptr{Strat}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}), 
            graph,       strat,      pointer(permtab), pointer(peritab), pointer(cblkptr), pointer(rangtab), pointer(treetab))
    err == 0 || error("Error in graphOrder")
    return (permtab, peritab, cblkptr, rangtab, treetab)
end

function orderAlloc()
    optr = ccall((:SCOTCH_orderAlloc, SCOTCH_LIBSCOTCH), Ptr{Ordering}, ())
    optr != C_NULL || error("Error in orderAlloc")
    return optr
end

function graphOrderInit(graph::Ptr{Graph}, ordering::Ptr{Ordering}, permtab::Array{Cint,1}, peritab::Array{Cint,1}, cblkptr::Array{Cint,1}, rangtab::Array{Cint,1}, treetab::Array{Cint,1})
    err = ccall((:SCOTCH_graphOrderInit, SCOTCH_LIBSCOTCH), Cint,
                (Ptr{Graph}, Ptr{Ordering}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}),
                graph, ordering, pointer(permtab), pointer(peritab), pointer(cblkptr), pointer(rangtab), pointer(treetab))
    err == 0 || error("Error in graphOrderInit")
    return
end

function graphOrderComputeList(graph::Ptr{Graph}, ordering::Ptr{Ordering}, listtab::Array{Cint,1}, strat::Ptr{Strat})
    err = ccall((:SCOTCH_graphOrderComputeList, SCOTCH_LIBSCOTCH), Cint,
                (Ptr{Graph}, Ptr{Ordering}, Cint, Ptr{Cint}, Ptr{Strat}),
                graph, ordering, Cint(length(listtab)), pointer(listtab), strat)
    err == 0 || error("Error in graphOrderComputeList")
    return
end

function graphOrderCompute(graph::Ptr{Graph}, ordering::Ptr{Ordering}, strat::Ptr{Strat})
    err = ccall((:SCOTCH_graphOrderCompute, SCOTCH_LIBSCOTCH), Cint,
                (Ptr{Graph}, Ptr{Ordering}, Ptr{Strat}),
                graph, ordering, strat)
    err == 0 || error("Error in graphOrderCompute")
    return
end

function graphOrderCheck(graph::Ptr{Graph}, ordering::Ptr{Ordering})
    err = ccall((:SCOTCH_graphOrderCheck, SCOTCH_LIBSCOTCH), Cint, 
                (Ptr{Graph}, Ptr{Ordering}),
                graph, ordering)
    err == 0 || error("Error in graphOrderCheck")
end

function graphOrderExit(graph::Ptr{Graph}, ordering::Ptr{Ordering})
    ccall((:SCOTCH_graphOrderExit, SCOTCH_LIBSCOTCH), Void,
                (Ptr{Graph}, Ptr{Ordering}),
                graph, ordering)
end

end # module Scotch



