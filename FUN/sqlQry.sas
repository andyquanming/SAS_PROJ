	%MACRO _sqlQry()  ; 
		%LET SQL = %QSYSFUNC(DEQUOTE( %SUPERQ(SQL) )) ; 
		%LET DLM = %STR(,) ;
		%LET NEWLINE = %STR(|) ;
		%LOCAL selected sqlClauses; 

		%LET selected = %QSYSFUNC( prxchange( s/select+\s*?(.*?)\s*?from.*/$1/i , -1 , %superq(SQL) ) ) ;
		%LET cat_selected = CATX("&DLM." , &selected. ) ;
		%LET sqlClauses = %QSYSFUNC( prxchange( s/select+\s*?.*?\s*?(from.*)/$1/i , -1 , %superq(SQL) ) ) ;

		PROC SQL NOPRINT ;
			SELECT %UNQUOTE(&cat_selected.)
			INTO : sqlFetch SEPARATED BY "&NEWLINE." 
			%UNQUOTE(&sqlClauses.)
			;
		QUIT ;

	%MEND; 
	PROC FCMP OUTLIB=WORK.FUNCS.sqlQry ;
		FUNCTION sqlQry( SQL $ ) $&STRING_MAX_LEN. ;
			length sqlFetch $&STRING_MAX_LEN. ;
			RC = run_macro( '_sqlQry' ,SQL ,sqlFetch ) ;
			return(sqlFetch) ;
		endsub ;
	RUN ;
	%ins_func_dict( SQL���� ,
                    sqlQry( SQL�d�� ) , 
                    "�^��SQL�d�ߵ��G�A��춡�H�r���Ϲj�A��ƶ��HPipe�Ϲj" )
