	%MACRO _viewCompr() ;
		%LET view_1 = %SYSFUNC(DEQUOTE( %SUPERQ(view_1))) ;
		%IF %SYSFUNC(COUNTW( %SUPERQ(view_1) , %STR( ) ) ) > 1 %THEN %DO ; 
				%LET view_1 = %STR(%() %SUPERQ(view_1) %STR(%)) ; 
				%END ;
		%LET view_2 = %SYSFUNC(DEQUOTE( %SUPERQ(view_2))) ;
		%IF %SYSFUNC(COUNTW( %SUPERQ(view_2) , %STR( ) ) ) > 1 %THEN %DO ; 
				%LET view_2 = %STR(%() %SUPERQ(view_2) %STR(%)) ; 
				%END ;
		%LET joinKey = %SYSFUNC(DEQUOTE(%SUPERQ(joinKey))) ;
		%LET DIFF_RPT = %SYSFUNC(DEQUOTE(%SUPERQ(DIFF_RPT))) ;
		
		%LOCAL UUID ; 
		%LET UUID = &SYSJOBID._&SYSMACRONAME._&SYSINDEX. ; 
		
		PROC SQL OUTOBS=1 ; 
			CREATE TABLE _&UUID._1 AS 
				SELECT * 
				FROM &view_1. 
				;
			CREATE TABLE _&UUID._2 AS 
				SELECT * 
				FROM &view_2. 
				;
		QUIT ;  
		%LOCAL COMM_DIM 
	           RENAME_STMT 
	           CMPR_STMT 
			   WHERE_DIFF_STMT
	           JOIN_STMT 
	           ;

		PROC SQL NOPRINT ; 
			SELECT A.NAME 
			INTO : COMM_DIM SEPARATED BY ',' 
			FROM ( SELECT NAME 
					FROM DICTIONARY.COLUMNS  
					WHERE LIBNAME = "WORK" 
					AND MEMNAME = %UPCASE("_&UUID._1") ) A 
			INNER JOIN 
				( SELECT NAME 
			      FROM DICTIONARY.COLUMNS  
				  WHERE LIBNAME = "WORK" 
				  AND MEMNAME = %UPCASE("_&UUID._2") ) B 
			ON A.NAME = B.NAME 
			;
		QUIT ;

		%IF %SYSEVALF(%SUPERQ(COMM_DIM) ^= ,BOOLEAN) %THEN %DO ;
			%LET RENAME_STMT = %STR(,) %SYSFUNC(doOver( %SUPERQ(COMM_DIM) , 
	                                                    B.? AS _?         ,
	                                                    %STR(,) ));
			%LET CMPR_STMT = %STR(,) 
	                         %SYSFUNC(doOver( %SUPERQ(COMM_DIM) ,
		                              CASE WHEN A.? NE B.? THEN 1 ELSE 0 END AS CMP_? ,
	                                  %STR(,))) ;
			%LET WHERE_DIFF_STMT = WHERE %SYSFUNC(doOver( %SUPERQ(COMM_DIM) ,
	                                              CALCULATED CMP_? = 1         ,
												   %STR( OR ) )) ;
		%END;
		%LET JOIN_STMT = %SYSFUNC(doOver(%SUPERQ(joinKey), A.? = B.? , %STR( AND ) )) ;
		%LOCAL joinKey_1 ;
		%LET joinKey_1 = %SYSFUNC(KSCAN( %SUPERQ(joinKey),1,%STR(,))) ;
		PROC SQL ; 
			CREATE TABLE &DIFF_RPT. AS 
				SELECT CASE 
							WHEN A.&joinKey_1. IS MISSING THEN "ONLY_2"  
							WHEN B.&joinKey_1. IS MISSING THEN "ONLY_1" 
							ELSE "BOTH"
					   END AS _CASE ,
	                   A.*  &RENAME_STMT. &CMPR_STMT. ,B.*
				FROM &view_1. A
				FULL JOIN &view_2. B
					ON &JOIN_STMT.
				&WHERE_DIFF_STMT.
				;
		QUIT ;
		PROC DATASETS LIB=WORK NOLIST NODETAILS NOWARN ; 
			DELETE _&UUID._: ;
		RUN ;
	%MEND;
	PROC FCMP OUTLIB=WORK.FUNCS.viewCompr ;
		FUNCTION viewCompr( view_1 $ ,view_2 $ ,joinKey $ ,DIFF_RPT $ ) ;
			length RC 8 ;
			RC = run_macro( '_viewCompr' ,
                            view_1 ,
							view_2 ,
							joinKey ,
							DIFF_RPT ) ;
			return(RC) ;
		endsub ;
	RUN ;
	%ins_func_dict( 資料集探索                 , 
                    viewCompr( 表格VIEW1 ,
                               表格VIEW2 ,
                               串接變數   ,
                               比對結果資料集 ) , 
			        "比對兩個VIEW資料內容的差異比對" )
