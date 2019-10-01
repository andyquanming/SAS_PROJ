	%MACRO _chkVarRel() ; 
		%LET TBL_VIEW = %SYSFUNC(DEQUOTE(%SUPERQ(TBL_VIEW))) ;
		%LET COL1 = %SYSFUNC(DEQUOTE(%SUPERQ(COL1)));
		%LET COL2 = %SYSFUNC(DEQUOTE(%SUPERQ(COL2))) ;
		%LET REL_RTN = "ERR" ;

		%IF %SYSFUNC(COUNTW( %SUPERQ(TBL_VIEW) , %STR( ) ) ) > 1 %THEN %DO ; 
			%LET TBL_VIEW = %STR(%() %SUPERQ(TBL_VIEW) %STR(%)) ; 
			%END ;

		%LOCAL UUID ;
		%LET UUID = &SYSJOBID._&SYSMACRONAME._&SYSINDEX. ;

		%LOCAL _COL1_MANY_COL2 _COL2_MANY_COL1;
		PROC SQL NOPRINT  ; 
			SELECT COUNT(*) 
			INTO : _COL1_MANY_COL2 
			FROM (
				SELECT A.&COL1. , COUNT(DISTINCT A.&COL2. ) AS &COL2._CNT
				FROM ( SELECT DISTINCT &COL1 , &COL2 
				       FROM %UNQUOTE(&TBL_VIEW.) ) A
				GROUP BY A.&COL1. 
				HAVING &COL2._CNT > 1 ) 
			;
			SELECT COUNT(*)  
			INTO : _COL2_MANY_COL1 
			FROM (
				SELECT A.&COL2. , COUNT(DISTINCT A.&COL1. ) AS &COL1._CNT
				FROM ( SELECT DISTINCT &COL1 , &COL2 
				       FROM  %UNQUOTE(&TBL_VIEW.) ) A
				GROUP BY A.&COL2. 
				HAVING &COL1._CNT > 1 ) 
			;
		QUIT ;
		%IF &_COL1_MANY_COL2. > 0 AND &_COL2_MANY_COL1. > 0 %THEN %DO ;
			%LET REL_RTN = "M-N" ; 
			%RETURN ; 
			%END ; 
		%IF &_COL1_MANY_COL2. > 0 AND &_COL2_MANY_COL1. = 0 %THEN %DO ; 
			%LET REL_RTN = "1-N" ;
			%END; 
		%IF &_COL1_MANY_COL2. = 0 AND &_COL2_MANY_COL1. > 0 %THEN %DO ; 
			%LET REL_RTN = "M-1" ;
			%END; 
		%IF &_COL1_MANY_COL2. = 0 AND &_COL2_MANY_COL1. = 0 %THEN %DO ; 
			%LET REL_RTN = "1-1" ;
			%END; 

	%MEND; 
	PROC FCMP OUTLIB=WORK.FUNCS.chkVarRel ;
		FUNCTION chkVarRel( TBL_VIEW $ , COL1 $ , COL2 $ ) $3 ;
			LENGTH REL_RTN $3 ;
			RC = run_macro( '_chkVarRel' ,TBL_VIEW , COL1 ,COL2 ,REL_RTN ) ;
			RETURN(REL_RTN) ;
		ENDSUB ;
	RUN ;
	%ins_func_dict( 資料集探索 ,
                    chkVarRel( 表格或查詢 , 欄位_1 ,欄位_2 ) ,
                    "找出表格/VIEW中兩個欄位的關係" )
