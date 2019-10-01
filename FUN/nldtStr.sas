	PROC FCMP OUTLIB=WORK.FUNCS.nldtStr ;
		FUNCTION nldtStr( datetime ) $19  ;
			length str $19 ;
			str = put(datetime, nldatm19.) ;
			return(str) ;
		endsub ;
	RUN ;
	%ins_func_dict( 格式轉換 ,
                    nldtStr( 日期時間 ) , 
                    "將日期時間轉為yyyy/mm/dd hh:mm:ss" )
