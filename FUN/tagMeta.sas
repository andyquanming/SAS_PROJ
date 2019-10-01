	%MACRO _tagMeta()  ;
		%LET META = %SYSFUNC(DEQUOTE( &META.)) ; 
		%LET OUTDS = %SYSFUNC(DEQUOTE( &OUTDS.));
		
		%LOCAL OUTLIB DS ;
		%LET OUTLIB = %KSCAN( WORK.&OUTDS. , -2 , . ) ;
		%LET DS = %KSCAN( WORK.&OUTDS. , -1 , . ) ;

		%LOCAL UUID; 
		%LET UUID = &SYSJOBID._&SYSMACRONAME._&SYSINDEX. ; 
		
		PROC SQL ; 
			CREATE TABLE _&UUID._1 AS 
				SELECT MONOTONIC() AS VARNUM , 
                       NAME , 
	                   DESC  
				FROM &META. 
				;
		QUIT; 

		PROC CONTENTS DATA=&OUTDS. NOPRINT OUT=_&UUID._2 ; RUN ; 

		%LOCAL DESCLIST NAMELIST ;
		PROC SQL NOPRINT ; 
			SELECT "LABEL " || KSTRIP( A.NAME ) || " = '" || KSTRIP(B.DESC)  || "' ; "  
			INTO : DESCLIST SEPARATED BY ' '
			FROM _&UUID._2 A 
				INNER JOIN _&UUID._1 B
				ON (A.VARNUM = B.VARNUM) 
			;
		QUIT ; 

		PROC SQL NOPRINT ; 
			SELECT CASE 
					    WHEN KSTRIP(A.NAME) NE KSTRIP(B.NAME) THEN 
					    "RENAME " || KSTRIP( A.NAME ) || " = " || KSTRIP(B.NAME)  || " ; " 
						ELSE " " 
				   END 
			INTO : NAMELIST SEPARATED BY ' '
			FROM _&UUID._2 A 
				INNER JOIN _&UUID._1 B
				ON (A.VARNUM = B.VARNUM) 
			;
		QUIT ; 

		%PUT ***DEBUG*** &NAMELIST. ; 

		PROC DATASETS LIB=&OUTLIB. NODETAILS NOWARN NOLIST ;
			MODIFY &DS. ;
				&DESCLIST.
				&NAMELIST. 
			
		RUN ; 

		PROC DATASETS LIB=WORK NOLIST NOWARN NODETAILS ;
			DELETE _&UUID._: ;
		RUN ; 
	%MEND;
	PROC FCMP OUTLIB=WORK.FUNCS.tagMeta ;
		FUNCTION tagMeta( META $ , OUTDS $ )  ;
			LENGTH RC 8 ;
			RC = run_macro( '_tagMeta' ,META ,OUTDS  ) ;
			return(RC) ;
		endsub ;
	RUN ;
	%ins_func_dict( 元數據管理 , 
                    tagMeta( METADATA ,對應資料集 ) , 
                    "對資料貼上欄位名稱與標籤說明" )
