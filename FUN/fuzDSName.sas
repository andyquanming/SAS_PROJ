	%MACRO _fuzDSName()  ;
		%LET LIB = %QUPCASE(%SYSFUNC(DEQUOTE( &LIB. ))); 
		%LET fuzzy = %QUPCASE(%SYSFUNC(DEQUOTE( &fuzzy. ))) ;  
		%LET rtn_name = ; 

		PROC SQL NOPRINT ; 
			SELECT DISTINCT MEMNAME 
			INTO : rtn_name SEPERATED BY ','
			FROM DICTIONARY.TABLES 
			WHERE LIBNAME = "&LIB." AND
                  MEMNAME CONTAINS "&fuzzy." 
			;
		QUIT ; 

	%MEND; 
	PROC FCMP OUTLIB=WORK.FUNCS.fuzDSName ;
		FUNCTION fuzDSName( LIB $ , fuzzy $ ) $&STRING_MAX_LEN. ;
			length rtn_name $&STRING_MAX_LEN. ;
			RC = run_macro( '_fuzDSName' ,
                            LIB ,
                            fuzzy ,
							rtn_name ) ;
			return(rtn_name) ;
		endsub ;
	RUN ;
	%ins_func_dict( ���ƾں޲z , 
                    fuzDSName( ����]�W�� , ��ƶ��ҽk�W�� ) , 
                    "��X����]���i�઺��ƦW��" )
