	%MACRO _doOver()  ;
		%LOCAL val_1 ; 
		%LOCAL val ; 
		%LOCAL seq ;
		%LOCAL i ;
/*		%LOCAL SMBL ; */
		%LET SMBL = %SYSFUNC(DEQUOTE(%SUPERQ(SMBL))) ; 
/*%STR(?) ;*/
		%LOCAL DLM ; 
		%LET DLM = %STR(,) ; 
		%LOCAL SEP ; 
		%LET SEP = %STR(|) ;
	
		%LOCAL INOBS ;
		%LET PHRASE = %QSYSFUNC(DEQUOTE(%SUPERQ(PHRASE))) ;
		%LET valList = %QSYSFUNC(DEQUOTE(%SUPERQ(valList))) ; 
		%LET OUT_DLM = %QSYSFUNC(DEQUOTE(%SUPERQ(OUT_DLM))) ;
		%LET INOBS = %SYSFUNC(COUNTW(%QSYSFUNC(KSCAN( %SUPERQ(valList) ,1 ,&SEP.)) ,&DLM.)) ;

		%IF %SYSEVALF( %SUPERQ(valList) = , Boolean ) %THEN %DO ;
			%LET rtn_phrase = %str() ;
			%RETURN ;
		%END;

		%LOCAL out_phrase tmp_phrase;
		%IF %SYSFUNC(COUNTW( %SUPERQ(valList) , &SEP.)) EQ 1  %THEN %DO ; 
			%LET out_phrase = %QSYSFUNC(TRANWRD( &PHRASE. , &SMBL. ,&SMBL.1 ) ) ;
			%END ;
		%ELSE %DO ;
			%LET out_phrase = &PHRASE. ;
			%END ;

		%DO i = 1 %TO 1 ;
			%LET tmp_phrase = &out_phrase. ;
			%DO SEQ = 1 %TO %SYSFUNC(COUNTW( %SUPERQ(valList) , &SEP. ) ) ;
				%LOCAL tmp_&SEQ._&i. ; 
				%LET tmp_&SEQ._&i. = %QSYSFUNC(KSTRIP( %QSYSFUNC(KSCAN(%SUPERQ(valList) , &SEQ. , &SEP. )))) ;
				%LET tmp_&SEQ._&i. = %QSYSFUNC(KSTRIP(%QSYSFUNC(KSCAN( &&tmp_&SEQ._&i. , &i. , &DLM. ) ) )) ;
				%LET tmp_phrase = %QSYSFUNC(TRANWRD( &tmp_phrase. , &SMBL.&SEQ. , &&tmp_&SEQ._&i. ) ) ;
			%END ;
			%LET rtn_phrase = &tmp_phrase. ;
		%END; 

		%DO i = 2 %TO &INOBS.;
			%LET tmp_phrase = &out_phrase. ;
			%DO SEQ = 1 %TO %SYSFUNC(COUNTW( %SUPERQ(valList) , &SEP. ) ) ;
				%LOCAL tmp_&SEQ._&i. ; 
				%LET tmp_&SEQ._&i. = %QSYSFUNC(KSTRIP( %QSYSFUNC(KSCAN(%SUPERQ(valList) ,&SEQ. , &SEP. )))) ;
				%LET tmp_&SEQ._&i. = %QSYSFUNC(KSTRIP(%QSYSFUNC(KSCAN( &&tmp_&SEQ._&i. , &i. , &DLM. ) ) )) ;
				%LET tmp_phrase = %QSYSFUNC(TRANWRD( &tmp_phrase. , &SMBL.&SEQ. , &&tmp_&SEQ._&i. ) ) ;
			%END ;
			%LET rtn_phrase = &rtn_phrase.&OUT_DLM.&tmp_phrase. ;
		%END; 
		%LET rtn_phrase = "%SYSFUNC(COMPBL(&rtn_phrase.))";
		%IF %SYSFUNC(LENGTHN( %SUPERQ(rtn_phrase) )) GE &STRING_MAX_LEN. %THEN %DO ; 
			%LET rtn_phrase = " " ;
			%END;
	%MEND; 
	PROC FCMP OUTLIB=WORK.FUNCS.doSmblOver ;
		FUNCTION doSmblOver( valList $ ,PHRASE $ ,OUT_DLM $ , SMBL $) $&STRING_MAX_LEN. ;
			length rtn_phrase $&STRING_MAX_LEN. ;
			RC = run_macro( '_doOver' ,
                            valList ,
                            PHRASE ,
							OUT_DLM ,
							SMBL ,
                            rtn_phrase ) ;
			return(rtn_phrase) ;
		endsub ;
	RUN ;
	%ins_func_dict( �r�����j�M�� , 
                    doSmblOver( ���j�M�� ,�ݮM�J�y�k ,���X�y�k���j�r�� ,�����Ÿ� ) , 
                    "�N�M��(�r�����椸��Pipe���j����)�A�ഫ�����O
                     �p doOver( 'a1,a2,a3|b1,b2,b3', '?1=?2 ;' ) �|����
                     a1=b1; a2=b2 ; a3=b3 ;" )
	PROC FCMP OUTLIB=WORK.FUNCS.doOver ;
		FUNCTION doOver( valList $ ,PHRASE $ ,OUT_DLM $ ) $&STRING_MAX_LEN. ;
			length rtn_phrase $&STRING_MAX_LEN. ;
			length SMBL $1 ;
			SMBL = "?" ;
			RC = run_macro( '_doOver' ,
			                            valList ,
			                            PHRASE ,
										OUT_DLM ,
										SMBL ,
			                            rtn_phrase ) ; ;
			return(rtn_phrase) ;
		endsub ;
	RUN ;
	%ins_func_dict( �r�����j�M�� , 
                    doOver( ���j�M�� , �ݮM�J�y�k , ���X�y�k���j�r�� ) , 
                    "�N�M��(�r�����椸��Pipe���j����)�A�ഫ�N��Ÿ������O
                     �p doOver( 'a1,a2,a3|b1,b2,b3', '?1=?2 ;' ) �|����
                     a1=b1; a2=b2 ; a3=b3 ;" )
