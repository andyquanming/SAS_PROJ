	PROC FORMAT;   
	   picture bigmoney (fuzz=0 round)
	      0-<10000='0,000 元' (prefix='$')
	      1E04-<100000000='0,000.0 萬' (prefix='$' mult=1E-03)
	      1E08-<1000000000000='0,000.0 億' (prefix='$' mult=1E-07)
	      1E12-<10000000000000000='0,000.0 兆' (prefix='$' mult=1E-011)
	    ;
	RUN;
	PROC FCMP OUTLIB=WORK.FUNCS.bigMoney ;
		FUNCTION bigMoney( money ) $32 ;
			return(putn( money, "bigmoney.")) ;
		ENDSUB ;
	RUN ;
	%ins_func_dict( 格式轉換 ,
                    bigMoney( 大額金錢 ) , 
                    "轉成台制金額(元/萬/億/兆)" )
