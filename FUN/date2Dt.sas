	PROC FCMP OUTLIB=WORK.FUNCS.date2Dt ;
		FUNCTION date2Dt( date ) ;
			return(DHMS(date,0,0,0)) ;
		ENDSUB ;
	RUN ;
	%ins_func_dict( �榡�ഫ ,
                    date2Dt( ��� ) , 
                    "�N����ର����ɶ�" )
