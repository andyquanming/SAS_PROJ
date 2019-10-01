/*�{���W��	: _rangeScan 											    */
/*�@��		: Andy                                                   */
/*�B�z���n	: �N���j�M��ھڽd����X�l�M��                                  */
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
	%ins_func_dict( �r�����j�M�� ,
                    rangeScan( ���j�M�� ,�}�l�Ǹ� ,�����Ǹ� ,���j�r�� ) , 
                    "���X���w�d��Φ��s���M��" )
