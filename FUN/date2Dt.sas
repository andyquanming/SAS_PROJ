	PROC FCMP OUTLIB=WORK.FUNCS.date2Dt ;
		FUNCTION date2Dt( date ) ;
			return(DHMS(date,0,0,0)) ;
		ENDSUB ;
	RUN ;
	%ins_func_dict( 格式轉換 ,
                    date2Dt( 日期 ) , 
                    "將日期轉為日期時間" )
