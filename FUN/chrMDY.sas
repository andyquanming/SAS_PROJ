	PROC FCMP OUTLIB=WORK.FUNCS.chrMDY ;
		FUNCTION chrMDY( MM $ , DD $ , YY $ )  ;
			return( MDY( INPUT(MM,BEST2.) ,  
			             INPUT(DD,BEST2.) ,
						 INPUT(YY,BEST4.) ) ) ;
		endsub ;
	RUN ;
	%ins_func_dict( �榡�ഫ ,
                    chrMDY( ��r�� , ��r�� , ��r�~ ) , 
                    "��r����" )
