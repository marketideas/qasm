                              ;lst off
            xc    off         
            xc                
            xc                

MXX         =     %00         

            mx    MXX         
            org   $4000       

dp          =     $A5         
expr        =     $0405       
lexpr       =     $010203     
immed       =     $123456     
neg         equ   -16         

]var1 		= v1234

                              ;lst off
start00                      
            brk               ;$00
            ora   (dp,x)      
            cop   $BA         
            ora   $BC,S       
            tsb   dp          
            ora   dp          
            asl   dp          
            ora   [dp]        
            php               
            ora   #immed      
            asl               
            phd               
            tsb   expr        
            ora   expr        
            asl   expr        
            oral  lexpr       
                              ;end

start10                       
            bpl   start10     
            ora   (dp),y      
            ora   (dp)        
            ora   (dp,s),y    
            trb   dp          
            ora   dp,x        
            asl   dp,x        
            ora   [dp],y      
            clc               
            ora   expr,y      
            inc               
            tcs               
            trb   expr        
            ora   expr,x      
            asl   expr,x      
            oral  lexpr,x     

start20                       
            jsr   expr        
            and   (dp,x)      
            jsl   lexpr       
            and   dp,s        
            bit   dp          
            and   dp          
            rol   dp          
            and   [dp]        
            plp               
            and   #immed      
            rol               
            pld               
            bit   expr        
            and   expr        
            rol   expr        
            andl  lexpr       

start30                       
            bmi   start30     
            and   (dp),y      
            and   (dp)        
            and   (dp,s),y    
            bit   dp,x        
            and   dp,x        
            rol   dp,x        
            and   [dp],y      
            sec               
            and   expr,y      
            dec               
            tsc               
            bit   expr,x      
            and   expr,x      
            rol   expr,x      
            andl  lexpr,x     

start40                       
            rti               
            eor   (dp,x)      
            wdm   $01         
            eor   dp,s        
            mvp   dp,dp+1     
            eor   dp          
            lsr   dp          
            eor   [dp]        
            pha               
            eor   #immed      
            lsr               
            phk               
            jmp   expr        
            eor   expr        
            lsr   expr        
            eorl  lexpr       

start50                       
            bvc   start50     
            eor   (dp),y      
            eor   (dp)        
            eor   (dp,s),y    
            mvn   dp,dp+1     
            eor   dp,x        
            lsr   dp,x        
            eor   [dp],y      
            cli               
            eor   expr,y      
            phy               
            tcd               
            jml   lexpr       
            eor   expr,x      
            lsr   expr,x      
            eorl  lexpr,x     

start60                       
            rts               
            adc   (dp,x)      
            per   start60     
            adc   dp,s        
            stz   dp          
            adc   dp          
            ror   dp          
            adc   [dp]        
            pla               
            adc   #immed      
            ror               
            rtl               
            jmp   (expr)      
            adc   expr        
            ror   expr        
            adcl  lexpr       

start70                       
            bvs   start70     
            adc   (dp),y      
            adc   (dp)        
            adc   (dp,s),y    
            stz   dp,x        
            adc   dp,x        
            ror   dp,x        
            adc   [dp],y      
            sei               
            adc   expr,y      
            ply               
            tdc               
            jmp   (expr,x)    
            adc   expr,x      
            ror   expr,x      
            adcl  expr,x      

start80                       
            bra   start80     
            sta   (dp,x)      
            brl   start80     
            sta   dp,s        
            sty   dp          
            sta   dp          
            stx   dp          
            sta   [dp]        
            dey               
            bit   #immed      
            txa               
            phb               
            sty   expr        
            sta   expr        
            stx   expr        
            stal  lexpr       

start90                       
            bcc   start90     
            sta   (dp),y      
            sta   (dp)        
            sta   (dp,s),y    
            sty   dp,x        
            sta   dp,x        
            stx   dp,y        
            sta   [dp],y      
            tya               
            sta   expr,y      
            txs               
            txy               
            stz   expr        
            sta   expr,x      
            stz   expr,x      
            stal  lexpr,x     

startA0                       
            ldy   #immed      
            lda   (dp,x)      
            ldx   #immed      
            lda   dp,s        
            ldy   dp          
            lda   dp          
            ldx   dp          
            lda   [dp]        
            tay               
            lda   #immed      
            tax               
            plb               
            ldy   expr        
            lda   expr        
            ldx   expr        
            ldal  lexpr       

startB0                       
            bcs   startB0     
            lda   (dp),y      
            lda   (dp)        
            lda   (dp,s),y    
            ldy   dp,x        
            lda   dp,x        
            ldx   dp,y        
            lda   [dp],y      
            clv               
            lda   expr,y      
            tsx               
            tyx               
            ldy   expr,x      
            lda   expr,x      
            ldx   expr,y      
            ldal  lexpr,x     

startC0                       
            cpy   #immed      
            cmp   (dp,x)      
            rep   #$FF        
            mx    MXX         
            cmp   dp,s        
            cpy   dp          
            cmp   dp          
            dec   dp          
            cmp   [dp]        
            iny               
            cmp   #immed      
            dex               
            wai               
            cpy   expr        
            cmp   expr        
            dec   expr        
            cmpl  lexpr       

startD0                       
            bne   startD0     
            cmp   (dp),y      
            cmp   (dp)        
            cmp   (dp,s),y    
            pei   dp          
            cmp   dp,x        
            dec   dp,x        
            cmp   [dp],y      
            cld               
            cmp   expr,y      
            phx               
            stp               
            jml   [lexpr]     
            cmp   expr,x      
            dec   expr,x      
            cmpl  lexpr,x     

startE0                       
            cpx   #immed      
            sbc   (dp,x)      
            sep   #$FF        
            mx    MXX         
            sbc   dp,s        
            cpx   dp          
            sbc   dp          
            inc   dp          
            sbc   [dp]        
            inx               
            sbc   #immed      
            nop               
            xba               
            cpx   expr        
            sbc   expr        
            inc   expr        
            sbcl  lexpr       

startF0                       
            beq   startF0     
            sbc   (dp),y      
            sbc   (dp)        
            sbc   (dp,s),y    
            pea   startF0     
            sbc   dp,x        
            inc   dp,x        
            sbc   [dp],y      
            sed               
            sbc   expr,y      
            plx               
            xce               
            jsr   (expr,x)    
            sbc   expr,x      
            inc   expr,x      
            sbcl  lexpr,x     
            lst   off         
            sav   ./test.bin  

