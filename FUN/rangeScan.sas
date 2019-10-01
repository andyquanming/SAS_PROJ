/*程式名稱	: _rangeScan 											    */
/*作者		: Andy                                                   */
/*處理概要	: 將分隔清單根據範圍取出子清單                                  */
	%MACRO _rangeScan()  ;
		%LOCAL i ; 
		%LOCAL listElement ;
		%LET TEXT = %QSYSFUNC(DEQUOTE( %SUPERQ(TEXT) )) ;
		%LET DLM = %QSYSFUNC(KSTRIP(%QSYSFUNC(DEQUOTE(%SUPERQ(DLM)))));
		%LET rtn_List = ; 
		%DO i = &BEGIN. %TO &END. ; 
			%LET listElement = %SYSFUNC(KSCAN(%SUPERQ(TEXT) ,
                                              &i. ,
                                              &DLM.));
			%IF %SYSEVALF(%SUPERQ(rtn_List)= ,Boolean) %THEN %DO ;
				%LET rtn_List = &listElement. ;
				%END;
			%ELSE %DO ; 
				%LET rtn_List = &rtn_List.&DLM.&listElement. ;
				%END;
		%END ;
	%MEND;
	PROC FCMP OUTLIB=WORK.FUNCS.rangeScan ;
		FUNCTION rangeScan( TEXT $ ,BEGIN ,END ,DLM $ ) $&STRING_MAX_LEN. ;
			length rtn_List $&STRING_MAX_LEN. ;
			RC = run_macro( '_rangeScan' ,
                            TEXT ,
                            BEGIN ,
                            END ,
							DLM ,
                            rtn_List ) ;
			return(rtn_List) ;
		endsub ;
	RUN ;
	%ins_func_dict( 字元分隔清單 ,
                    rangeScan( 分隔清單 ,開始序號 ,結束序號 ,分隔字元 ) , 
                    "取出指定範圍形成新的清單" )
