/*程式名稱  : mcr_compareStat                                */
/*作者      : Andy                                              */
/*處理概要  : 驗證多個表格依照構面group by 後比對統計量是否相同          */
/*輸入        : tblList: 表格陣列 
              groupByList: 指定構面
              StatList : 統計量陣列
              sha: 比對加密方式
              sha_format: sha對應格式
              rejectDS: 錯誤報表表格                              */
/*輸出      : 錯誤的維度值( rejectDS ) 錯誤的明細( ERR_PRFIX_ )      */
%MACRO mcr_compareStat( tblList     ,
                        groupByList , 
                        StatList    , 
                        sha=SHA256  , 
                        sha_format=HEX64. , 
						ERR_PRFIX = _ERR ,
                        rejectDS=_checkGroupByStatisticErr)  ;
    %LOCAL UUID tblCnt groupBySpace groupByComma tblArrSpace i ; 
    %LET UUID = &SYSJOBID._&SYSINDEX. ; /*executed_id*/

    %LET groupByComma = %QSYSFUNC(DEQUOTE(%SUPERQ(groupByList))) ;
    %LET groupBySpace = %QSYSFUNC(TRANWRD( &groupByComma. , %STR(,) , %STR( ) ) ) ;
    %LET StatList = %QSYSFUNC(DEQUOTE(%SUPERQ(StatList))) ;
    %LET tblList = %QSYSFUNC(DEQUOTE(%SUPERQ(tblList))) ;

    %LET tblCnt = 0 ;
    %LET tblArrSpace = ;
    %DO %WHILE ( %QKSCAN( &tblList. , &tblCnt. + 1 , %STR(,) ) ^= );
		%LET tblCnt = %EVAL( &tblCnt. + 1 ) ;
        %LOCAL tbl_&UUID._&tblCnt. ;
        %LET tbl_&UUID._&tblCnt. =  %KSCAN( &tblList. , &tblCnt. , %STR(,) ) ;
		PROC SORT DATA=&&tbl_&UUID._&tblCnt. SORTSIZE=MAX THREADS OUT= _&UUID._&tblCnt. ;
			BY &groupBySpace. ;
		RUN ;
        proc sql magic = 102 ; 
            create table m_tbl_&UUID._&tblCnt. /*( index=( idx_%KSCAN(&&tbl_&UUID._&tblCnt. , -1 ,%STR(.) ) =( %UNQUOTE(&groupBySpace.))))*/ as 
                select %UNQUOTE(&groupByComma.) ,  
                     putc( &sha.(catx( "|" , %UNQUOTE(&StatList.))) , "%SYSFUNC(dequote(&sha_format.))" ) as checkSum_&tblCnt. 
                from _&UUID._&tblCnt.
                group by %UNQUOTE(&groupByComma.) 
                ;
        quit;
        %LET tblArrSpace = &tblArrSpace. m_tbl_&UUID._&tblCnt. ;
        %END ;
 
    data &rejectDS. ( drop= checkSum_: ) ;
        MERGE &tblArrSpace. ;
        BY %UNQUOTE(&groupBySpace.) ;
        %DO i = 2 %to &tblCnt. ;
            IF checksum_1 NE checkSum_&i. then output ; 
        %END;
    run;
	%LET tblCnt = 0 ;
	%DO %WHILE ( %QKSCAN( &tblList. , &tblCnt. + 1 , %STR(,) ) ^= );
		%LET tblCnt = %EVAL( &tblCnt. + 1 ) ;
        %LOCAL DS_NAME ;
        %LET DS_NAME =  %SYSFUNC(KSCAN( &tblList. , &tblCnt. , %STR(,) ) ) ;
		%LET DS_NAME = %SYSFUNC(KSCAN( &DS_NAME. , -1 , %STR(.) ) ) ;
		%LET DS_NAME = %SYSFUNC(KSCAN( &DS_NAME. , 1 , %STR(%() ) ) ;
		DATA &ERR_PRFIX._&DS_NAME. ;
			MERGE _&UUID._&tblCnt.( IN = DATA ) &rejectDS.(IN=ERR) ;
			BY %UNQUOTE(&groupBySpace.) ;
			IF DATA AND ERR THEN OUTPUT ;
		RUN;
        %LET tblArrSpace = &tblArrSpace. m_tbl_&UUID._&tblCnt. ;
        %END ;
   	proc datasets lib=work nolist nodetails nowarn;
        delete m_tbl_&UUID._: _&UUID._: ;
    run ;
%MEND; 
%ins_mcr_dict( 資料品質 , 
               mcr_compareStat( 資料集清單 ,群組維度清單 ,統計量清單 ) ,
			   對多個資料集指定欄位群組看統計量是否相同 )
/* 範例說明*/
/* 範例一:  master.key1 = 'b' 會跟  detail.key1 = 'b' 的加總對不起來 所以會出現在錯誤報表裡 

    data comp1 ; 
        key1 = "a" ; key2 = "a1" ; amt1 = 30 ; amt2 = 70 ; output ; 
        key1 = "b" ; key2 = "b1" ; amt1 = 1 ; amt2 = 3 ; output ; 
    run ; 
    data comp2 ; 
        key1 = "a" ; key2 = "a1" ; amt1 = 10 ; amt2 = 20 ; output ; 
        key1 = "a" ; key2 = "a1" ; amt1 = 20 ; amt2 = 50 ; output ; 
        key1 = "b" ; key2 = "b1" ; amt1 = 1 ; amt2 = 2 ; output ; 
        key1 = "b" ; key2 = "b1" ; amt1 = 1 ; amt2 = 3 ; output ; 
    run ; 
     options mprint; 
    %mcr_compareStat( "comp1,comp2" , "key1,key2" , "SUM(amt1),SUM(amt2)" ) ; 
*/
