%MACRO rtn_DSName(DS) ;
	%SYSFUNC(KSCAN( %SYSFUNC(KSCAN( &DS. , -1 , %STR(.) ) ) , 1 , %STR(%() ) )
%MEND ;

%MACRO rtn_DSLib(DS)  ;
	%SYSFUNC(KSCAN( WORK.&DS. , -2 , %STR(.) ) ) 
%MEND;

%MACRO rtn_DSOption(DS)  ;
	%LOCAL FIRST_Parentheses_INDEX ;
	%LOCAL LAST_Parentheses_INDEX ;
	%LET FIRST_Parentheses_INDEX = %SYSFUNC( FIND( &DS. , %STR(%() ) ) ;
	%LET LAST_Parentheses_INDEX = %SYSFUNC( FIND( &DS. , %STR(%))  , -%SYSFUNC(LENGTH( &DS. ))   ) ) ;
	%IF &FIRST_Parentheses_INDEX. > 0 %THEN %DO ;
		%SYSFUNC(KSUBSTR( &DS. , 
	                      &FIRST_Parentheses_INDEX. + 1 , 
	                      &LAST_Parentheses_INDEX. - &FIRST_Parentheses_INDEX. - 1 ) ) 
		%END;
	%ELSE %DO ;
		%STR( )
		%END ;
%MEND ;

/*폻ⓕ빨ⁿ*/
/*폻ⓕ�@: 
	%LET DS = WORK.AAA(WHERE=(XX = 123 ) ) ;
	%PUT DS NAME = %rtn_DSName(&DS.) ;
	%PUT DS Lib = %rtn_DSLib(&DS.) ;
	%PUT DS Options = %rtn_DSOption(&DS.) ;
*/
/*폻ⓕ짨: 
	%LET DS = AAA(WHERE=(XX = 123 ) ) ;
	%PUT DS NAME = %rtn_DSName(&DS.) ;
	%PUT DS Lib = %rtn_DSLib(&DS.) ;
	%PUT DS Options = %rtn_DSOption(&DS.) ;
*/
/*폻ⓕ짽: 
	%LET DS = WORK.AAA ;
	%PUT DS NAME = %rtn_DSName(&DS.) ;
	%PUT DS Lib = %rtn_DSLib(&DS.) ;
	%PUT DS Options = %rtn_DSOption(&DS.) ;
*/
/*폻ⓕ�|: 
	%LET DS = AAA ;
	%PUT DS NAME = %rtn_DSName(&DS.) ;
	%PUT DS Lib = %rtn_DSLib(&DS.) ;
	%PUT DS Options = %rtn_DSOption(&DS.) ;
*/
