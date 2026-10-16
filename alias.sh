#!/bin/bash

export BASE=$PWD

export PRODOS_IMAGE_DIR=$BASE/images
export PRODOS_WORK_VOL=boot.2mg
export PRODOS_WORK_SIZE=32M

alias koin='repo koin'
alias iigs='repo m65816 && cd fpga'
alias qasm='repo qasm'

alias gss='git status'

alias u1='daemon -i --chdir=$PWD -- xfce4-terminal --display $DISPLAY -x tio -b 19200 /dev/ttyUSB1'
alias base='cd $BASE'

export PATH="$PATH":$BASE/bin
