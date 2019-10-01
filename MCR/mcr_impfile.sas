/*�{���W��  : mcr_impfile                                        */
/*�@��      : Andy                                              */
/*�B�z���n  : �פJ���j�r�Ÿ�ƶ��A��Ū�� METADATA���X���W�٤�LABEL  */
/*��J        : CSV: �ӷ���r�� 
                DLM: �ӷ����j�r��
                OUT : SAS DATASET
               */
/*��X      : ���~�����׭�( rejectDS ) ���~������( ERR_PRFIX_ )      */
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
	
	/* �Y�� METADATA �s�b �N�ھ� METADATA �ܧ����W�٥H�� LABEL */
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
%ins_mcr_dict( ��Ʊ��� , 
               mcr_impfile( ���j��r�ɩ�CSV ,���j�r�� ,���X��ƶ��W�� ) ,
			   �פJ���j��r�ɩ�CSV��SAS DATASET )
/* �d�һ��� */
/* �d�Ҥ@: �NDTGDC003 ���W�ٻ����פJ�A�çQ�ζפJ��MET_DTGDC003(METADATA) �N��l��ƶפJ 
	%mcr_impfile( D:\SASData\GD_PR\DQ\P_CSV\MET_DTGDC003.csv ,  "," , MET_DTGDC003 , getnames=YES )
	%mcr_impfile( D:\SASData\GD_PR\DQ\P_CSV\20190316_GDC003.csv , "," , DTGDC003  ,META=MET_DTGDC003 ) ;
*/
