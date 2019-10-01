	%MACRO _loadDsMeta()  ;
		%LET DSLIST = %SYSFUNC(DEQUOTE(%SUPERQ(DSLIST)));
		%LET OUTMETA = %SYSFUNC(DEQUOTE(%SUPERQ(OUTMETA)));

		%LOCAL UUID ; 
		%LET UUID = &SYSJOBID._&SYSMACRONAME._&SYSINDEX. ;
		PROC CONTENTS DATA=SASHELP.AACOMP OUT=&OUTMETA. NOPRINT ;RUN ; 
		DATA &OUTMETA. ;
			IF 0 THEN SET &OUTMETA. ; 
			STOP ; 
		RUN ;

		%LOCAL i DS_i; 

		%DO i = 1 %TO %SYSFUNC(COUNTW(%SUPERQ(DSLIST) ,%STR(,) )) ;
			%LET DS_i = %KSCAN(%SUPERQ(DSLIST) ,&i. , %STR(,) ); 
			PROC CONTENTS DATA=&DS_i. OUT=_&UUID._&I. NOPRINT ; RUN ; 
			PROC APPEND BASE=&OUTMETA. DATA=_&UUID._&I. FORCE ; RUN ;
		%END; 
		PROC DATASETS LIB=WORK NODETAILS NOLIST NOWARN ;
			DELETE _&UUID._: ;
		RUN ; 
	%MEND; 
	PROC FCMP OUTLIB=WORK.FUNCS.loadDsMeta ;
		FUNCTION loadDsMeta( DSLIST $ ,OUTMETA $ ) ;
			length RC 8 ;
			RC = run_macro( '_loadDsMeta' ,
                            DSLIST ,
                            OUTMETA ) ;
			return(RC) ;
		endsub ;
	RUN ;
	%ins_func_dict( 元數據管理 , 
                    loadDsMeta( 資料集清單 , 結果資料集 ) , 
                    "匯入資料集清單的METADATA" )
