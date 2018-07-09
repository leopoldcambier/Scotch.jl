libscotch.dylib: scotch_wrapper.c
	gcc-7 -dynamiclib -fpic -o libscotch.dylib scotch_wrapper.c -I$(SCOTCH_DIR)/include/ -L$(SCOTCH_DIR)/lib/ -lscotch -lscotcherr -lm -Wl,-all_load -undefined dynamic_lookup
