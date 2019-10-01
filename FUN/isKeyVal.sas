	%MACRO _isKeyVal()  ;
		%LET TBL_VIEW = %SYSFUNC(DEQUOTE(%SUPERQ(TBL_VIEW))) ;
		%LET KEYs = %SYSFUNC(DEQUOTE(%SUPERQ(KEYs)));
		%LET Val = %SYSFUNC(DEQUOTE(%SUPERQ(Val))) ;
		%LET dup_DTL = %SYSFUNC(DEQUOTE(%SUPERQ(dup_DTL))) ; 
		%LET rtn_sts = 0 ; 

		%IF %SYSFUNC(COUNTW( %SUPERQ(TBL_VIEW) , %STR( ) ) ) > 1 %THEN %DO ; 
			%LET TBL_VIEW = %STR(%() %SUPERQ(TBL_VIEW) %STR(%)) ; 
			%END ;

		PROC SQL ; 
			CREATE TABLE &dup_DTL. AS
				SELECT &KEYs. , COUNT(DISTINCT &Val.) AS &Val._CNT , &Val. 
				FROM &TBL_VIEW. 
				GROUP BY &KEYs. 
				HAVING &Val._CNT >= 2 
				;
		QUIT ; 

		%LOCAL dup_cnt ; 
		PROC SQL NOPRINT ; 
			SELECT COUNT(*) 
			INTO : dup_cnt 
			FROM &dup_DTL. 
			;
		QUIT ; 
		%IF %SYSEVALF( &dup_cnt. > 0 ) %THEN %DO ; 
			%LET rtn_sts = 1 ;
			%END; 

	%MEND; 
	PROC FCMP OUTLIB=WORK.FUNCS.isKeyVal ;
		FUNCTION isKeyVal( TBL_VIEW $ , KEYS $ , VAL $ , dup_DTL $ ) ;
			length rtn_sts 8 ;
			RC = run_macro( '_isKeyVal' ,
                            TBL_VIEW     , 
                            KEYS         ,
							VAL          , 
							dup_DTL      ,
                            rtn_sts ) ;
			return(rtn_sts) ;
		endsub ;
	RUN ;
	%ins_func_dict( 布林判斷 , 
                    isKeyVal( 資料集或view ,群組鍵值 ,判斷唯一性欄位 ,重複資料 ) , 
                    "判斷串接條件是否會造成資料膨脹" )
