	%MACRO _findKeySrc()  ;
		%LET LIB = %SYSFUNC(DEQUOTE(&LIB.)) ;
		%LET varName = %SYSFUNC(DEQUOTE( &varName. ) ) ;
		%LET varVal = %SYSFUNC(DEQUOTE( &varVal. ) ) ;
		%LET rtn_src = ; 

		%LOCAL UUID ; 
		%LOCAL i ;
		%LOCAL table_i ; 
		%LET UUID = &SYSJOBID._&sysmacroname._&SYSINDEX. ;	

		proc contents data=&LIB.._all_ out= _&UUID._1 noprint ; run ; 
		%GLOBAL  _&UUID._exist ;

		%GLOBAL table_list table_cnt ; 
		%LET table_list = ;
		proc sql noprint ;
				select distinct memname 
				into : table_list separated by "|" 
				from _&UUID._1
				where name = "%UPCASE(&varName.)" 
				;
			QUIT ; 
		%LET table_cnt = %SYSFUNC(COUNTW( %SUPERQ(table_list) , %str(|) ) ) ;
		%DO i = 1 %TO &table_cnt. ;
			%LET table_i = %SYSFUNC(KSCAN( &table_list. , &i. , %STR(|) ) ) ;
			%IF %SYSEVALF( %SUPERQ( table_i ) NE , BOOLEAN ) %THEN %DO ; 
				%LET _&UUID._exist = 0 ;
				proc sql outobs=1 noprint ;
					select 1
					into : _&UUID._exist  
					from  &LIB..&table_i. 
					where &varName. = "&varVal." 
					;
				quit;
				%IF &&_&UUID._exist  %THEN %DO;
					%LET rtn_src = &rtn_src.%STR(,)&table_i. ;
				%END;
			%END;
		%END;
		%IF %SYSEVALF(%SUPERQ(rtn_src)=,BOOLEAN) EQ 0 %THEN %DO ;
			%LET rtn_src = %SYSFUNC(KSUBSTR( &rtn_src. , 2  ,%SYSFUNC(KLENGTH(%SUPERQ(rtn_src))) - 1 ) ) ;
		%END;
		proc datasets lib=work nolist nowarn nodetails ;
			delete _&UUID._: ;
		run ;
		
	%MEND;
	PROC FCMP OUTLIB=WORK.FUNCS.findKeySrc ;
		FUNCTION findKeySrc( LIB $ ,varName $ , varVal $ ) $&STRING_MAX_LEN. ;
			length rtn_src $&STRING_MAX_LEN. ;
			RC = run_macro( '_findKeySrc' ,
							LIB ,
                            varName ,
                            varVal ,
                            rtn_src ) ;
			return(rtn_src) ;
		endsub ;
	RUN ;
	%ins_func_dict( 資料集探索 , 
                    findKeySrc( 資料館 ,欄位名稱 ,欄位值 ) , 
                    "找出資料在那些表格存在" )
