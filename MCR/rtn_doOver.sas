/*程式名稱  : rtn_doOver	                                     */
/*作者      : Andy                                               */
/*處理概要  : 將傳入的字串根據分隔字符剖析後進行重組回傳               */
/*輸入        : strVals( 分隔字串 )
                PHRASE( 重組語句 )  
             */
/*輸出      : 重組後語法 */
%MACRO rtn_doOver( strVals ,
                   PHRASE  , 
                   SYMBOL=? , 
                   DLM="," ,
				   SEP=";" , 
                   OUT_DLM=%STR( ) ,
                   INOBS= )  ;
	%LOCAL val_1 ; 
	%LOCAL val ; 
	%LOCAL rtn_doOver ;
	%LOCAL seq ;
	%LOCAL i ;
	%LET PHRASE = %QSYSFUNC(DEQUOTE( %SUPERQ(PHRASE)) ) ;
	%LET DLM = %QSYSFUNC(DEQUOTE( %SUPERQ(DLM) )) ;
	%LET SEP = %QSYSFUNC(DEQUOTE( %SUPERQ(SEP) )) ; 
	%LET OUT_DLM = %QSYSFUNC(DEQUOTE( %SUPERQ(OUT_DLM) )); 
	%LET SYMBOL = %QSYSFUNC(DEQUOTE( %SUPERQ(SYMBOL) ) ) ;
	%LET strVals = %QSYSFUNC(DEQUOTE( %SUPERQ(strVals) ) ) ; 
	%LET INOBS = %SYSFUNC(DEQUOTE( %SUPERQ(INOBS) ) ) ;
	%IF %SYSEVALF( &strVals.= , Boolean ) %THEN %DO ;
		%str()
		%RETURN ;
	%END;

	%LOCAL out_phrase tmp_phrase;
	/* 如果字串只有一個維度取代? ->?1 */
	%IF %SYSFUNC(COUNTW( &strVals. , &SEP. ) ) EQ 1  %THEN %DO ; 
		%LET out_phrase = %QSYSFUNC(TRANWRD( &PHRASE. , &SYMBOL. ,&SYMBOL.1 ) ) ;
		%END ;
	%ELSE %DO ;
		%LET out_phrase = &PHRASE. ;
		%END ;

	%DO i = 1 %TO 1 ;
		%LET tmp_phrase = &out_phrase. ;
		%DO SEQ = 1 %TO %SYSFUNC(COUNTW( &strVals. , &SEP. ) ) ;
			%LOCAL tmp_&SEQ._&i. ; 
			%LET tmp_&SEQ._&i. = %QSYSFUNC(KSTRIP( %QSYSFUNC(KSCAN(&strVals. , &SEQ. , &SEP. )))) ;
			%LET tmp_&SEQ._&i. = %QSYSFUNC(KSTRIP(%QSYSFUNC(KSCAN( &&tmp_&SEQ._&i. , &i. , &DLM. ) ) )) ;
			%LET tmp_phrase = %QSYSFUNC(TRANWRD( &tmp_phrase. , &SYMBOL.&SEQ. , &&tmp_&SEQ._&i. ) ) ;
		%END ;
		%LET rtn_doOver = &tmp_phrase. ;
	%END; 
	%IF %SYSEVALF(%SUPERQ(INOBS)= ,BOOLEAN) %THEN %DO ; 
		%LET INOBS = %SYSFUNC(COUNTW( %QSYSFUNC(KSCAN( &strVals. , 1 , &SEP. ) ) , &DLM. ) ) ;
		%END;

	%DO i = 2 %TO &INOBS.;
		%LET tmp_phrase = &out_phrase. ;
		%DO SEQ = 1 %TO %SYSFUNC(COUNTW( &strVals. , &SEP. ) ) ;
			%LOCAL tmp_&SEQ._&i. ; 
			%LET tmp_&SEQ._&i. = %QSYSFUNC(KSTRIP( %QSYSFUNC(KSCAN(&strVals. , &SEQ. , &SEP. )))) ;
			%LET tmp_&SEQ._&i. = %QSYSFUNC(KSTRIP(%QSYSFUNC(KSCAN( &&tmp_&SEQ._&i. , &i. , &DLM. ) ) )) ;
			%LET tmp_phrase = %QSYSFUNC(TRANWRD( &tmp_phrase. , &SYMBOL.&SEQ. , &&tmp_&SEQ._&i. ) ) ;
		%END ;
		%LET rtn_doOver = &rtn_doOver.&OUT_DLM.&tmp_phrase. ;
	%END; 

	&rtn_doOver.
%MEND; 
/*範例說明*/
/*範例一: 
  OPTIONS MPRINT ;
  %put %rtn_doOver( " , aa ,bb ,cc " , 'LAST_? = ? ;' , INOBS=2) ; 
  %put %rtn_doOver( "aa ,bb ,cc | d , e, f " , 'LAST_?1 = ?2 ;' , INOBS=2 , SEP = "|" ) ; 

*/
/*%put %rtn_doOver("SLIP_LOT_NO='0'|SLIP_LOT_NO in (1,2,3)|SYS_NO='DJ'|SLIP_LOT_NO in */
/*(1,2,3)|SLIP_LOT_NO in (1,2,3)|1=1 %str(;) IS_AIZ = 'A00'|IS_AIZ = 'B01'|IS_AIZ = 'B02'|IS_AIZ = 'B03'|IS_AIZ = 'C00'|IS_AIZ = 'NOR'"*/
/*,'IF ?1 THEN ?2 ;' , */
/*													 DLM = "%STR(|)" ,*/
/*													 SEP = ";" ,*/
/*                                                     OUT_DLM = ' ELSE ') ;*/
