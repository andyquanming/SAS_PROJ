	%MACRO _doPivot()  ;
		%LET DS = %SYSFUNC(DEQUOTE(%SUPERQ(DS))) ; 
		%LET row_group = %SYSFUNC(DEQUOTE(%SUPERQ(row_group))) ;
		%LET col_group = %SYSFUNC(DEQUOTE(%SUPERQ(col_group))) ;
		%LET STAT_GROUP = %SYSFUNC(DEQUOTE(%SUPERQ(STAT_GROUP))) ;
		%LET PIVOT = %SYSFUNC(DEQUOTE(%SUPERQ(PIVOT)));

		%LOCAL all_group ; 
		%LET all_group = %SYSFUNC(CATX( %STR(,) , %SUPERQ(row_group) , %SUPERQ(col_group) )) ;

		%LOCAL UUID ; 
		%LET UUID = &SYSJOBID._&SYSMACRONAME._&SYSINDEX. ;

		%LOCAL i VAR VARs STAT_STMT STAT;
		%LET VAR = ; 
		%LET VARs = ; 
		%LET STAT_STMT = ; 
		%LET STAT = ;  
		%DO i = 1 %TO %SYSFUNC(COUNTW( %SUPERQ(STAT_GROUP) ,%STR(,) ));
			%LET STAT = %KSCAN(%SUPERQ(STAT_GROUP) , &I. ,%STR(,) ) ;
			%LET VAR = %SYSFUNC(TRANWRD( %SUPERQ(STAT) , %STR(%() , %STR(_) )) ;
			%LET VAR = %SYSFUNC(KCOMPRESS(%SUPERQ(VAR) , () )) ;
			%LET VARs = &VARs. &VAR. ;
			
			%IF %SYSEVALF(%SUPERQ(STAT_STMT) ^= ,BOOLEAN) %THEN %DO ; 
				%LET STAT_STMT = &STAT_STMT. %STR(,) &STAT. AS &VAR. ;
				%END; 
			%ELSE %DO ; 
				%LET STAT_STMT = &STAT. %STR(AS) &VAR. ;
				%END; 
			%END;
		%LOCAL SELECT_STMT ;
		%LET SELECT_STMT = &all_group. ; 
		%IF %SYSEVALF(%SUPERQ(SELECT_STMT) ^= , BOOLEAN) %THEN %DO ; 
			%IF %SYSEVALF(%SUPERQ(STAT_STMT) ^= , BOOLEAN) %THEN %DO ; 
				%LET SELECT_STMT = &SELECT_STMT. %STR(,) &STAT_STMT. ;
				%END;
			%END;

		PROC SQL ; 
			CREATE TABLE _&UUID._1 AS 
				SELECT &SELECT_STMT. 
				FROM &DS. 
				%IF %SYSEVALF(%SUPERQ(ALL_GROUP) ^= ,BOOLEAN) %THEN %DO ;
					GROUP BY &all_group.
					%END;  
				;
		QUIT ;

		PROC SORT SORTSIZE=MAX 
	              THREADS 
				  DATA=_&UUID._1  ;
			BY %SYSFUNC(doOver( %SUPERQ(all_group) , ? , %str( ) )) ;
		RUN ;
		
		PROC TRANSPOSE DATA=_&UUID._1 out=&PIVOT. prefix=_ ;
			%IF %SYSEVALF(%SUPERQ(row_group) ^= ,boolean) %THEN %DO ; 
				BY %SYSFUNC(tranwrd(%SUPERQ(row_group) , %STR(,) , %STR( ) )) ;
				%END; 
			%IF %SYSEVALF(%SUPERQ(col_group) ^= ,boolean) %THEN %DO ; 
				ID %SYSFUNC(tranwrd(%SUPERQ(col_group) , %STR(,) , %STR( ) )) ;
				%END; 
			%IF %SYSEVALF(%SUPERQ(STAT_GROUP) ^= , boolean) %THEN %DO ; 
				VAR &VARs. ;
				%END; 
		RUN;

		PROC DATASETS LIB=WORK NOLIST NODETAILS NOWARN ;
			DELETE _&UUID._: ; 
		RUN ;
	%MEND; 
	PROC FCMP OUTLIB=WORK.FUNCS.doPivot ;
		FUNCTION doPivot( DS $ ,
                          row_group $ ,
                          col_group $ , 
                          STAT_GROUP $ , 
                          PIVOT $ )  ;
			length rc $&STRING_MAX_LEN. ;
			RC = run_macro( '_doPivot' ,
                            DS ,
                            row_group ,
                            col_group ,
							STAT_GROUP ,
                            PIVOT ) ;
			return(rc) ;
		endsub ;
	RUN ;
	%ins_func_dict( 元數據管理 , 
                    doPivot( 資料集 ,
                             列群組清單 ,
                             欄群組清單 ,
                             統計清單   ,
                             產出資料集 ) , 
                    "對資料進行樞紐分析" )
