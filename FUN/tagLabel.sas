	%MACRO _tagLabel()  ;
		%LET META = %SYSFUNC(DEQUOTE( &META.)) ; 
		%LET OUTDS = %SYSFUNC(DEQUOTE( &OUTDS.));
		
		%LOCAL OUTLIB DS ;
		%LET OUTLIB = %KSCAN( WORK.&OUTDS. , -2 , . ) ;
		%LET DS = %KSCAN( WORK.&OUTDS. , -1 , . ) ;

		%LOCAL UUID ; 
		%LET UUID = &SYSJOBID._&SYSMACRONAME._&SYSINDEX. ; 
		%LOCAL VAR_LIST ; 

		PROC CONTENTS DATA=&OUTDS. OUT= _&UUID._1 NOPRINT ; RUN ; 
		%LET VAR_LIST = ; 
		PROC SQL NOPRINT ; 
			SELECT DISTINCT QUOTE(NAME)
			INTO :VAR_LIST SEPARATED BY ','
			FROM _&UUID._1 
			;
		QUIT ; 
		PROC SORT THREADS DATA=&META. NODUPKEY ;
			BY NAME ; 
		RUN ; 

		PROC SQL NOPRINT;
			SELECT "LABEL " || KSTRIP(NAME) ||  " = '" || KSTRIP(DESC)  || "' ; " 
			INTO : DESCLIST SEPARATED BY ' '
			FROM &META. 
			WHERE NAME IN ( &VAR_LIST. ) 
			;
		QUIT ; 

		PROC DATASETS LIB=&OUTLIB. NODETAILS NOWARN NOLIST ;
			MODIFY &DS. ;
				&DESCLIST.
			
		RUN ; 

		PROC DATASETS LIB=WORK NOLIST NODETAILS NOWARN ; 
			DELETE _&UUID._: ;
		RUN ; 
	%MEND;
	PROC FCMP OUTLIB=WORK.FUNCS.tagLabel;
		FUNCTION tagLabel( META $ , OUTDS $ )  ;
			LENGTH RC 8 ;
			RC = run_macro( '_tagLabel' ,META ,OUTDS  ) ;
			return(RC) ;
		endsub ;
	RUN ;
	%ins_func_dict( 元數據管理 ,
                    tagLabel( METADATA ,對應資料集 ) ,
                    "對資料貼上欄位標籤說明" )
