# Scotch.jl

A Julia interface to the Scotch graph partitioner (https://www.labri.fr/perso/pelegrin/scotch/)

To use the library:
    1) Compile Scotch as a *dynamic* shared library (.so on linux, .dylib on mac)
    2) Edit libscotch variable in src/Scotch.jl to point to the shared library
    3) Include Scotch.jl and import Scotch
    4) Call the routine like you would call Scotch

All function can be used as

import Scotch

Scotch.[scotch function](arguments)

This is still very experimental and a work in progress
