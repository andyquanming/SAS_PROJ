	%MACRO _isSubList() ;
		%LET List = %SYSFUNC(DEQUOTE(%SUPERQ(List))) ;
		%LET subList = %SYSFUNC(DEQUOTE(%SUPERQ(subList))) ;
		%LET DLM = %SYSFUNC(DEQUOTE(%SUPERQ(DLM)));
		%LET rtn = 0 ;

		
		%IF %SYSEVALF(%SUPERQ(List) = ) OR 
            %SYSEVALF(%SUPERQ(subList) = ) %THEN %DO ; 
			%RETURN ;
			%END;
		
		%LOCAL i 
	           ListCnt 
	           List_i 
	           sep; 
		%LET ListCnt = %SYSFUNC(COUNTW(%SUPERQ(subList) ,%SUPERQ(DLM)));
		%DO i = 1 %TO &ListCnt. ;
			%LET List_i = %SYSFUNC(KSTRIP(%KSCAN(%SUPERQ(subList),&i.,%SUPERQ(DLM)))) ;
			%IF %SYSFUNC(FIND(%SUPERQ(List),&List_i.,it)) = 0 %THEN %DO ;
				%RETURN ;
			%END;
		%END;
		%LET rtn = 1 ;
	%MEND;
	PROC FCMP OUTLIB=WORK.FUNCS.isSubList ;
		FUNCTION isSubList( List $ , subList $ , DLM $ ) ;
			length rtn 8 ;
			RC = run_macro( '_isSubList' ,List ,subList ,DLM ,rtn ) ;
			return(rtn) ;
		endsub ;
	RUN ;
	%ins_func_dict( 布林判斷 , 
                    isSubList( 分隔清單 , 子分隔清單 ,分隔字原 ) , 
                    "判斷子分隔清單的元素是否都在分隔清單內" )
