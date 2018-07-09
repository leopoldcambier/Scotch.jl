
module Scotch

const libscotch = "src/libscotch.dylib"

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
    ccall((:SCOTCH_version, libscotch), Void, 
            (Ptr{Cint}, Ptr{Cint}, Ptr{Cint}), 
            pointer(ver), pointer(rel), pointer(pat))
    return (ver[1], rel[1], pat[1])
end

function graphAlloc()
    graph = ccall((:SCOTCH_graphAlloc, libscotch), Ptr{Graph}, ())
    if graph == C_NULL
        error("Error in graphAlloc")
    end
    return graph
end

   # err += SCOTCH_graphInit(graph);
   # err += SCOTCH_graphLoad(graph, file, baseval, flagval);
function graphInit(graph::Ptr{Graph})
    err = ccall((:SCOTCH_graphInit, libscotch), Cint, 
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
    err = ccall((:SCOTCH_graphLoad, libscotch), Cint,
                (Ptr{Graph}, Ptr{File}, Cint, Cint),
                graph, file, Cint(baseval), Cint(flagval))
    err == 0 || error("Error in graphInit")
    return 
end

function graphBuild(graph::Ptr{Graph}, A::SparseMatrixCSC{Tv, Ti}) where {Tv, Ti <: Integer}
    A.n == A.m || error("Matrix should be square")
    # Creates graph with no selfloops, as required by Scotch
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
    # Build graph
    err = ccall((:SCOTCH_graphBuild, libscotch), Cint,
          (Ptr{Graph}, Cint, Cint,    Ptr{Cint},  Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Cint,    Ptr{Cint},  Ptr{Cint}),
          graph,       1,    vertnbr, verttab,    C_NULL,    C_NULL,    C_NULL,    edgenbr, edgetab,    C_NULL)
    err == 0 || error("Error in graphBuild")
    return
end

function graphCheck(graph::Ptr{Graph})
    err = ccall((:SCOTCH_graphCheck, libscotch), Cint, 
                (Ptr{Graph},), 
                graph)
    err == 0 || error("Error in graphCheck")
end

function graphSize(graph::Ptr{Graph})
    nv = Cint[0]
    ne = Cint[0]
    ccall((:SCOTCH_graphSize, libscotch), Void,
               (Ptr{Graph}, Ptr{Cint}, Ptr{Cint}),
               graph, pointer(nv), pointer(ne)) 
    return (nv[1], ne[1])
end

# Strategy
function stratAlloc()
    strat = ccall((:SCOTCH_stratAlloc, libscotch), Ptr{Strat}, ())
    strat != C_NULL || error("Error in stratAlloc")
    return strat
end

function stratInit(strat::Ptr{Strat})
    err = ccall((:SCOTCH_stratInit, libscotch), Cint,
                (Ptr{Strat},),
                strat)
    err == 0 || error("Error in stratInit")
    return
end

function stratGraphOrder(strat::Ptr{Strat}, st::String)
    err = ccall((:SCOTCH_stratGraphOrder, libscotch), Cint,
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
    err = ccall((:SCOTCH_graphOrder, libscotch), Cint,
            (Ptr{Graph}, Ptr{Strat}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}), 
            graph,       strat,      pointer(permtab), pointer(peritab), pointer(cblkptr), pointer(rangtab), pointer(treetab))
    err == 0 || error("Error in graphOrder")
    return (permtab, peritab, cblkptr, rangtab, treetab)
end

function orderAlloc()
    optr = ccall((:SCOTCH_orderAlloc, libscotch), Ptr{Ordering}, ())
    optr != C_NULL || error("Error in orderAlloc")
    return optr
end

function graphOrderInit(graph::Ptr{Graph}, ordering::Ptr{Ordering}, permtab::Array{Cint,1}, peritab::Array{Cint,1}, cblkptr::Array{Cint,1}, rangtab::Array{Cint,1}, treetab::Array{Cint,1})
    err = ccall((:SCOTCH_graphOrderInit, libscotch), Cint,
                (Ptr{Graph}, Ptr{Ordering}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}),
                graph, ordering, pointer(permtab), pointer(peritab), pointer(cblkptr), pointer(rangtab), pointer(treetab))
    err == 0 || error("Error in graphOrderInit")
    return
end

function graphOrderComputeList(graph::Ptr{Graph}, ordering::Ptr{Ordering}, listtab::Array{Cint,1}, strat::Ptr{Strat})
    err = ccall((:SCOTCH_graphOrderComputeList, libscotch), Cint,
                (Ptr{Graph}, Ptr{Ordering}, Cint, Ptr{Cint}, Ptr{Strat}),
                graph, ordering, Cint(length(listtab)), pointer(listtab), strat)
    err == 0 || error("Error in graphOrderComputeList")
    return
end

function graphOrderCompute(graph::Ptr{Graph}, ordering::Ptr{Ordering}, strat::Ptr{Strat})
    err = ccall((:SCOTCH_graphOrderCompute, libscotch), Cint,
                (Ptr{Graph}, Ptr{Ordering}, Ptr{Strat}),
                graph, ordering, strat)
    err == 0 || error("Error in graphOrderCompute")
    return
end

function graphOrderCheck(graph::Ptr{Graph}, ordering::Ptr{Ordering})
    err = ccall((:SCOTCH_graphOrderCheck, libscotch), Cint, 
                (Ptr{Graph}, Ptr{Ordering}),
                graph, ordering)
    err == 0 || error("Error in graphOrderCheck")
end

end # module Scotch



