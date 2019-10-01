	%MACRO _do2NF()  ;
		%LET TBL_VIEW = %SYSFUNC(DEQUOTE(%SUPERQ(TBL_VIEW))) ;
		
		%LET PKEYs = %SYSFUNC(DEQUOTE(%SUPERQ(PKEYs)));
		%LET OUT = %SYSFUNC(DEQUOTE(%SUPERQ(OUT)));

		%LOCAL UUID keyCnt INFO;
		%LET UUID = &SYSJOBID._&SYSMACRONAME._&SYSINDEX ;
		%LET keyCnt = %SYSFUNC(COUNTW( %SUPERQ(PKEYs) , %STR(,) ) ) ;
		%PUT KEYCNT = &keyCnt. ; 
		%LOCAL DS ;
		%IF %SYSFUNC(COUNTW( %SUPERQ(TBL_VIEW) , %STR( ) ) ) > 1 %THEN %DO ; 
			%LET TBL_VIEW = %STR(%() %SUPERQ(TBL_VIEW) %STR(%)) ;
			PROC SQL ;
				CREATE TABLE _&UUID._1 AS 
					SELECT * 
					FROM &TBL_VIEW. 
					;
			QUIT ; 
			%LET DS = _&UUID._1 ; 
			%END ;
		%ELSE %DO ; 
			%LET DS = &TBL_VIEW. ;
			%END ;
		
		proc sql noprint ; 
			create table _&UUID._2 as 
			select %SYSFUNC(doOver( %SUPERQ(PKEYs) , COUNT( DISTINCT ? ) AS ? , %STR(,) ))
			from &DS.
			;
		quit ;
		proc transpose data= _&UUID._2 
					   out = _&UUID._3 
	                   (rename=(_name_ = var) rename=( col1 = cnt) );  
		run ;
		proc sort data = _&UUID._3  ; by  cnt ; run ;
		proc sql noprint ;
			select var 
			into :KeyList separated by ","
			from _&UUID._3
			;
		quit ;

		proc contents data = &DS. out = _&UUID._4 noprint ; run ;
		proc sql noprint ; 
			select name 
			into : vals_2NF /*要確認是否相依的欄位*/ separated by ','
			from _&UUID._4
			where  upcase(name) 
			not in ( %SYSFUNC(doOver( %SUPERQ(PKEYs) , "?" , %STR(,) )) )
			;
			quit ;
		
		%LOCAL i j ;
		%LOCAL part_pk park_val;
		%UNQUOTE( %NRSTR(%%)GLOBAL %SYSFUNC(doOver( %SUPERQ(PKEYs) , ?_KEEP , %STR( ) )) ) ;


		/* 每個傳入的PKEY 對除了PKEY外的欄位比對欄位相依情形 */
		%DO j = 1 %TO %SYSFUNC(COUNTW( %SUPERQ(vals_2NF) , %STR(,))) ;
			%LET park_val = %SYSFUNC(KSCAN(%SUPERQ(vals_2NF),&j., %str(,))) ;
			%DO i = 1 %TO %SYSFUNC(COUNTW( %SUPERQ(KeyList) , %STR(,))) ;
				%LET park_pk = %SYSFUNC(KSCAN(%SUPERQ(KeyList),&i., %str(,))) ;
				data _&UUID._5(keep=&park_pk. &park_val.) ;
					set &DS. ; ; 
					if CMISS( &park_val. ) = 0 then output ; 
				run ;
				proc sort data=_&UUID._5 THREADS SORTSIZE=MAX NODUPKEY out=_&UUID._6 ;
					by &park_pk. &park_val.;
				run;
				%local dsid nobs ;
				%let dsid=%sysfunc(open(_&UUID._6));
				%let nobs=%sysfunc(attrn(&dsid,nlobs));
				%let dsid=%sysfunc(close(&dsid));
				%if %sysevalf(&nobs. = 0 ) %then %do ; 
					%goto next_val_2NF ;
				%end ;
				%local bingo_flg ;
				%LET bingo_flg = 1 ;
				data _null_ ;
					set _&UUID._6 ;
					by &park_pk. &park_val.;
					if not last.&park_pk. and last.&park_val. then do ;
						call symputx( "bingo_flg" , 0 ) ;
						stop ;
					end ;
				run ;
				%IF &bingo_flg. eq 1 %THEN %DO ; 
					%LET &park_pk._KEEP = &&&park_pk._KEEP &park_val. ;
					%goto next_val_2NF;
					%END;
			%END;
	%next_val_2NF:
		%END;
		%LOCAL INFO ; 
		%LET INFO = ;
		%DO i = 1 %TO %SYSFUNC(COUNTW( %SUPERQ(KeyList) , %STR(,))) ;
			%LET park_pk = %SYSFUNC(KSCAN(%SUPERQ(KeyList),&i., %str(,))) ;
			%IF %SYSEVALF( %SUPERQ(&park_pk._KEEP) NE , boolean ) %THEN %DO ;
				%LET INFO = &INFO., &park_pk._dependency : &&&park_pk._KEEP;
			%END ;
		%END ;

		proc datasets lib=work nolist nowarn nodetails;
			delete _&UUID._: ;
		run ;

		%DO i = 1 %TO %SYSFUNC(COUNTW( %SUPERQ(INFO) , %STR(,) ) ) ;
			%PUT %SYSFUNC(KSCAN( %SUPERQ(INFO) , &i. , %STR(,) ) ) ;
		%END;
		
		DATA &OUT.(KEEP=KEY SEQ VAL ) ; 
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

	%MEND; 
	PROC FCMP OUTLIB=WORK.FUNCS.do2NF ;
		FUNCTION do2NF( TBL_VIEW $ , PKEYs $ , OUT $ ) ;
			length RC 8 ;
			RC = run_macro( '_do2NF' ,
                            TBL_VIEW     , 
                            PKEYs        ,
							OUT          ) ;
			return(RC) ;
		endsub ;
	RUN ;
	%ins_func_dict( 資料集探索                , 
                    do2NF( 表格VIEW1       ,
                           要分類的維度清單  ,
                           分類結果資料集    ) , 
			        "對表格作2階正規化" )
