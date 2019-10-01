	PROC FCMP OUTLIB=WORK.FUNCS.chr2Num ;
		FUNCTION chr2Num( chr $ )  ;
			return(inputn(chr,"best32.")) ;
		endsub ;
	RUN ;
	%ins_func_dict( 格式轉換 ,
                    chr2Num( 文字 ) , 
                    "文字轉數字" )
