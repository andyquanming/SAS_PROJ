	PROC FCMP OUTLIB=WORK.FUNCS.nldStr ;
		FUNCTION nldStr( date ) $10  ;
			length str $10 ;
			str = put(date, nldate10.) ;
			return(str) ;
		endsub ;
	RUN ;
	%ins_func_dict( 格式轉換 ,
                    nldStr( 日期 ) , 
                    "將日期轉為yyyy/mm/dd" )
