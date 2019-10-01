	%MACRO _isEqualView() ;
		%LET VIEW1 = %QSYSFUNC(DEQUOTE(%SUPERQ(VIEW1))) ;
		%LET VIEW2 = %QSYSFUNC(DEQUOTE(%SUPERQ(VIEW2))) ; 
		%LET RTN = 0 ; 
		
		%LOCAL UUID ;
		%LET UUID = &SYSJOBID._&sysmacroname._&SYSINDEX. ; 

		PROC SQL NOPRINT OUTOBS=1 ; 
			CREATE TABLE _&UUID._1 AS 
				SELECT * 
				FROM ( %UNQUOTE(&VIEW1.)) 
				;
		QUIT ; 
		PROC CONTENTS DATA= _&UUID._1 OUT=_&UUID._2 NOPRINT ; RUN ;
		%LOCAL JOIN_STMT WHERE_STMT ;
		PROC SQL NOPRINT ; 
			SELECT "A." || KSTRIP( NAME) || " = B." || KSTRIP(NAME)
			INTO : JOIN_STMT SEPARATED BY "AND"
			FROM _&UUID._2
			;
		QUIT; 
		PROC SQL OUTOBS=1 NOPRINT ; 
			SELECT "A." ||KSTRIP(NAME ) || " IS MISSING OR B." || KSTRIP(NAME) || " IS MISSING" 
			INTO : WHERE_STMT 
			FROM _&UUID._2 
			;
		QUIT ;

		PROC SQL NOPRINT ; 
			SELECT COUNT(*) = 0 
			INTO :RTN
			FROM ( 	SELECT * 
				   	FROM ( %UNQUOTE(&VIEW1.) ) A
						FULL JOIN ( SELECT *
							    FROM ( %UNQUOTE(&VIEW2.) ) ) B 
						ON &JOIN_STMT.
					WHERE &WHERE_STMT. )
			;
		QUIT ; 
		PROC DATASETS LIB=WORK NODETAILS NOLIST NOWARN ; 
			DELETE _&UUID.: ;
		RUN ;
	%MEND; 
	PROC FCMP OUTLIB=WORK.FUNCS.isEqualView ;
		FUNCTION isEqualView( VIEW1 $ , VIEW2 $ ) ;
			length RTN 8 ;
			RC = run_macro( '_isEqualView' ,VIEW1 , VIEW2 ,RTN ) ;
			return(RTN) ;
		endsub ;
	RUN ;
	%ins_func_dict( 布林判斷 ,
                    isEqualView( SQL查詢_1 ,SQL查詢_2 ) , 
                    "判斷兩個VIEW是否完整一對一" )
