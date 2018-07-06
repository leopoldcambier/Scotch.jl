include("Scotch.jl")

import Scotch

@show Scotch.version()
graph = Scotch.graphAlloc()
Scotch.graphInit(graph)
Scotch.graphLoad(graph, "laplacian_10x10.grf", 1, 0)
(nv, ne) = Scotch.graphSize(graph)
@show nv, ne

strat = Scotch.stratAlloc()
Scotch.stratInit(strat)
Scotch.stratGraphOrder(strat, "n{sep=/levl<10?g:z;}")

(p, ip, nb, cblk, tree) = Scotch.graphOrder(graph, strat)
@show nb

order = Scotch.orderAlloc()
Scotch.graphOrderInit(graph, order, p, ip, nb, cblk, tree)
