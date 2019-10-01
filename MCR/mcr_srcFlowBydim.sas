/*程式名稱	: mcr_srcFlowBydim                               */
/*作者	  : Andy                                           */
/*處理概要	: 以特定維度來看在各來源的資訊程度，資料多的代表流程較前 */
/*輸    入  : SRCs( 來源 )DIMs(維度)  */
/*輸    出  :   													*/
%MACRO mcr_srcFlowBydim( SRCs , DIMs , OUT=srcFlowBydim )  ;
	%LOCAL i src UUID ;
	%LET UUID = &SYSJOBID._&SYSINDEX. ;  
	%LET SRCs = %QSYSFUNC(DEQUOTE( %SUPERQ(SRCs) ) ) ; 
	%LET DIMs = %QSYSFUNC(DEQUOTE( %SUPERQ(DIMs) ) ) ; 
	%DO i = 1 %TO %SYSFUNC(COUNTW( &SRCs. , %STR(,) ) ) ; 
		%LET src = %SYSFUNC(KSCAN( &SRCs. , &i. , %STR(,) ) )  ;
		%LOCAL SRC_NAME SRCs_name ;
		%LET SRC_NAME = %SYSFUNC(KSCAN(&SRC. , -1 , %STR(.) ) ) ;
		%IF %SYSEVALF( &i. = 1 ) %THEN %DO ; 
			%LET SRCs_name = &SRC_NAME. ;
			%END ;
		%ELSE %DO ; 
			%LET SRCs_name = &SRCs_name. %STR(,) &SRC_NAME. ;
			%END ;
		PROC SORT DATA=&src.(KEEP= %rtn_doOver( "&DIMs." ,'?' ) ) 
                  threads 
                   SORTSIZE=MAX NODUPKEY OUT=_&UUID._&SRC_NAME. ; 
			BY %UNQUOTE(%rtn_doOver( &DIMs. , '?' )) ; 
		RUN ;
	%END ; 
	DATA &OUT. ;
		FORMAT SUM ;
		MERGE %UNQUOTE(%rtn_doOver( "&SRCs_name." , "_&UUID._?( IN = ?_IN) ")) ; 
		BY %UNQUOTE(%rtn_doOver( &DIMs. , '?' )) ;
		%UNQUOTE(%rtn_doOver( "&SRCs_name." , 'BINGO_? = 0 ;' )) ;
		%UNQUOTE(%rtn_doOver( "&SRCs_name." , ' IF ?_IN THEN BINGO_? = 1 ; ' )) 
	RUN ;
	PROC DATASETS LIB=WORK NOLIST NODETAILS NOWARN ; 
		DELETE _&UUID._: ; 
	RUN ; 
%MEND;
/* 範例說明*/
/* 盤點 XX 這個維度在各表格的分布
 a0 --> a1      -->a3
    --> a2 
data a0 ; 
	xx = 'REC1' ; OUTPUT ;
	xx = 'REC2' ; OUTPUT ;
	xx = 'REC3' ; OUTPUT ;
    xx = 'REC4'; OUTPUT ;
	xx = 'REC5'; OUTPUT ;
run ;
data a1 ; 
	xx = 'REC1' ; OUTPUT ;
	xx = 'REC2' ; OUTPUT ;
run ;
data a2 ; 
	xx = 'REC4' ; OUTPUT ;
	xx = 'REC5' ; OUTPUT ;
run ;
data a3 ; 
	xx = 'REC1' ; OUTPUT ;
	XX = 'REC2'  ;OUTPUT ;
	XX = 'REC4'  ;OUTPUT ;
run ;
%mcr_srcFlowBydim( "a0,a1,a2,a3" , "xx" , OUT=AAA) 

%mcr_srcFlowBydim( "QUERY.DTAAB001_Q
,QUERY.DTAB0005_Q
,QUERY.DTAB0010
,QUERY.DTAB0206_Q
,QUERY.DTABL001
,QUERY.DTACA080
,QUERY.DTACAZ80
,QUERY.DTACE002
,QUERY.DTACF211_D
,QUERY.DTACF411
,QUERY.DTAEL031
,QUERY.DTAP0000_Q
,QUERY.DTATA101_CONTRACT_Q
,QUERY.DTATG111
,QUERY.EA_ClaimData" , "policy_no" , OUT=AAA) 
*/
%ins_mcr_dict( 資料探勘 , 
               mcr_srcFlowBydim( 來源資料集清單 ,
	                             比對維度      ,
                                 OUT=產出資料集 ) ,
			   以特定維度來看在各來源的資訊程度，資料多的代表流程較前   )
