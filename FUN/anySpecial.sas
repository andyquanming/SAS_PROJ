	%MACRO _anySpecial() ;
		%LET CHAR = %QSYSFUNC(KSTRIP(%QSYSFUNC(DEQUOTE(%SUPERQ(CHAR))))) ;
		%LET rtn = 0 ;

		%IF %SYSEVALF(%SUPERQ(CHAR) = ) %THEN %DO ;
			%RETURN ;	
			%END ;
		%LOCAL i char_i ; 
		%DO i = 1 %TO %KLENGTH(&CHAR.) ;
			%LET char_i = %QKSUBSTR(&CHAR., &I. , 1) ;
			%IF %SYSFUNC(NOTALPHA(&char_i.)) AND 
				%SYSFUNC(NOTDIGIT(&char_i.)) %THEN %DO ; 
				%LET rtn = 1 ;
				%RETURN ;
			%END ;
		%END ;
	%MEND; 
	PROC FCMP OUTLIB=WORK.FUNCS.anySpecial ;
		FUNCTION anySpecial( CHAR $ ) ;
			length rtn 8 ;
			RC = run_macro( '_anySpecial' ,CHAR ,rtn ) ;
			return(rtn) ;
		endsub ;
	RUN ;
	%ins_func_dict( 布林判斷 ,
                    anySpecial( 字串 ) , 
                    "判斷是否存在非英數字元" )
