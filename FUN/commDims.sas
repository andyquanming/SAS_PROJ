	%MACRO _commDims()  ;
		%LET DS_List = %QSYSFUNC(DEQUOTE( &DS_List. ) ) ;
		%LET rtn_Dim = ;

		%LOCAL i DS_NAME DS UUID;
		%LOCAL MERGE_stmt ALL_STMT ;
		%LET MERGE_stmt = ;
		%LET UUID = &SYSJOBID._&sysmacroname._&SYSINDEX. ; 
		%DO i = 1 %TO %SYSFUNC(COUNTW( &DS_List. , %STR(,) ) ) ;
			%LET DS = %SYSFUNC(KSCAN( &DS_List. , &i. , %STR(,) ) ) ; 
			%LET DS_NAME = %SYSFUNC( KSCAN( %SYSFUNC(KSCAN( &DS. , -1 ,%STR(.) ) ) , 1 , %STR(%() ) );
			PROC CONTENTS DATA=&DS. NOPRINT NODETAILS OUT= _&UUID._&DS_NAME.(KEEP=NAME TYPE LENGTH RENAME=(TYPE = &DS_NAME._TYPE LENGTH=&DS_NAME._LENGTH )) ; RUN ; 
			PROC SORT DATA=_&UUID._&DS_NAME. NODUPKEY ;
				BY NAME ; 
			RUN ;
			%LET MERGE_stmt = &MERGE_stmt. _&UUID._&DS_NAME.(IN=IN_&DS_NAME.) ;
			%IF &i. > 1 %THEN %DO ;
				%LET ALL_STMT = &ALL_STMT. AND %STR( ) ;
				%END ;
			%LET ALL_STMT = &ALL_STMT. IN_&DS_NAME. ;
		%END ;

		DATA _&UUID._1 ; 
			MERGE &MERGE_stmt. ;
			BY NAME ;
			IF &ALL_STMT. THEN OUTPUT ;  
		RUN ;

		PROC SQL NOPRINT  ; 
			SELECT NAME 
			INTO :rtn_Dim SEPARATED BY ","
			FROM _&UUID._1
			;
			QUIT;
		PROC DATASETS LIB=WORK NOLIST NOWARN NODETAILS ;
			DELETE _&UUID._: ;
		RUN;

	%MEND; 
	PROC FCMP OUTLIB=WORK.FUNCS.commDims ;
		FUNCTION commDims( DS_List $ ) $&STRING_MAX_LEN. ;
			length rtn_dim $&STRING_MAX_LEN. ;
			RC = run_macro( '_commDims' ,
                            DS_List ,
                            rtn_dim ) ;
			return(rtn_dim) ;
		endsub ;
	RUN ;
	%ins_func_dict( 資料集探索 , 
                    commDims( 資料集清單 ) ,
                    "資料集找出共同維度" )
