	%MACRO _loadRule()  ;
		%LET MET_PIPE_TXT = %SYSFUNC(DEQUOTE( &MET_PIPE_TXT. )) ; 
		%LET META_TBL = %SYSFUNC(DEQUOTE( &META_TBL. )) ;
		%LET REL_DSList = %QSYSFUNC(DEQUOTE(%SUPERQ(REL_DSList))) ;

		%LOCAL UUID ; 
		%LET UUID = &SYSJOBID._&sysmacroname._&SYSINDEX. ;

		DATA _&UUID._1 ;
					INFILE "%SYSFUNC(DEQUOTE( %SUPERQ(MET_PIPE_TXT) ))" 
		            DLM='|' TRUNCOVER DSD TERMSTR=CRLF ;

					LENGTH trgt_tbl $50 ;
					LENGTH trgt_com $10 ;
					LENGTH com_ser 8 ;
					LENGTH com_desc $1000 ;
					LENGTH ASMP $2000 ;
					LENGTH EXPR $2000 ;
					LENGTH ALIAS $50 ;

					LABEL trgt_tbl = "目標表格" ;
					LABEL trgt_com = "目標規則" ; 
					LABEL com_ser = "規則編號" ; 
					LABEL com_desc = "規則說明" ;		
					LABEL ASMP = "條件" ;
				    LABEL EXPR = "公式表達式" ;
					LABEL ALIAS = "別稱" ;

					INPUT trgt_tbl
		                  trgt_com 
						  com_ser
						  com_desc
						  ASMP
						  EXPR
						  ALIAS ;
		RUN ;

		%LOCAL i subDs ; 
		%DO I = 1 %TO %SYSFUNC(COUNTW( &REL_DSList. , %str(,) )) ;
			%LET subDs = %KSCAN( &REL_DSList. ,&i. ,%str(,) ) ;
			PROC CONTENTS DATA= &subDs.  
			              OUT=_&UUID._M&I.(KEEP=MEMNAME NAME) NOPRINT ; RUN ; 
			%IF &i. EQ 1 %THEN %DO ; 
				DATA _&UUID._B ;
					IF 0 THEN SET _&UUID._M&I ;
					STOP ; 
				RUN ; 
				%END ;
			PROC APPEND BASE=_&UUID._B DATA=_&UUID._M&I. FORCE ; RUN ;
		%END; 

		%LOCAL VARs ;
		PROC SQL NOPRINT; 
			SELECT DISTINCT UPCASE(NAME) 
			INTO : VARs SEPARATED BY ','
			FROM 	_&UUID._B
			;
		QUIT ;

		PROC CONTENTS DATA=_&UUID._1 OUT=_&UUID._META NOPRINT ; RUN ;

		%LOCAL CHECK_FIELD ; 
		PROC SQL NOPRINT ; 
			SELECT COUNT(*) 
			INTO : CHECK_FIELD
			FROM _&UUID._META 
			WHERE UPCASE(NAME) IN ( "TRGT_TBL" , 
	                                "TRGT_COM" , 
	                                "COM_SER" , 
	                                "COM_DESC" , 
	                                "ASMP" 		,
	                                "EXPR" , 
	                                "ALIAS"  ) 
			;
		QUIT ;
		%IF &CHECK_FIELD. NE 7 %THEN %DO ; 
			%PUT ERROR: METADATA IS INVALID. NUMBER OF VALID FIELDS = &CHECK_FIELD. ;
			%ABORT CANCEL ; 
		%END; 

		PROC SORT THREADS SORTSIZE=MAX 
		          DATA=_&UUID._1 
	              OUT=_&UUID._2 ;
			BY TRGT_TBL TRGT_COM COM_SER ;
		RUN;

		/* 資料欄位計算 */
		DATA _&UUID._SEL(KEEP= trgt_tbl
	                           trgt_com	
	                           com_ser	
	                           com_desc	
	                           ASMP	
	                           EXPR	
	                           ALIAS 
	                           RELA_SRC 
	                           RELA_VAR ) ;
			SET _&UUID._2(WHERE=( UPCASE(trgt_com) NOT IN ( 'BAS' ,'JNR') )) END=EOF ; 

			LENGTH RELA_SRC $32767 ;
			LENGTH RELA_VAR $32767 ;
			LABEL RELA_SRC = "相關表格" ; 
			LABEL RELA_VAR = "相關變數" ; 

			RETAIN DLM ;
			IF _N_ = 1 THEN DO ;
				dlm = " ,()=" ;
			END ;
			
			RELA_SRC = "" ;
			RELA_VAR = "" ;
			i = 1 ;
			DO UNTIL(KSCAN(EXPR ,i ,dlm) eq '') ;
				EXPS_WORD = KSTRIP(KSCAN(EXPR , i ,dlm )) ;
				IF CMISS(EXPS_WORD) = 0 THEN DO ; 
				    VAR_IN_WORD= KSCAN( EXPS_WORD , -1 , ".") ;
					VAR_BINGO = FINDW( "&VARs." ,KSTRIP(VAR_IN_WORD) ) ;
					WORD_IN_RELA_VAR = FIND( RELA_VAR ,EXPS_WORD ,"it" ) ;
					IF VAR_BINGO > 0 AND WORD_IN_RELA_VAR = 0 THEN DO ; 
						RELA_VAR = CATX("," , RELA_VAR , KSTRIP(EXPS_WORD)|| BYTE(10) )  ;
					END ;
					SRC_IN_WORD = KSCAN(EXPS_WORD,-2,".") ;
					SRC_IN_RELA_SRC = FIND( RELA_SRC , SRC_IN_WORD,"it") ;
					IF VAR_BINGO AND SRC_IN_RELA_SRC = 0 THEN DO ; 
						RELA_SRC = CATX("," ,RELA_SRC ,KSTRIP(SRC_IN_WORD) || BYTE(10))  ;
					END ;
		    	END;	
				i = i + 1 ;
			END ;
			OUTPUT ;
		RUN ;
	
		/* FROM AND JOIN STATEMENT */
		DATA _&UUID._BAS (KEEP=trgt_tbl
				                           trgt_com	
				                           com_ser	
				                           com_desc	
				                           ASMP	
				                           EXPR	
				                           ALIAS 
				                           RELA_SRC 
				                           RELA_VAR ) ; 
			SET _&UUID._1(WHERE=(UPCASE(trgt_com) EQ 'BAS' )) ;
			LENGTH RELA_VAR $1000 ;
			RELA_SRC = "N/A" ;
			RELA_VAR = metaQry(kstrip(EXPR)) ;
		RUN ; 

		DATA _&UUID._JNR (KEEP=trgt_tbl
				                           trgt_com	
				                           com_ser	
				                           com_desc	
				                           ASMP	
				                           EXPR	
				                           ALIAS 
				                           RELA_SRC 
				                           RELA_VAR ) ; 
			SET _&UUID._1(WHERE=(UPCASE(trgt_com) EQ 'JNR' )) ;
			LENGTH RELA_VAR $2000 ;
			RELA_SRC = "N/A" ;
			RELA_VAR = metaQry(kstrip(EXPR)) ;
		RUN ; 

		DATA &META_TBL. ;
			LENGTH trgt_tbl $50 ;
			LENGTH trgt_com $10 ;
			LENGTH com_ser 8 ;
			LENGTH com_desc $1000 ;
			LENGTH ASMP $2000 ;
			LENGTH EXPR $2000 ;
			LENGTH ALIAS $50 ;
			LENGTH RELA_SRC $1000 ;
			LENGTH RELA_VAR $1000 ;
			
			SET _&UUID._BAS 
				_&UUID._JNR
	            _&UUID._SEL   ; 
		RUN ; 

		PROC DATASETS LIB=WORK NOLIST NODETAILS NOWARN ; 
			DELETE _&UUID._: ; 
		RUN ;
	%MEND; 
	PROC FCMP OUTLIB=WORK.FUNCS.loadRule ;
		FUNCTION loadRule( MET_PIPE_TXT $ ,META_TBL $ , REL_DSList $ ) ;
			length RC 8 ;
			RC = run_macro( '_loadRule'  ,
                            MET_PIPE_TXT ,
                            META_TBL     ,
							REL_DSList   ) ;
			return(rtn_err) ;
		endsub ;
	RUN ;
	%ins_func_dict( 元數據管理 , 
                    loadRule( pipe分隔TXT ,控制檔 ,關聯清單) ,
                    "產出規則檢核控制檔" )
