SCOTCH_DIR = /Users/lcambier/Stanford/scotch_6.0.5a

libscotch.dylib: scotch_wrapper.c
        gcc-7 -dynamiclib -fpic -o $(SCOTCH_DIR)/lib/libscotch.dylib scotch_wrapper.c -I$(SCOTCH_DIR)/include/ -L$(SCOTCH_DIR)/lib/ -lscotch -lscotcherr -lm -Wl,-all_load -undefined dynamic_lookup
