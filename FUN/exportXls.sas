	%MACRO _exportXls()  ;
		%LET DS = %SYSFUNC(DEQUOTE( %SUPERQ(DS) ) ) ; 
		%LET outXls = %SYSFUNC(STRIP(%SYSFUNC(DEQUOTE(%SUPERQ(outXls)))));
		
		%LOCAL DS_NAME ; 
		%LET DS_NAME = %SYSFUNC(KSCAN( %SYSFUNC(KSCAN( %SUPERQ(DS) , 1 , %STR(%() ) ) , -1 , %STR(.) ) ) ;
		PROC EXPORT DATA=&DS.( OBS=1000000 ) 
	                OUTFILE="&outXls."
					DBMS=XLSX REPLACE ;
					SHEET=%SYSFUNC(KSTRIP(&DS_NAME.)) ;
		RUN ;
	%MEND;
	PROC FCMP OUTLIB=WORK.FUNCS.exportXls ;
		FUNCTION exportXls( DS $ ,outXls $ ) ;
			length RC 8 ;
			RC = run_macro( '_exportXls' ,
                            DS ,
                            outXls ) ;
			return(RC) ;
		endsub ;
	RUN ;
	%ins_func_dict( 元數據管理 ,
                    exportXls(資料集 ,產出檔名) , 
                    "產出XLS檔案" )
