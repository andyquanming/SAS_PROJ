	PROC FCMP OUTLIB=WORK.FUNCS.hash32 ;
		FUNCTION hash32( chr $ ) $32 ;
			return(putc( md5(kstrip(chr)),"hex32.")) ;
		ENDSUB ;
	RUN ;
	%ins_func_dict( 格式轉換 ,
                    hash32( 字串 ) , 
                    "將字串轉成固定長度32的編碼" )
