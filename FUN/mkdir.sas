	%MACRO _mkdir() ;
		%LET dir = %SYSFUNC(DEQUOTE(&DIR.)) ;
		X "mkdir &DIR. " ;
	%MEND; 
	PROC FCMP OUTLIB=WORK.FUNCS.mkdir ;
		FUNCTION mkdir( DIR $ ) ;
			length RC 8 ;
			RC = run_macro( '_mkdir' ,
                            DIR      ) ;
			return(RC) ;
		ENDSUB ;
	RUN ;
	%ins_func_dict( �t�θ�T             , 
                    mkdir( ��Ƨ����| )  , 
			        "�إ߸�Ƨ�"   )
