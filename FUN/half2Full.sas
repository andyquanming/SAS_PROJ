	PROC FCMP OUTLIB=WORK.FUNCS.half2Full ;
		FUNCTION half2Full( TEXT $ ) $&STRING_MAX_LEN. ;
			length rtn_TEXT $&STRING_MAX_LEN. ;
			rtn_TEXT = KTRANSLATE( TEXT , 
                                   "�Ϣ�Т�Ѣ�Ң�Ӣ�Ԣ�բ�֢�ע�آ�٢�ڢ��ۢ��ܢ��ݢ��ޢ��ߢ������������������@��A��B��C���������������������Тw" ,
								   "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz0123456789--"
                                 );
			return(rtn_TEXT) ;
		endsub ;
	RUN ;
	%ins_func_dict( �榡�ഫ ,
                    half2Full( ��r ) , 
                    "�b�������" )
