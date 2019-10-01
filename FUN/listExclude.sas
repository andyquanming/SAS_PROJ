	%MACRO _listExclude()  ;
		%LET List = %QSYSFUNC(DEQUOTE(%SUPERQ(List))) ;
		%LET Exclude = %QSYSFUNC(DEQUOTE(%SUPERQ(Exclude))) ;
		%LET List_rtn = ;

		
		%IF %SYSEVALF(%SUPERQ(Exclude) = ) %THEN %DO ; 
			%LET List_rtn = %SUPERQ(List) ;
			%RETURN ;
			%END;
		
		%LOCAL i 
	           ListCnt 
	           List_i 
	           sep; 
		%LET ListCnt = %SYSFUNC(COUNTW(&List. ,%STR(,)));
		%DO i = 1 %TO &ListCnt. ;
			%LET List_i = %SYSFUNC(KSTRIP(%KSCAN(%SUPERQ(List),&i.,%STR(,)))) ;
			%IF %SYSFUNC(FIND(%SUPERQ(Exclude),&List_i.,it)) = 0 %THEN %DO ;
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
	PROC FCMP OUTLIB=WORK.FUNCS.listExclude ;
		FUNCTION listExclude( List $ , Exclude $ ) $&STRING_MAX_LEN. ;
			length List_rtn $&STRING_MAX_LEN. ;
			RC = run_macro( '_listExclude' ,List ,Exclude ,List_rtn ) ;
			return(List_rtn) ;
		endsub ;
	RUN ;
	%ins_func_dict( 字元分隔清單 , 
                    listExclude( 分隔清單 ,要排除分隔清單 ) ,
                    "將第一個清單中屬於第二個清單的成員排除" )
