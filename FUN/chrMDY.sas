	PROC FCMP OUTLIB=WORK.FUNCS.chrMDY ;
		FUNCTION chrMDY( MM $ , DD $ , YY $ )  ;
			return( MDY( INPUT(MM,BEST2.) ,  
			             INPUT(DD,BEST2.) ,
						 INPUT(YY,BEST4.) ) ) ;
		endsub ;
	RUN ;
	%ins_func_dict( 格式轉換 ,
                    chrMDY( 文字月 , 文字日 , 文字年 ) , 
                    "文字轉日期" )
