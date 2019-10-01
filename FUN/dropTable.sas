	%MACRO _dropTable()  ;
		%LET DS = %SYSFUNC(DEQUOTE( &DS.)) ; 
		PROC SQL ; 
			DROP TABLE &DS. ;
		QUIT ; 
	%MEND;
	PROC FCMP OUTLIB=WORK.FUNCS.dropTable ;
		FUNCTION dropTable( DS $ )  ;
			length RC 8 ;
			RC = run_macro( '_dropTable' ,DS ) ;
			return(RC) ;
		endsub ;
	RUN ;
	%ins_func_dict( SQL���� ,
                    dropTable( ���W�� ) ,
                    "�R�����w���" )
