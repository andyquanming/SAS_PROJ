	%MACRO _SCD2LagDiff()  ;
		
		%LET DS = %SYSFUNC(DEQUOTE( &DS. ));
		%LET tran_dttm = %SYSFUNC(DEQUOTE(&tran_dttm.)) ;
		%LET tran_dttm = %SYSFUNC(INPUTN( &tran_dttm. , NLDATM19. )) ;
		%LET OUT_PREFIX = %SYSFUNC(DEQUOTE( &OUT_PREFIX. )) ;
		%LET pk = %QUPCASE(%QSYSFUNC(DEQUOTE( %SUPERQ(PK)))) ;


		%LET valid_bgn = %SYSEVALF( &tran_dttm. - 1 ) ; 
		%LET valid_end = &tran_dttm. ;

	
		%LOCAL LAST_KEY ; 
		%LET LAST_KEY = %KSCAN( %SUPERQ(PK) , -1 , %STR(,) ) ;

		%LOCAL valid_to_L01 valid_to_L02 ;
		%LOCAL UUID ;
		%LOCAL varList numList chrList LENGTH_MCR ;
		%LET UUID = &SYSJOBID._&SYSINDEX. ;

		%PUT 本期資料有效起日時間 : %SYSFUNC(PUTN( &valid_bgn. ,NLDATM19.)) ; 
		%PUT 上期資料有效迄日時間 : %SYSFUNC(PUTN( &valid_end. ,NLDATM19.)) ;
		
		%LOCAL PK_QUOTE_COMMA  ;
		%LET PK_QUOTE_COMMA = %SYSFUNC(DOOVER( %SUPERQ(pk),"?",%STR(,))) ;
		%LOCAL PK_UNQUOTE_SPACE ;
		%LET PK_UNQUOTE_SPACE = %SYSFUNC(DOOVER( %SUPERQ(pk), ? ,%STR( ))) ;

		PROC CONTENTS DATA=&DS. OUT=_&UUID._1 NOPRINT ; RUN ; 
		PROC SQL NOPRINT ; 
			SELECT NAME 
			INTO :varList separated by ','
			FROM _&UUID._1
			WHERE UPCASE(NAME) 
	               NOT IN ( &PK_QUOTE_COMMA.  ,
	                        "VALID_FROM_DTTM" ,
	                        "VALID_TO_DTTM"   )
			;
			SELECT NAME 
			INTO :chrList separated by ','
			FROM _&UUID._1
			WHERE TYPE = 2 AND 
	              UPCASE(NAME) NOT IN ( &PK_QUOTE_COMMA.   ,
	                       			    "VALID_FROM_DTTM"  , 
	                                    "VALID_TO_DTTM"    )
			;
			SELECT NAME 
			INTO :numList separated by ','
			FROM _&UUID._1
			WHERE TYPE = 1 AND 
	              UPCASE(NAME) NOT IN ( &PK_QUOTE_COMMA.  ,
	                                    "VALID_FROM_DTTM" , 
	                                    "VALID_TO_DTTM"   )
			;
			SELECT "LENGTH LAST_" ||	KSTRIP(NAME) || 
	           ( CASE WHEN TYPE = 2 THEN " $" ELSE " " END ) || KSTRIP(PUTN( LENGTH , "8." )) || ";" 
			   INTO : LENGTH_MCR SEPARATED BY ' '
			   FROM _&UUID._1
				WHERE UPCASE(NAME) 
	               NOT IN ( &PK_QUOTE_COMMA.  ,
	                        "VALID_FROM_DTTM" , 
	                        "VALID_TO_DTTM"   )
				;
			QUIT ;

		PROC SORT DATA=&DS.(WHERE=( VALID_TO_DTTM GE &valid_bgn. AND 
	                                VALID_FROM_DTTM LE &valid_end. ) ) 
	          THREADS SORTSIZE=max OUT=_&UUID._2 ; 
			BY &PK_UNQUOTE_SPACE. VALID_FROM_DTTM VALID_TO_DTTM ; 
		RUN ;

		DATA &OUT_PREFIX.DTL( DROP = insert_cnt delete_cnt update_cnt noChange_cnt ) 
	     	 &OUT_PREFIX.SUMM( KEEP = insert_cnt delete_cnt update_cnt noChange_cnt ) ;
			FORMAT DIFF_TYPE 
	               grpCnt
		           &PK_UNQUOTE_SPACE. 
		           valid_from_dttm 
		           valid_to_dttm;
			SET _&UUID._2 END=EOF; 
			BY &PK_UNQUOTE_SPACE. valid_from_dttm valid_to_dttm ; 

			/* LENGTH STMT */
			LENGTH grpCnt 8 ;
			LENGTH diff_type $10 ;
			LENGTH insert_cnt 8 ;
			LENGTH delete_cnt 8 ;
			LENGTH update_cnt 8 ;
			LENGTH noChange_cnt 8 ;
			%UNQUOTE( &LENGTH_MCR. ) ;

			/* RETAIN STMT */ 
			RETAIN grpCnt ;
			RETAIN insert_cnt; 
			RETAIN delete_cnt; 
			RETAIN update_cnt;
			RETAIN noChange_cnt ; 
			%SYSFUNC( doOver( %SUPERQ(varList) , RETAIN LAST_? %str(;) , %str( ) )) 
			%SYSFUNC( doOver( %SUPERQ(varList) , RETAIN CMP_? %str(;) , %str( ) )) 
			
			/* GLOBAL INITIAL STMT */ 
			IF _N_ = 1 THEN DO ; 
				insert_cnt = 0 ;
				delete_cnt = 0 ;
				update_cnt = 0 ;
				noChange_cnt = 0 ; 
				group_str = 0 ;
				END ;

			/* GROUP INITIAL STMT */ 
			IF FIRST.&LAST_KEY. THEN DO ; 
				grpCnt = 0 ;
				group_str = 1 ;
				%SYSFUNC( doOver( %SUPERQ(varList) , CMP_? = 0 %str(;) , %str( ) )) 
				%SYSFUNC( doOver( %SUPERQ(chrList) , LAST_? = " " %str(;) , %str( ) )) 
				%SYSFUNC( doOver( %SUPERQ(numList) , LAST_? = 0 %str(;) , %str( ) )) 
				END ;

			/* COMPUTATION IN GROUP */
			grpCnt = grpCnt + 1 ;
			/*比對*/
			IF grpCnt > 1 THEN DO ;
				%SYSFUNC( doOver( %SUPERQ(varList) , IF LAST_? NE ? THEN CMP_? = 1 %str(;) , %str( ) )) 
				END ;
			IF grpCnt = 1 THEN DO ;
				%SYSFUNC( doOver( %SUPERQ(varList) , LAST_? = ? %str(;) , %str( ))) 
				END ;

			/* GROUP OUTPUT STMT */ 
			IF LAST.&LAST_KEY. THEN DO ;
			    /* 兩期內的資料不只一筆 ==> 修改 */
			    /* 兩期內的資料只有一筆, 且為無效 ==> 刪除 */
			    /*                  , 有效 ==> 用出生日期判斷既有或是本期新增 */
				IF grpCnt GT 1 THEN DO ;
					diff_type = "UPDATE" ; 
					update_cnt = update_cnt + 1 ; 
					END ;
				ELSE DO ; 
					IF valid_to_dttm LT &valid_end. THEN DO ;
						diff_type = "DELETE" ;
						delete_cnt = delete_cnt + 1 ;
						END ;
					ELSE DO ; 
		                IF valid_from_dttm GT &valid_bgn. THEN DO ; 		
							diff_type = "INSERT" ;
							insert_cnt = insert_cnt + 1 ;
							END ;
						ELSE DO ; 
							diff_type = "NOCHANGE" ;
							noChange_cnt = noChange_cnt + 1 ;
							END ;
						END ;
					END ;
					OUTPUT &OUT_PREFIX.DTL ;
				END ;  
			IF EOF THEN DO ;
				OUTPUT &OUT_PREFIX.SUMM ;
				END ;
		RUN ;  
		
		PROC DATASETS LIB=WORK NOLIST NODETAILS NOWARN ; 
			DELETE _&UUID._: ; 
		RUN ;

	%MEND;
	PROC FCMP OUTLIB=WORK.FUNCS.SCD2LagDiff ;
		FUNCTION SCD2LagDiff( DS $ , PK $ ,TRAN_DTTM $ ,OUT_PREFIX $ ) ;
			length RC 8 ;
			RC = run_macro( '_SCD2LagDiff' ,
							DS             ,
                            PK             ,
                            TRAN_DTTM      ,
                            OUT_PREFIX     ) ;
			return(RC) ;
		endsub ;
	RUN ;
	%ins_func_dict( DDS函數 ,
                    SCD2LagDiff( 歷程資料集 ,前端主鍵 ,交易時間 ,產出報表前綴 ) , 
                    "解析 Slowly Changing Type 2 歷程前後期變動" )
