/*程式名稱  : mcr_tagSrcOnTarget	                                     */
/*作者      : Andy                                                      */
/*處理概要  : 將Target table 根據 src 貼標                                */
/*輸入        : target( 目標表格 )
                DIMs( 能貼標的共同維度 )  
                SRCs ( "來源表格1 , 來源表格2 , ... , 來源表格n " 可以加上option )
				TARGET_WITH_TAG ( 挑標後的目標表格 ) 
                TAG_NAME ( 標籤變數名稱 )
                TAG_CNT (標籤個數變數名稱 )
                NO_TAG (未找到標籤資料 )
                ONLY_ONE_TAG( 恰有一個標籤資料 )
                MULTI_TAGS( 找到多個標籤的資料 ) 
             */
/*輸出      :  貼標後的TARGET 
              根據標籤分割後的小TARGET 
*/
%MACRO mcr_tagSrcOnTarget( target , 
                           DIMs   , 
                           SRCs   , 
                           TARGET_WITH_TAG , 
                           NO_TAG = _ERR_noTag ,
                           ONLY_ONE_TAG = _OnlyOne_TAG , 
						   MULTI_TAGS = _MULTI_TAGS ,
						   TAG_NAME = TAGNAME , 
						   TAG_CNT = TAG_CNT 
                           )  ;
	%LOCAL UUID i ;
	%LOCAL BY_DIMs DIMs_CNT;
	%LOCAL src_i  src_i_opt src_i_lib src_i_Name;
	%LOCAL MERGE_STMT ;
	%LOCAL bingo_SRC_STMT ;
	%LOCAL subTarget_STMT ;
	%LOCAL TAG_CNT_STMT ;
	%LOCAL TAR_NAME ;
	%LET TAR_NAME = %rtn_DSName( &target. ); 
	%LET TAR_NAME = %SYSFUNC(KSTRIP( &TAR_NAME. ) ) ;
 
	%LET TAG_CNT = %SYSFUNC(DEQUOTE( &TAG_CNT. ) ) ;
	%LET UUID = &SYSJOBID._&SYSINDEX. ;
	%LET DIM = %QSYSFUNC(DEQUOTE( &DIMs. )) ;
	%LET BY_DIMs = %SYSFUNC(TRANWRD( &DIM. , %STR(,) , %STR( ) ) ) ; 
	%LET DIMs_CNT = %SYSFUNC(COUNTW( &DIM. , %STR(,) ) ) ;
	%LET SRCs = %QSYSFUNC(DEQUOTE(&SRCs.)) ;
	%LET src_cnt = %SYSFUNC(countw(&SRCs.,%str(,))) ;
	%LET PREFIX = BINGO_ ;
	/* prepare nondup dimension var dataset for both target and sources */
	PROC SORT THREADS SORTSIZE=MAX DATA=&target. out=_&UUID._trgt ;
		BY &BY_DIMs. ; 
	RUN; 
	%LET MERGE_STMT =  ;
	%LET bingo_SRC_STMT = ;
	%LET subTarget_STMT = ;
	%LET TAG_CNT_STMT = &TAG_CNT. = SUM%STR(%() ; 
	%Do i = 1 %TO &src_cnt. ;
		%LET src_i = %SYSFUNC(KSCAN(&SRCs. , &i. , %str(,))) ;
		%LET src_i_lib = %rtn_DSLib( &src_i. ) ;
		%LET src_i_Name = %rtn_DSName( &src_i. ) ;
		%LET src_i_Opt = %rtn_DSOption( &src_i. ) ;
		%LET src_i = %QSYSFUNC(KSCAN( &src_i_opt , -1 , %STR(.) ) ) ;
		%LET src_i = %QSYSFUNC(KSCAN( &src_i. , 1 , %STR(%() ) ) ;
		%LET src_i = %QSYSFUNC(KSTRIP( &src_i. ) ) ; 
		
		PROC SORT DATA=&src_i_lib..&src_i_Name.( &src_i_Opt. ) 
                  THREADS 
                  SORTSIZE=MAX 
                  OUT=_&UUID._src_&i.(KEEP = &BY_DIMs.) nodupkey ;
			BY &BY_DIMs. ; 
		RUN; 
		%LET MERGE_STMT = &MERGE_STMT. _&UUID._src_&i.( IN = src_&i. ) ;
		%LET subTarget_STMT = &subTarget_STMT. _&TAR_NAME._&src_i_Name. (DROP = &PREFIX._: &TAG_CNT. &TAG_NAME. ) ;		
		%LET bingo_SRC_STMT =  &bingo_SRC_STMT. IF TRGT AND src_&i. THEN DO %STR(;)
                                    &TAG_NAME. = CATX( "," , KSTRIP(&TAG_NAME.) , "&src_i_Name." ) %STR(;) 
                                    &PREFIX._&src_i_Name. = 1 %STR(;) 
									OUTPUT _&TAR_NAME._&src_i_Name. %STR(;)
									END %STR(;) ;
		%IF &i. > 1 %THEN %LET TAG_CNT_STMT = &TAG_CNT_STMT. %STR(,) ;
		%LET TAG_CNT_STMT = &TAG_CNT_STMT. &PREFIX._&src_i_Name. ;
	%END;
	%LET MERGE_STMT = &MERGE_STMT. _&UUID._trgt( IN = TRGT ) ;
	%LET TAG_CNT_STMT = &TAG_CNT_STMT. %STR(%)) ;
	DATA &TARGET_WITH_TAG.(DROP = &PREFIX._: )
	     &NO_TAG.(DROP = &PREFIX._: &TAG_CNT. &TAG_NAME. )
		 &ONLY_ONE_TAG.( DROP = &PREFIX._: &TAG_CNT. )
		 &MULTI_TAGS.(DROP = &PREFIX._: )
         %UNQUOTE( &subTarget_STMT.) 
         ; 
		MERGE %UNQUOTE(&MERGE_STMT.) ;
		BY &BY_DIMs. ; 
		LENGTH &TAG_NAME. $200 ;
		%UNQUOTE(&bingo_SRC_STMT.) ;
		%UNQUOTE(&TAG_CNT_STMT.) ;
		IF MISSING( &TAG_CNT. ) THEN &TAG_CNT. = 0 ;
		IF TRGT THEN 	output &TARGET_WITH_TAG. ;
		IF TRGT AND &TAG_CNT. = 0 THEN OUTPUT &NO_TAG. ;
		IF TRGT AND &TAG_CNT. = 1 THEN OUTPUT &ONLY_ONE_TAG. ;
		IF TRGT AND &TAG_CNT. > 1 THEN OUTPUT &MULTI_TAGS. ;
	RUN ;
	
	proc datasets lib=work nolist nowarn nodetails;
		delete _&UUID.: ;
	run;

%MEND; 
/*範例說明*/
	/*範例一
	data src1 ;
		key = 'A' ; val = 1 ; output ;
		key = 'B' ; val = 2 ; output ; 
	run ;
	data src2 ;
		key2 = 'C' ; val = 1 ; output ;
		key2 = 'D' ; val = 2 ; output ;
		key2 = 'A' ; val = 3 ; output ;
		key2 = 'E' ; val = 1 ; output ;
	run ;
	data src3 ;
		key3 = 'E' ; val = 1 ; output ;
		key3 = 'F' ; val = 2 ; output ;
		key3 = 'G' ; val = 3 ; output ;
	run ;

	data target ; 
		Key = 'A' ; val = 11 ; output ; 
		Key = 'B' ; val = 22 ; output ;
		Key = 'H' ; val = 11 ; output ;
		Key = 'K' ; val = 11 ; output ;
		Key = 'C' ; val = 11 ; output ;
		Key = 'D' ; val = 11 ; output ;
	run;

	%mcr_tagSrcOnTarget(work.target , 
                       "key"        ,
                       "src1 , src2( RENAME=(KEY2=KEY)) , src3(RENAME=(KEY3=KEY))" ,
                       work.target_out)
	options fullstimer ;
	%mcr_tagSrcOnTarget(SCD.DTGDD003(WHERE=(ACNT_DATE LE '31JAN2019'd )) , 
                       "POLICY_NO"        ,
                       "QUERY.DTAAI001(KEEP = POLICY_NO) , 
                        QUERY.DTAAA010 (KEEP = POLICY_NO) , 
                        QUERY.DTAAB001_Q (KEEP = POLICY_NO), 
                        QUERY.DTAIZ000(KEEP = POLICY_NO)" ,
                        D003_TAGGED ,
						TAG_NAME=SRC ,
                        TAG_CNT=SRC_CNT ,
						NO_TAG = _Source_404 ,
                        ONLY_ONE_TAG = _Source_BINGO , 
						MULTI_TAGS = _Source_many 
                        )

	*/
%ins_mcr_dict( 資料探勘 , 
               mcr_tagSrcOnTarget( 目標表格 , 
                                   能貼標的共同維度 , 
                                   來源表格清單   , 
                                   貼標後結果     ) ,
			                       利用共同的維度，對來源表格貼上標籤  )
