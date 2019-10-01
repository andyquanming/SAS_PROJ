	%MACRO __do1NF(DS , 
	               FORCE_ORDER= , 
	               FORCE_NUM= , 
	               OUT=_1NF_INFO , 
	               LIMIT=1 ,
	               MCR=_1NF_MCR ,
				   FREQ_TBL= 	,
	               mcr_loop=rtn_doOver ) ;
		%LOCAL UUID i J INFO ;
		%LET UUID = &SYSJOBID._&sysmacroname._&SYSINDEX. ;
		%LET OUT = %SYSFUNC(DEQUOTE( &OUT. ) ) ; 
		%LET FORCE_ORDER = %QSYSFUNC(UPCASE(%QSYSFUNC(DEQUOTE( %SUPERQ(FORCE_ORDER))))) ;
		%LET FORCE_NUM = %QSYSFUNC(UPCASE(%QSYSFUNC(DEQUOTE( %SUPERQ(FORCE_NUM) ) ))) ;
		%GLOBAL &MCR. ; 
		%IF &LIMIT. EQ 1 %THEN %DO ; 
			DATA BASE_&UUID. ;
				SET &DS.;
			RUN ; 
			%LET DS = BASE_&UUID. ;
		%END ;
		%IF &LIMIT. GT 20 %THEN %DO ; 
			%PUT NOTE: 超過迭待次數 ; 
			%RETURN ; 
			%END ;
		/* DS文字變數相異值個數排序展開 */
		proc contents data=&DS. out=_&UUID._meta noprint ; run ;
		data _&UUID._meta ;
			set _&UUID._meta ; 
			name = UPCASE(name) ;
		run ;
		proc sql noprint ; 
			select name
			into :nameList separated by ' '
			from _&UUID._meta
			;	
		quit;
		proc sort data=&DS. NODUPKEY threads sortsize=max OUT=_&UUID._1 ; 
			BY &nameList. ;
		RUN ;
		%IF %SYSEVALF(%SUPERQ(FREQ_TBL)= , BOOLEAN) %THEN %DO ;
			%LET FREQ_TBL =  _FREQ_&UUID._ ;
			proc sql noprint ; 
				select "count( distinct " || name || ")  as " || name  
				into :keyFreqStmt separated by ','
				from _&UUID._meta
				where %IF %SYSEVALF( %SUPERQ(FORCE_ORDER)= , BOOLEAN ) EQ 0 %THEN %DO ;
						NAME NOT IN (
							%SYSFUNC(doOver( %SUPERQ(force_order) , "?" , %str(,) )) 
						)
						AND
						%END ;
				 		( type = 2 
							%IF %SYSEVALF( %SUPERQ(FORCE_NUM)= , BOOLEAN ) EQ 0 %THEN %DO ;
							OR UPCASE(NAME) IN (
								%SYSFUNC(doOver(%SUPERQ(FORCE_NUM) , "?" , %STR(,) )) )
							%END ; )
				;
			quit ;
			proc sql ; 
				create table _&UUID._cntDistnct as 
				select &keyFreqStmt.
					from &DS. ;
				quit; 	
			proc transpose data= _&UUID._cntDistnct 
			               out = _&UUID._freq (rename=(_name_ = var) rename=( col1 = cnt) );  
			run ;
			proc sort data = _&UUID._freq nodupkey threads sortsize=max OUT=&FREQ_TBL. ; by descending cnt ; run ;
		%END;

		%LOCAL UK1 UK2_N ;
		proc sql noprint OUTOBS=1 ;
			select var 
			into :UK1 separated by ","
			from &FREQ_TBL.
			%IF %SYSEVALF( %SUPERQ(FORCE_ORDER)= , BOOLEAN ) EQ 0 %THEN %DO ;
				WHERE VAR NOT IN (
					%SYSFUNC(doOver( %SUPERQ(FORCE_ORDER) ,"?" ,%STR(,))) 
					)
			%END;
			ORDER BY CNT DESC 
			;
		quit ;	
		PROC SQL noprint ;
			select var 
			into :UK2_N separated by ","
			from &FREQ_TBL.
			WHERE VAR NE "%UPCASE(&UK1.)"
			%IF %SYSEVALF( %SUPERQ(FORCE_ORDER)= , BOOLEAN ) EQ 0 %THEN %DO ;
				AND VAR NOT IN ( 
					%SYSFUNC(doOver(%SUPERQ(force_order) , "?" , %STR(,) )) 
					)		 
			%END;
			ORDER BY CNT  
			;
		QUIT ;

		%LET keys = %SYSFUNC(doOver( %SUPERQ(force_order) , ? ,%str(,) ))%STR(,)
	                &UK1. %STR(,)
					%SYSFUNC(doOver( %SUPERQ(UK2_N) ,? ,%str(,) )) ;
		%LET UKs = %SYSEVALF( %SYSFUNC(COUNTW(%SUPERQ(force_order),%STR(,) )) + %SYSFUNC(COUNTW(%SUPERQ(UK2_N),%STR(,))) + 1 ); 
		PROC SORT DATA=&DS. threads sortsize=max NODUPKEY OUT=_&UUID._2;
			BY %SYSFUNC(TRANWRD(%SUPERQ(keys),%STR(,) , %STR( ) )) ;
		RUN;
		%LOCAL i j keyCnt;
		%LET keyCnt=0;
		DATA _null_;
			IF 0 THEN SET _&UUID._1 NOBS=_all_obs_;
			SET _&UUID._2 NOBS =_unique_obs_ END=done;
			ALL = _all_obs_  ;
			DISTINCT = _unique_obs_ ;
			IF _unique_obs_<_all_obs_ then do;
				put "NOTE: mcr_normalize: no unique keys found for table &DS.";
				STOP;
				END;
			RETAIN keyCnt 1;
			BY %SYSFUNC(TRANWRD(%SUPERQ(keys),%STR(,) , %STR( ) )) ;
			SELECT(keyCnt);
				%do i=1 %TO &UKs;
				when(&i) do;
					%do j=&i %TO &UKs;
					if last.%scan(%SUPERQ(keys),&j,%STR(,)) then goto KeyOK;
					keyCnt+1;          
					%end;
					end;
				%end;
				end;
			KeyOK:
			if done then call symputx('keyCnt',keyCnt);
		run;
		%if &keyCnt. > 0 %THEN %DO;
			%LOCAL PKEY KEY_TMP ;
			%LET KEY_TMP = %SYSFUNC(rangeScan( %SUPERQ(keys) , 1 , &keyCnt. , %STR(,) )) ;
			%LET PKEY = %SYSFUNC(doOver( %SUPERQ(KEY_TMP) ,? ,%STR(,) )) ;
			%END ;
		%ELSE %RETURN;

		%LET INFO = primary_key : &PKEY.  ;

		proc datasets lib=work nolist nowarn nodetails;
			delete _&UUID._: ;
		run ;

		%DO i = 1 %TO %SYSFUNC(COUNTW( %SUPERQ(INFO) , %STR(,) ) ) ;
			%PUT %SYSFUNC(KSCAN( %SUPERQ(INFO) , &i. , %STR(,) ) ) ;
		%END;
		
		DATA &OUT.(KEEP=KEY SEQ VAL INFO) ; 
			LENGTH INFO $32636 ; 
			LENGTH KEY $32636 ;
			LENGTH SEQ 8 ;
			LENGTH VALs $32636 ;
			LENGTH VAL $40 ;
			LENGTH INFO_i $3000 ;
			INFO = SYMGET( 'INFO' ) ;
			DO i = 1 to COUNTW(INFO , "," ) ; 
				INFO_i = KSCAN( INFO , i , "," ) ; 
				KEY = KSTRIP( KSCAN( INFO_i , 1 , ":"  ) ) ; 
				VALs = KSTRIP( KSCAN( INFO_i , 2 , ":" ) ) ;
				DO SEQ = 1 TO COUNTW(VALs, " ") ;
					VAL = KSTRIP(KSCAN(VALs , SEQ , " " ) ) ;
					OUTPUT ;
				END ;
			END ; 
		RUN ;
		%LOCAL res_keyCnt ;
		PROC SQL NOPRINT ;
			SELECT MAX(SEQ) 
			INTO : res_keyCnt 
			FROM &OUT.
			;
			QUIT ; 

		%IF %SYSFUNC(COUNTW( %SUPERQ(FORCE_ORDER) , %STR(,) ) ) NE &res_keyCnt. %THEN %DO ;
			%LOCAL new_FORCE_ORDER ;
			PROC SQL NOPRINT ;
				SELECT VAL 
				INTO : new_FORCE_ORDER SEPARATED BY ',' 
				FROM &OUT.
				WHERE SEQ LE %SYSFUNC(COUNTW(&FORCE_ORDER. , %STR(,) ) ) OR SEQ = &res_keyCnt.
				ORDER BY SEQ  
				;
				QUIT ;
			%LET LIMIT = %SYSEVALF( &LIMIT. + 1 ) ;
			%__do1NF( &DS. ,
	                  FORCE_ORDER="&new_FORCE_ORDER." ,
	                  FORCE_NUM=&FORCE_NUM. ,
	                  LIMIT=&LIMIT. ,
	                  OUT=&OUT. ,
					  FREQ_TBL=&FREQ_TBL. ,
	                  MCR=&MCR. )
			%END ; 
		%ELSE %DO ;
			PROC SQL NOPRINT; 
			 	SELECT VAL 
				INTO :&MCR. SEPARATED BY ','
				FROM &OUT.
				ORDER BY SEQ 
				;
			QUIT;
			PROC SQL ;
				DROP TABLE &FREQ_TBL. ; 
				DROP TABLE &DS. ;
			QUIT ;
			%END ;
	%mend;
	%MACRO _do1NF() ; 
		%LET DS = %SYSFUNC(DEQUOTE(&DS.)) ;
		%LET FORCE_NUM = %SYSFUNC(DEQUOTE(%SUPERQ(FORCE_NUM))) ;
		%LET FORCE_ORDER = %SYSFUNC(DEQUOTE(%SUPERQ(FORCE_ORDER))) ;
		
		%LET RTN_UK = ; 
		%__do1NF( &DS. ,
                FORCE_NUM=%SUPERQ(FORCE_NUM) , 
                FORCE_ORDER=%SUPERQ(FORCE_ORDER) )
		%LET RTN_UK = &_1NF_MCR. ;
	%MEND; 
	PROC FCMP OUTLIB=WORK.FUNCS.do1NF ;
		FUNCTION do1NF( DS $ , FORCE_NUM $ , FORCE_ORDER $ ) $&STRING_MAX_LEN. ;
			length rtn_uk $&STRING_MAX_LEN. ;
			RC = run_macro( '_do1NF' ,
                            DS ,
                            FORCE_NUM ,
                            FORCE_ORDER ,
							rtn_uk ) ;
			return(rtn_uk) ;
		endsub ;
	RUN ;
	%ins_func_dict( 資料集探索 , 
                    do1NF( 資料集 ,須納入數值變數 ,須納入變數 ) , 
                    "找出資料的主鍵" )
