	PROC FCMP OUTLIB=WORK.FUNCS.hash32 ;
		FUNCTION hash32( chr $ ) $32 ;
			return(putc( md5(kstrip(chr)),"hex32.")) ;
		ENDSUB ;
	RUN ;
	%ins_func_dict( �榡�ഫ ,
                    hash32( �r�� ) , 
                    "�N�r���ন�T�w����32���s�X" )
