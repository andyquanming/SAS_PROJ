	%MACRO _metaQry()  ;
		%LOCAL UUID ; 
		%LET UUID = &SYSJOBID._&sysmacroname._&SYSINDEX. ; 

		%LET SQL = %SYSFUNC(DEQUOTE( %SUPERQ(SQL) ) ) ; 

		PROC SQL OUTOBS=1 ;
			CREATE TABLE _&UUID._1 AS 
			&SQL.
			;
		QUIT ;
		PROC CONTENTS DATA=_&UUID._1 OUT=_&UUID._2 NOPRINT ; RUN ; 
		PROC SQL NOPRINT ; 
			SELECT UPCASE(NAME)
			INTO :meta SEPARATED BY ",%SYSFUNC(BYTE(10))"
			FROM _&UUID._2
			;
		QUIT;
		PROC DATASETS LIB=WORK NODETAILS NOLIST NOWARN ;
			DELETE _&UUID._: ; 
		RUN ; 
	%MEND; 
	PROC FCMP OUTLIB=WORK.FUNCS.metaQry ;
		FUNCTION metaQry( SQL $ ) $&STRING_MAX_LEN. ;
			length meta $&STRING_MAX_LEN. ;
			RC = run_macro( '_metaQry' , SQL ,meta ) ;
			return(meta) ;
		endsub ;
	RUN ;
	%ins_func_dict( 元數據管理 , 
                    metaQry( SQL查詢 ) , 
                    "產出SQL結果欄位清單" )
