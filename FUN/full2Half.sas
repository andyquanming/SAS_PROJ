	PROC FCMP OUTLIB=WORK.FUNCS.full2Half ;
		FUNCTION full2Half( TEXT $ ) $&STRING_MAX_LEN. ;
			length rtn_TEXT $&STRING_MAX_LEN. ;
			rtn_TEXT = KTRANSLATE( TEXT , 
								   "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz0123456789--" ,
								   "ＡａＢｂＣｃＤｄＥｅＦｆＧｇＨｈＩｉＪｊＫｋＬｌＭｍＮｎＯｏＰｐＱｑＲｒＳｓＴｔＵｕＶｖＷｗＸｘＹｙＺｚ０１２３４５６７８９－─" 
                                 );
			return(rtn_TEXT) ;
		endsub ;
	RUN ;
	%ins_func_dict( 格式轉換 ,
                    full2Half( 文字 ) , 
                    "全型轉半型" )
