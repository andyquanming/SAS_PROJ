	PROC FCMP OUTLIB=WORK.FUNCS.num2Chr ;
		FUNCTION num2Chr( num ) $32  ;
			length rtn_chr $32 ;
			rtn_chr = putn(num,"best32.") ;
			return(rtn_chr) ;
		endsub ;
	RUN ;
	%ins_func_dict( �榡�ഫ         ,
                    num2Chr( �Ʀr ) ,
                    "�Ʀr���r" )
