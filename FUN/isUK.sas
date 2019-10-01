	%MACRO _isUK()  ; 
		%LET DS = %SYSFUNC(DEQUOTE( &DS. )) ; 
		%LET GRAIN_VARS = %SYSFUNC(DEQUOTE(%SUPERQ(GRAIN_VARS))) ;
		%LET rtn_unique = 0 ;
		
		%IF %SYSFUNC(COUNTW( %SUPERQ(DS) , %STR( ) ) ) > 1 %THEN %DO ; 
			%LET DS = %STR(%() %SUPERQ(DS) %STR(%)) ; 
			%END ;

		%LOCAL DUP UUID;
		%LET UUID = &SYSJOBID._&SYSMACRONAME._&SYSINDEX. ; 
		PROC SQL OUTOBS=1 NOPRINT  ;
			CREATE TABLE _&UUID._1 AS  
				SELECT &GRAIN_VARS. , COUNT(*) AS CNT
					   FROM &DS. 
		               GROUP BY &GRAIN_VARS. 
		               HAVING CNT >= 2 
			;
		QUIT ;
		PROC SQL ; 
			SELECT COUNT(*) 
			INTO :DUP 
			FROM _&UUID._1 
			;
		QUIT ;
		%IF &dup. = 0 %THEN %DO ;
			%LET rtn_unique = 1 ;
		%END;
	 
	%MEND;
	PROC FCMP OUTLIB=WORK.FUNCS.isUK ;
		FUNCTION isUK( DS $ ,GRAIN_VARS $ ) ;
			length rtn_unique 8 ;
			RC = run_macro( '_isUK' ,
							DS ,
                            GRAIN_VARS ,
                            rtn_unique ) ;
			return(rtn_unique) ;
		endsub ;
	RUN ;
	%ins_func_dict( 布林判斷 , 
                    isUK( 資料集/VIEW ,唯一性欄位 ) , 
                    "判斷欄位的唯一性" )
