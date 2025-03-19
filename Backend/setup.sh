#!/bin/bash
export CONDA_PREFIX=/esat/micas_raid/users/h05d4a_students/conda-env

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CONDA_PREFIX/lib
export OPENLANE_ROOT=$CONDA_PREFIX/share/openlane
export PDK_ROOT=$CONDA_PREFIX/share/pdk
export PDK=sky130A
export STD_CELL_LIBRARY=sky130_fd_sc_hd
export STD_CELL_LIBRARY_OPT=sky130_fd_sc_hd
export TCLLIBPATH=$(find $CONDA_PREFIX/lib -type d -name tcllib*)
export PATH=$CONDA_PREFIX/bin:$PATH:$OPENLANE_ROOT:$OPENLANE_ROOT/scripts
export OPENLANE_LOCAL_INSTALL=1
