/*程式名稱  : mcr_cntValidValue                                  */
/*作者      : Andy                                              */
/*處理概要  : 計算資料集欄位有效值個數                              */
/*輸入      : 表格                                              */
/*輸出      : 表格                                              */
%MACRO mcr_cntValidValue( DS , OUT , MCR ,mcr_loop=rtn_doOver )  ; 
	%LOCAL UUID ; 
	%LET UUID = &SYSJOBID._&SYSINDEX. ; 
	PROC CONTENTS DATA=&DS. OUT=_&UUID._1 NOPRINT ; RUN ; 
	%LOCAL NAMELIST ; 
	%LET mcr_loop = %SYSFUNC(DEQUOTE(%SUPERQ(mcr_loop) ) );
	%IF %SYSMACEXIST(&mcr_loop.) EQ 0 %THEN %DO ;
		%PUT ERROR: macro for loop doing does not exist. &=mcr_loop..  ;
		%abort cancel ;
	%END;
	PROC SQL NOPRINT ; 
		SELECT NAME 
		INTO :NAMELIST SEPARATED BY ','
	    FROM  _&UUID._1
		;
	QUIT;
	DATA &OUT.(KEEP=TOTAL _CNT_: ); 
		FORMAT TOTAL ;
		SET &DS. END=EOF;
		%UNQUOTE(%UNQUOTE(%NRSTR(%%)%SUPERQ(mcr_loop)( "%SUPERQ(NAMELIST)" , 
                                                       ' IF CMISS(?) = 0 THEN _CNT_? + 1 ; ' ) ) )
		TOTAL + 1 ;
		IF EOF THEN OUTPUT &OUT. ;
	RUN ; 
	
	proc transpose data= &OUT.
	               out = &OUT. (rename=(_name_=var) rename=(col1=cnt)  ) ;  
	RUN ;
	PROC SORT DATA=&OUT. THREADS SORTSIZE=MAX ;
		BY DESCENDING CNT ;
	RUN ;

	DATA &OUT. ;
		SET &OUT. ; 
		IF var NE "TOTAL" THEN DO ;
			VAR = KSUBSTR(VAR, 6 ) ;
		END ;
	RUN ;
	
	%GLOBAL &MCR. ;
	proc sql noprint ; 
		select KSTRIP(VAR)
		into : &MCR. SEPARATED BY ',' 
		from &OUT.
		where cnt > 0 AND VAR NE 'TOTAL'
		;
	QUIT;

	%LET &MCR. = %SYSFUNC(TRANWRD( %SUPERQ(&MCR.) ,_CNT_ ,%STR() ) ) ;

	PROC DATASETS LIB=WORK NOLIST NODETAILS NOWARN ; 
		DELETE _&UUID._: ;
	RUN ;

%MEND ;
%ins_mcr_dict( 資料探索 , 
               mcr_cntValidValue( 資料集 ,統計結果 , 統計巨集變數 ) ,
			   計算資料集欄位有效值個數 )
/* 範例說明 */
/*
	data dtgdc001_cat_1 
		 dtgdc001_cat_2
		 dtgdc001_cat_N ; 
		set GD_PROJ.DTGDC001 ;
		if substr(prod_cat ,1,1) = '1' then output dtgdc001_cat_1 ;
		if substr(prod_cat ,1,1) = '2' then output dtgdc001_cat_2 ;
		if cmiss( prod_cat ) then output dtgdc001_cat_N ;
	run ; 
	%mcr_cntValidValue(dtgdc001_cat_N , dtgdc001_cat_N_MISS , CAT_N_VALIDVAR )
	%PUT &CAT_N_VALIDVAR.  ;
	%mcr_cntValidValue(dtgdc001_cat_1 , dtgdc001_cat_1_MISS , CAT_1_VALIDVAR)
	%PUT &CAT_1_VALIDVAR.  ;
	%mcr_cntValidValue(dtgdc001_cat_2 , dtgdc001_cat_2_MISS , CAT_2_VALIDVAR)
	%PUT &CAT_2_VALIDVAR.  ;
*/
