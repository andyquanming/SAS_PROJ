	%MACRO _rmdir() ;
		%LET dir = %SYSFUNC(DEQUOTE(&DIR.)) ;
		X "rmdir &DIR. /s /q" ;
	%MEND; 
	PROC FCMP OUTLIB=WORK.FUNCS.rmdir ;
		FUNCTION rmdir( DIR $ ) ;
			length RC 8 ;
			RC = run_macro( '_rmdir' ,
                            DIR      ) ;
			return(RC) ;
		ENDSUB ;
	RUN ;
	%ins_func_dict( �t�θ�T             , 
                    rmdir( ��Ƨ����| )  , 
			        "�R���ǤJ��Ƨ�"   )
