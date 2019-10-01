/*程式名稱	: mcr_tagLabel                               */
/*作者	  : Andy                                       */
/*處理概要	: 將產出資料集至字典中找尋欄位標籤                */
/*輸    入  : 資料集                                      */
/*輸    出  :   										   */
%MACRO mcr_tagLabel( OUTDS , META=MET.MET_COL_LABEL )  ;
	%LET META = %SYSFUNC(DEQUOTE( &META.)) ; 
	%LET OUTDS = %SYSFUNC(DEQUOTE( &OUTDS.));
	
	%LOCAL OUTLIB DS ;
	%LET OUTLIB = %KSCAN( WORK.&OUTDS. , -2 , . ) ;
	%LET DS = %KSCAN( WORK.&OUTDS. , -1 , . ) ;

	%LOCAL UUID ; 
	%LET UUID = &SYSJOBID._&SYSMACRONAME._&SYSINDEX. ; 
	%LOCAL VAR_LIST ; 

	PROC CONTENTS DATA=&OUTDS. OUT= _&UUID._1  NOPRINT ; RUN ; 
	%LET VAR_LIST = ; 
	PROC SQL NOPRINT ; 
		SELECT DISTINCT QUOTE(KSTRIP(NAME))
		INTO :VAR_LIST SEPARATED BY ','
		FROM _&UUID._1 
		;
	QUIT ; 
	PROC SORT THREADS DATA=&META. NODUPKEY ;
		BY NAME ; 
	RUN ; 
	%LOCAL DESCLIST ; 
	%LET DESCLIST= ;
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
