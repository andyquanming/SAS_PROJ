	PROC FCMP OUTLIB=WORK.FUNCS.DTtype ;
		FUNCTION DTtype(a);
			IF a>=31622400 AND a<=253717747199 THEN return(2);
			IF a>=366 AND a<=2936547 THEN return(1);
			RETURN(0);
		ENDSUB;
	RUN ;
	%ins_func_dict( �榡�ഫ ,
                    DTtype( ����ήɶ� ) , 
                    "�^�Ǥ���ɶ�(2)���(1)���w(0)" )
