	PROC FCMP OUTLIB=WORK.FUNCS.full2Half ;
		FUNCTION full2Half( TEXT $ ) $&STRING_MAX_LEN. ;
			length rtn_TEXT $&STRING_MAX_LEN. ;
			rtn_TEXT = KTRANSLATE( TEXT , 
								   "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz0123456789--" ,
								   "�Ϣ�Т�Ѣ�Ң�Ӣ�Ԣ�բ�֢�ע�آ�٢�ڢ��ۢ��ܢ��ݢ��ޢ��ߢ������������������@��A��B��C���������������������Тw" 
                                 );
			return(rtn_TEXT) ;
		endsub ;
	RUN ;
	%ins_func_dict( �榡�ഫ ,
                    full2Half( ��r ) , 
                    "������b��" )
