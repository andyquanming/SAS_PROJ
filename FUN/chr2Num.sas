	PROC FCMP OUTLIB=WORK.FUNCS.chr2Num ;
		FUNCTION chr2Num( chr $ )  ;
			return(inputn(chr,"best32.")) ;
		endsub ;
	RUN ;
	%ins_func_dict( �榡�ഫ ,
                    chr2Num( ��r ) , 
                    "��r��Ʀr" )
