	PROC FORMAT;   
	   picture bigmoney (fuzz=0 round)
	      0-<10000='0,000 ��' (prefix='$')
	      1E04-<100000000='0,000.0 �U' (prefix='$' mult=1E-03)
	      1E08-<1000000000000='0,000.0 ��' (prefix='$' mult=1E-07)
	      1E12-<10000000000000000='0,000.0 ��' (prefix='$' mult=1E-011)
	    ;
	RUN;
	PROC FCMP OUTLIB=WORK.FUNCS.bigMoney ;
		FUNCTION bigMoney( money ) $32 ;
			return(putn( money, "bigmoney.")) ;
		ENDSUB ;
	RUN ;
	%ins_func_dict( �榡�ഫ ,
                    bigMoney( �j�B���� ) , 
                    "�ন�x����B(��/�U/��/��)" )
