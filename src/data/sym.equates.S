              dum 0
lab_size      equ   31
label_mask    equ   31

o_labstr      ds    lab_size+1 ; 0
o_labnum      ds    2   ; 16
o_lableft     ds    2   ; 18
o_labright    ds    2   ; 20
o_labprev     ds    2   ; 22
o_lablocal    ds    2   ; 24
o_labtype     ds    2   ; 26
o_labval      ds    4   ; 28

sym_size      equ   *
              dend

