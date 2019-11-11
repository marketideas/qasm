^RESTOREHANDLE  MAC
                PHL   ]1
                Tool  $B02
                <<<
^CHECKHANDLE    MAC
                PHL   ]1
                Tool  $1E02
                <<<
^SETPURGE       MAC
                PHWL  ]1;]2
                Tool  $2402
                <<<
^NEWHANDLE      MAC
                P2SL  ]1
                PxW   ]2;]3
                PHL   ]4
                Tool  $902
                <<<
^GETNEWID       MAC
                P1SW  ]1
                Tool  $2003
                <<<
PHWL            MAC
                PHW   ]1
                PHL   ]2
                <<<
PXW             MAC
                DO    ]0/1
                PHW   ]1
                DO    ]0/2
                PHW   ]2
                DO    ]0/3
                PHW   ]3
                DO    ]0/4
                PHW   ]4
                FIN
                FIN
                FIN
                FIN
                <<<
P2SL            MAC
                PHA
                PHA
                IF    #=]1
                PEA   ^]1
                ELSE
                PHW   ]1+2
                FIN
                PHW   ]1
                <<<
PHL             MAC
                IF    #=]1
                PEA   ^]1
                ELSE
                PHW   ]1+2
                FIN
                PHW   ]1
                <<<
P1SW            MAC
                PHA
                IF    #=]1
                PEA   ]1
                ELSE
                IF    MX/2
                LDA   ]1+1
                PHA
                FIN
                LDA   ]1
                PHA
                FIN
                <<<
PHW             MAC
                IF    #=]1
                PEA   ]1
                ELSE
                IF    MX/2
                LDA   ]1+1
                PHA
                FIN
                LDA   ]1
                PHA
                FIN
                <<<

