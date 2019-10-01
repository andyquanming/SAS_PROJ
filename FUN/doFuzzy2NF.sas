	%MACRO _doFuzzy2NF()  ;

		%LET TBL_VIEW = %SYSFUNC(DEQUOTE(%SUPERQ(TBL_VIEW))) ;
		%LET PKEYs = %QUPCASE(%QSYSFUNC(DEQUOTE(%SUPERQ(PKEYs) ) ) ) ;
		%LOCAL keyCnt ;
		%LET keyCnt = %SYSFUNC(COUNTW( %SUPERQ(PKEYs) , %STR(,) ) ) ;
		%LET OUT = %SYSFUNC(DEQUOTE(&OUT.)) ;

		%LOCAL DS ;
		%LOCAL UUID /*執行唯一KEY*/
	           INFO /*所有資料存放的MCR*/
	           ;
		%LET UUID = &SYSJOBID._&SYSMACRONAME._&SYSINDEX ;
		%IF %SYSFUNC(COUNTW( %SUPERQ(TBL_VIEW) , %STR( ) ) ) > 1 %THEN %DO ; 
				%LET TBL_VIEW = %STR(%() %SUPERQ(TBL_VIEW) %STR(%)) ;
				PROC SQL ;
					CREATE TABLE _&UUID._0 AS 
						SELECT * 
						FROM %UNQUOTE(&TBL_VIEW.) 
						;
				QUIT ; 
				%LET DS = _&UUID._0 ; 
				%END ;
			%ELSE %DO ; 
				%LET DS = &TBL_VIEW. ;
				%END ;

		%LOCAL DUPOBS P_VALUE SMP_FLG SMP_SEED SMP_OBS ;
		%LET DUPOBS= 100  ;
		%LET p_value=0.05  ;
		%LET SR_value=0.1 ; 
		%LET SMP_FLG=FALSE  ;
		%LET SMP_SEED=-1 ; 
		%LET SMP_OBS=1000000 ;
		
		
		DATA _&UUID._1  ; 
			LENGTH KEY $100 ;
			LENGTH VAL $40 ;
			LENGTH INFO $500 ;
			STOP ;
		RUN ; 

		%IF %SYSFUNC(KINDEX( %SUPERQ(DS) , %STR(%() ) ) > 0 %THEN %DO ;
			PROC SORT THREADS SORTSIZE=MAX 
	                  DATA=&DS. OUT=_&UUID._2 ;
				BY %KSCAN( %SUPERQ(PKEYs) , -1 , %STR(,) ) ;
			RUN ;
			%LET DS = _&UUID._2 ;
		%END ;
		%LOCAL DS_CNT ;
		PROC SQL NOPRINT ; 
			SELECT COUNT(*)
			INTO : DS_CNT SEPARATED BY ','
			FROM &DS.
			;
		QUIT ;

		/***********************************************************************/
		PROC CONTENTS DATA=&DS. OUT=_&UUID._31 NOPRINT ; RUN ; 
		PROC SQL NOPRINT ; 
			SELECT NAME 
			INTO :NAMELIST SEPARATED BY ','
		    FROM  _&UUID._31
			;
		QUIT;
		DATA _&UUID._3(KEEP=TOTAL _CNT_: ); 
			FORMAT TOTAL ;
			SET &DS. END=EOF;
			%SYSFUNC(doOver( %SUPERQ(NAMELIST) , IF CMISS(?) = 0 THEN _CNT_? + 1 %STR(;) , %STR( ) ))
			TOTAL + 1 ;
			IF EOF THEN OUTPUT _&UUID._3 ;
		RUN ; 
		
		proc transpose data= _&UUID._3
		               out = _&UUID._3 (rename=(_name_=var) rename=(col1=cnt)  ) ;  
		RUN ;
		PROC SORT DATA=_&UUID._3 THREADS SORTSIZE=MAX ;
			BY DESCENDING CNT ;
		RUN ;

		DATA _&UUID._3 ;
			SET _&UUID._3 ; 
			IF var NE "TOTAL" THEN DO ;
				VAR = KSUBSTR(VAR, 6 ) ;
			END ;
		RUN ;
		/***********************************************************************/
	/*	%UNQUOTE(%NRSTR(%%)%SUPERQ(mcr_cntValidValue)( &DS. ,_&UUID._3 ,_&UUID._3 ))*/
		%LET KeyList = %SUPERQ(PKEYs) ;
		%PUT NTOE: *********************************************************;
		%PUT NOTE: KEY ORDER IS &KeyList. ; 
		%PUT NTOE: *********************************************************;
		PROC SQL NOPRINT ;
			CREATE TABLE _&UUID._4 AS 
			SELECT * 
			FROM _&UUID._3
			WHERE UPCASE(VAR) NOT IN ( %SYSFUNC(doOver(%SUPERQ(PKEYs) , "%UPCASE(?)" , %STR(,) )) )
			;
		QUIT ;
		%LOCAL TOTAL ; 
		PROC SQL NOPRINT ; 
			SELECT CNT 
			INTO : TOTAL 
			FROM _&UUID._4
			WHERE VAR = "TOTAL"
			;
		QUIT ; 
		/* 找出要驗證相依的欄位 */
		DATA _&UUID._5 
	         _&UUID._4 ;
			SET _&UUID._4  ; 
			IF VAR NE "TOTAL" THEN DO ;
				OUTPUT _&UUID._4 ;
			END ;
			IF CNT > 1 AND VAR NE "TOTAL" THEN DO ;
				IF CNT / &TOTAL. < &SR_value. THEN DO ;
					CALL EXECUTE ( ' PROC SQL NOPRINT ; ' ) ;
					CALL EXECUTE( "INSERT INTO _&UUID._1 VALUES ( '' , '" || KSTRIP(VAR) || "' ," ) ;
					CALL EXECUTE( ' "NOTE VALID CNT = ' ||KSTRIP(CNT) || " TOTAL = &TOTAL." || '" ) ;' );
					CALL EXECUTE( 'QUIT; ' ) ;
				END;
				OUTPUT _&UUID._5 ; 
				END; 
			ELSE DO ;
				IF CNT = 0 THEN DO ;
					CALL EXECUTE ( ' PROC SQL NOPRINT ; ' ) ;
					CALL EXECUTE( "INSERT INTO _&UUID._1 VALUES ( '' , '" || KSTRIP(VAR) || "' ," ) ;
					CALL EXECUTE( ' "NG(all missing) OR FIXED VALUE" ) ;' );
					CALL EXECUTE( 'QUIT; ' ) ;
				END;
			END;
		RUN ;
		%LOCAL vals_2NF ;
		PROC SQL NOPRINT ; 
			SELECT VAR 
			INTO : vals_2NF SEPARATED BY ','
			FROM _&UUID._5
			;
		QUIT; 

		%LOCAL i /* val loop */ j /*key loop*/  ;
		%LOCAL park_pk park_val;
		/* 每個傳入的PKEY 對除了PKEY外的欄位比對欄位相依情形 */
		%DO j = 1 %TO %SYSFUNC(COUNTW( %SUPERQ(vals_2NF) , %STR(,))) ;
			%LET park_val = %SYSFUNC(KSCAN(%SUPERQ(vals_2NF),&j., %str(,))) ;
			%DO i = 1 %TO %SYSFUNC(COUNTW( %SUPERQ(KeyList) , %STR(,))) ;
				%LET park_pk = %SYSFUNC(KSCAN(%SUPERQ(KeyList),&i., %str(,))) ;
	            
				/* 計算有效資料的KEY相異數 */
				%local key_efct ;
				%let key_efct = 1 ;
				proc sort data=&DS.(  
	                         keep=&park_pk. &park_val. 
	                         WHERE=( &park_val. IS NOT MISSING ) )
						THREADS 
	                    SORTSIZE=MAX 
	                    NODUPKEY 
	                    OUT=_&UUID._6;
					by &park_pk. &park_val. ;
				run ;

				proc sort data=_&UUID._6
	                      THREADS  
	                      SORTSIZE=MAX 
	                      NODUPKEY 
	                      OUT=_&UUID._7;
					by &park_pk.;
				run;
				PROC SQL NOPRINT ; 
					select nobs 
					into : key_efct 
					from DICTIONARY.TABLES
					where upcase(libname) ="WORK"
					and memname = upcase("_&UUID._7")
					;
				QUIT ; 
	            /* KEY VAL 相異配對， GROUP BY KEY 驗證COUNT( DISTINCT VAL ) > 1 的個數 */
				%local key_dup_valcnt ;
				%local dup_flag ;
				%let key_dup_valcnt = 0 ;
				%let dup_flag = | ;
				proc sql ;
					create table _&UUID._8 as 
						select &park_pk. , COUNT(DISTINCT &park_val.) AS CNT 
						FROM  _&UUID._6
						GROUP BY  &park_pk. 
						;
				QUIT ;
				PROC SQL ;
					create table _&UUID._9 as 
						select *
						FROM  _&UUID._8
						WHERE CNT >= 2 
						;
				QUIT ;			
				PROC SQL NOPRINT ; 
					select nobs 
					into : key_dup_valcnt 
					from DICTIONARY.TABLES
					where upcase(libname) ="WORK"
					and memname = upcase("_&UUID._9")
					;
				QUIT ;
				%if %sysevalf( &key_dup_valcnt. = 0 ) %then %do ; 
					PROC SQL NOPRINT ;
						INSERT INTO _&UUID._1 VALUES ( "&park_pk." , "&park_val." , "PASS(NODUP)" ) ; 
					QUIT ;
					%goto next_val_2NF ;
					%end;
				%else %do ;
					%if %sysevalf( &key_dup_valcnt./ &key_efct. < &p_value. ) %then %do ; 
						/* 不合格率在一定比例(0.05)下SHOW 上去，但繼續巡檢下一個KEY*/
						PROC SQL NOPRINT ;
							INSERT INTO _&UUID._1 VALUES ( "&park_pk." , "&park_val." , "PASS(%SYSFUNC(KSTRIP(&key_dup_valcnt.))/%SYSFUNC(KSTRIP(&key_efct.)))" ) ; 
						QUIT ;
						PROC SORT DATA=_&UUID._9 SORTSIZE=MAX THREADS ;
							BY &park_pk. ;
						RUN ;
						DATA _&UUID._10(KEEP= KEY VAL DUP_KEY DUP_VAL ) ;
							LENGTH KEY $100 ;
							LENGTH VAL $40 ;
							LENGTH DUP_KEY $1000 ;
							LENGTH DUP_VAL $1000 ;
							MERGE _&UUID._6(IN=IN_1) _&UUID._9(IN=IN_2) ;
							BY &park_pk. ;
							key = "&park_pk." ;
							val = "&park_val." ;
							LENGTH &park_val._N $1000 ;
						    IF VTYPE(&park_val.) = "N" THEN DO ;
								&park_val._N = PUTN( &park_val. , "BEST32.") ;					 
								END;
							ELSE DO ; 
								&park_val._N = &park_val. ;
							END;
							DUP_KEY = &park_pk. ;
							DUP_VAL = &park_val._N ;
							IF IN_1 AND IN_2 THEN DO ;
								out_i + 1 ;
								OUTPUT ;  
							END;
							IF out_i > &DUPOBS. THEN DO ; 
	                        	STOP ;
							END;
						RUN ;
						%goto next_key_2NF ;
						%end;
					%end ;
	%next_key_2NF:
			%END;
	%next_val_2NF:
		%END;
	 	proc sql ; 
			create table &out. as 
				select a.VAR as val , b.key , b.info 
				from _&UUID._4 a left join _&UUID._1 b
				on a.VAR = b.val
				;
		QUIT ;
		proc sort data=&out. ; 
			by val KEY;
		run ;

		proc datasets lib=work nolist nowarn nodetails;
			delete _&UUID._: ;
		run ;
	%MEND; 
	PROC FCMP OUTLIB=WORK.FUNCS.doFuzzy2NF ;
		FUNCTION doFuzzy2NF( TBL_VIEW $ , PKEYs $ , OUT $ ) ;
			length RC 8 ;
			RC = run_macro( '_doFuzzy2NF' ,TBL_VIEW  ,PKEYs , OUT ) ;
			return(RC) ;
		endsub ;
	RUN ;
	%ins_func_dict( 資料集探索 , 
                    doFuzzy2NF( 表格或VIEW ,維度清單 ,結果檔 ) ,
                    "排除少數特殊資料後進行2NF" )
