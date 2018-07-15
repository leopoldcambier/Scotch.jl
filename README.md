# Scotch.jl

A Julia interface to the Scotch graph partitioner 
Scotch can be obtained at https://www.labri.fr/perso/pelegrin/scotch/

To use the library:
1) Compile Scotch as a *dynamic* shared library (.so on linux, .dylib on mac). Scotch is normally compiled as a static shared library (.a). See src/scotch_wrapper.cpp and src/makefile for an example showing how to easily compile Scotch as a dynamic shared library.
2) Edit libscotch variable in src/Scotch.jl to point to the shared library file
3) Include Scotch.jl and import Scotch
4) Call the routine like you would call Scotch, using the same sequence (alloc/init/use/free/exit).

All function can be used as

```import Scotch
Scotch.[scotch function name](arguments)
```

This is still very experimental and a work in progress
See example.jl for an example
