* Merlin 8/16 User's Manual - DEMO PROGRAM 1
* Assemble / run: JSR $8000 rings the bell.

              ORG   $8000
BELL          EQU   $FBDD
START         JSR   BELL
              RTS
