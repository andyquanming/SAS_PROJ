/*程式名稱	: mcr_tagMeta                               */
/*作者	  : Andy                                       */
/*處理概要	: 將產出資料集至字典中找尋欄位標籤和欄位貼上      */
/*輸    入  : 資料集                                      */
/*輸    出  :   										   */
%MACRO mcr_tagMeta( OUTDS , META= )  ;
	
	%LET OUTDS = %SYSFUNC(DEQUOTE( &OUTDS.));
	%IF %SYSEVALF(%SUPERQ(META) ^= ,BOOLEAN ) %THEN %DO ; 
		%LET META = %SYSFUNC(DEQUOTE( &META.)) ; 
		%LET META = %UPCASE(%SUPERQ(META)) ;
		%END; 
	%ELSE %DO ; 
		%LET META = MET.MET_COL_LABEL(WHERE=(TABLE=(%STR(%')%UPCASE(%KSCAN(&OUTDS. , -1 , %STR(.)))%STR(%')))) ;
		%END ;	

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
