	PROC FCMP OUTLIB=WORK.FUNCS.nldStr ;
		FUNCTION nldStr( date ) $10  ;
			length str $10 ;
			str = put(date, nldate10.) ;
			return(str) ;
		endsub ;
	RUN ;
	%ins_func_dict( �榡�ഫ ,
                    nldStr( ��� ) , 
                    "�N����ରyyyy/mm/dd" )
