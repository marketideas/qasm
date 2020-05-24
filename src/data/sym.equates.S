              dum 0
lab_size      equ   31
label_mask    equ   31

o_labstr      ds    lab_size+1 ; 0
o_labnum      ds    2   ; 32
o_lableft     ds    2   ; 34
o_labright    ds    2   ; 36
o_labprev     ds    2   ; 38
o_lablocal    ds    2   ; 40
o_labtype     ds    2   ; 42
o_labval      ds    4   ; 44

sym_size      equ   *
              dend
