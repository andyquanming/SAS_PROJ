	%MACRO _list2Set() ;
		%LET List = %QSYSFUNC(DEQUOTE(%SUPERQ(List))) ;
		%LET List_rtn = ;

		%LOCAL i 
	           sep 
	           ListCnt 
	           List_i ;
		%LET ListCnt = %SYSFUNC(COUNTW(%SUPERQ(List),%STR(,)));

		%DO i = 1 %TO &ListCnt. ;
			%LET List_i = %SYSFUNC(KSTRIP(%KSCAN(%SUPERQ(List),&i.,%STR(,)))) ;
			%IF %SYSFUNC(FIND(%SUPERQ(List_rtn),&List_i.,it)) = 0 %THEN %DO ;
				%IF %SYSEVALF(%SUPERQ(List_rtn) = ) %THEN %DO ;
					%LET sep = %STR( ) ;
					%END;
				%ELSE %DO ;
					%LET sep = %STR(,) ;
					%END;
				%Let List_rtn = %SYSFUNC(KSTRIP(%SUPERQ(List_rtn)))&sep.&List_i. ;
			%END;
		%END; 
		%LET List_rtn = "&List_rtn." ;
	%MEND; 
	PROC FCMP OUTLIB=WORK.FUNCS.list2Set ;
		FUNCTION list2Set( List $ ) $&STRING_MAX_LEN. ;
			length List_rtn $&STRING_MAX_LEN. ;
			RC = run_macro( '_list2Set' ,List ,List_rtn ) ;
			return(List_rtn) ;
		endsub ;
	RUN ;
	%ins_func_dict( 字元分隔清單 , 
                    list2Set( 分隔清單 ) ,
                    "將清單中重複的資料排除" )
