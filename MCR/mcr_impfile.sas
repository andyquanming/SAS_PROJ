/*程式名稱  : mcr_impfile                                        */
/*作者      : Andy                                              */
/*處理概要  : 匯入分隔字符資料集，並讀取 METADATA給出欄位名稱及LABEL  */
/*輸入        : CSV: 來源文字檔 
                DLM: 來源分隔字元
                OUT : SAS DATASET
               */
/*輸出      : 錯誤的維度值( rejectDS ) 錯誤的明細( ERR_PRFIX_ )      */
%MACRO mcr_impfile( CSV , DLM , OUT , getnames=NO , DATAROW = 1 , guessingrows=max , META=  ) ;
	%LOCAL OUT_LIB ; 
	%LOCAL OUT_DS ; 
	%LOCAL i UUID ;
	%LET UUID = &SYSJOBID._&SYSINDEX. ;
	%LET CSV = %SYSFUNC(DEQUOTE( %SUPERQ(CSV) ) ) ;
	%LET getnames = %SYSFUNC(DEQUOTE( %SUPERQ(getnames) ) ) ; 
	%LET guessingrows = %SYSFUNC(DEQUOTE( %SUPERQ( guessingrows ) ) ) ;
	%LET DLM = %QSYSFUNC(DEQUOTE( %SUPERQ(DLM) ) ) ;
	%IF &getnames. eq YES AND &DATAROW. EQ 1 %THEN %DO ; 
		%LET DATAROW = 2 ; 
		%END ; 
	%LET OUT_LIB = %SYSFUNC(KSCAN( WORK.%SUPERQ( OUT ) , 1 , %STR(.) ) ) ;
	%LET OUT_DS = %SYSFUNC(KSCAN( %QSYSFUNC(KSCAN( %SUPERQ( OUT ) , 1 , %STR(%() ) ) , -1 , %STR(.) ) ) ;

	PROC IMPORT DATAFILE="&CSV." 
	            DBMS=DLM 
				OUT=&OUT. REPLACE ;
		GETNAMES=&getnames. ;
		GUESSINGROWS=&guessingrows. ;
		DELIMITER = "%UNQUOTE(&DLM.)" ;
		DATAROW=&DATAROW. ;
	RUN ;
	
	/* 若有 METADATA 存在 就根據 METADATA 變更欄位名稱以及 LABEL */
	%IF %SYSEVALF(%SUPERQ( META ) = , BOOLEAN ) EQ 0 %THEN %DO ;
		%LOCAL META_CNT ;
		PROC SQL NOPRINT ;
			SELECT NAME 
			INTO   :META_NAME SEPARATED BY ',' 
			FROM &META. 
			;
			SELECT TRANWRD( TRANWRD( DESC , ";" , " " )  , "," , " " )
			INTO   :META_DESC SEPARATED BY ',' 
			FROM &META. 
			;
			SELECT COUNT(*) 
			INTO : META_CNT 
			FROM &META. 
			;
		QUIT;
		PROC CONTENTS DATA=&OUT. OUT= _&UUID._1 NOPRINT ; RUN ;
		PROC SQL NOPRINT ; 
			SELECT NAME 
			INTO :COLS SEPARATED BY ',' 
			FROM _&UUID._1 
			;
			QUIT ;
		%LOCAL OUT_CNT ;
		PROC SQL NOPRINT ; 
			SELECT COUNT(*) 
			INTO : OUT_CNT 
			FROM _&UUID._1
			;
			QUIT;
		%LOCAL LABEL_CNT ; 
		%LET LABEL_CNT = %SYSFUNC(MIN( &OUT_CNT. , &META_CNT. ) ) ;
		PROC DATASETS LIB=&OUT_LIB. FORCE NOLIST NODETAILS NOWARN ; 
			MODIFY &OUT_DS. ;  
				%UNQUOTE(%rtn_doOver( "&COLS.;&META_DESC." , ' LABEL ?1 = "?2" ;', INOBS=&LABEL_CNT. ) ) 
				%UNQUOTE(%rtn_doOver( "&COLS.;&META_NAME." , ' RENAME ?1 = ?2 ;' ,INOBS=&LABEL_CNT.) )
		RUN;
		%END ;
	PROC DATASETS LIB=WORK NOLIST NOWARN NODETAILS; 
		DELETE _&UUID._: ;
		RUN ;
%MEND;
%ins_mcr_dict( 資料探索 , 
               mcr_impfile( 分隔文字檔或CSV ,分隔字元 ,產出資料集名稱 ) ,
			   匯入分隔文字檔或CSV成SAS DATASET )
/* 範例說明 */
/* 範例一: 將DTGDC003 欄位名稱說明匯入，並利用匯入的MET_DTGDC003(METADATA) 將原始資料匯入 
	%mcr_impfile( D:\SASData\GD_PR\DQ\P_CSV\MET_DTGDC003.csv ,  "," , MET_DTGDC003 , getnames=YES )
	%mcr_impfile( D:\SASData\GD_PR\DQ\P_CSV\20190316_GDC003.csv , "," , DTGDC003  ,META=MET_DTGDC003 ) ;
*/
