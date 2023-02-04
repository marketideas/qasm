    lst on
    xc off
    xc
    xc
    org $2000

macro   mac
    lup 4
    lda #$00
    eom

start pha
    
    lup 5
]1  asl
    bcs ]1
    --^
    pla
    macro

    end

