	PROC FCMP OUTLIB=WORK.FUNCS.half2Full ;
		FUNCTION half2Full( TEXT $ ) $&STRING_MAX_LEN. ;
			length rtn_TEXT $&STRING_MAX_LEN. ;
			rtn_TEXT = KTRANSLATE( TEXT , 
                                   "ＡａＢｂＣｃＤｄＥｅＦｆＧｇＨｈＩｉＪｊＫｋＬｌＭｍＮｎＯｏＰｐＱｑＲｒＳｓＴｔＵｕＶｖＷｗＸｘＹｙＺｚ０１２３４５６７８９－─" ,
								   "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz0123456789--"
                                 );
			return(rtn_TEXT) ;
		endsub ;
	RUN ;
	%ins_func_dict( 格式轉換 ,
                    half2Full( 文字 ) , 
                    "半形轉全型" )
