	PROC FCMP OUTLIB=WORK.FUNCS.nldtStr ;
		FUNCTION nldtStr( datetime ) $19  ;
			length str $19 ;
			str = put(datetime, nldatm19.) ;
			return(str) ;
		endsub ;
	RUN ;
	%ins_func_dict( �榡�ഫ ,
                    nldtStr( ����ɶ� ) , 
                    "�N����ɶ��ରyyyy/mm/dd hh:mm:ss" )
