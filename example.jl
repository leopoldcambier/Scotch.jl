include("src/Scotch.jl")

import Scotch
using PyPlot

@show Scotch.version()

# Build matrix & graph
graph = Scotch.graphAlloc()
Scotch.graphInit(graph)
n = 100
function laplacian_2d(n)
    L = spdiagm((-ones(n-1), 4*ones(n), -ones(n-1)), (-1, 0, 1))
    return kron(speye(n),L) + kron(L,speye(n))
end
A = laplacian_2d(n)
N = n*n
Scotch.graphBuild(graph, A)
Scotch.graphCheck(graph)
(nv, ne) = Scotch.graphSize(graph)
@show nv, ne

# Create strategy
strat = Scotch.stratAlloc()
Scotch.stratInit(strat)
Scotch.stratGraphOrder(strat, "n{sep=/levl<2?g:z;}")

# Create ordering 
p    = Array{Cint,1}(N)
ip   = Array{Cint,1}(N)
nb   = Array{Cint,1}(1)
cblk = Array{Cint,1}(N+1)
tree = Array{Cint,1}(N)

order = Scotch.orderAlloc()
Scotch.graphOrderInit(graph, order, p, ip, nb, cblk, tree)

Scotch.graphOrderComputeList(graph, order, Array{Cint,1}(1:N), strat)
Scotch.graphOrderCheck(graph, order)

z = zeros(Int64, n*n)
for i = 1:nb[1]
    z[ip[cblk[i]:cblk[i+1]-1]] = i
end
Z = reshape(z, (n, n));
matshow(Z)

# Repartition part of the graph 
strat = Scotch.stratAlloc()
Scotch.stratInit(strat)
Scotch.stratGraphOrder(strat, "n{sep=/levl<4?g:z;}")
list = ip[cblk[1]:cblk[2]-1]

Scotch.graphOrderComputeList(graph, order, list, strat)
Scotch.graphOrderCheck(graph, order)

z = zeros(Int64, n*n)
for i = 1:nb[1]
    z[ip[cblk[i]:cblk[i+1]-1]] = i
end
Z = reshape(z, (n, n));
matshow(Z)
