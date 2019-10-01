	%MACRO _SCD2Loading()  ; 
		
		%LET IN_TBL = %SYSFUNC(DEQUOTE( &IN_TBL. )) ;
		%LET DW_TBL = %SYSFUNC(DEQUOTE( &DW_TBL. )) ;
		%LET tran_dttm = %SYSFUNC(DEQUOTE( &tran_dttm. )) ;


	    %LOCAL valid_to_dttm ; 
		%LET valid_to_dttm = "01JAN5999 00:00:00"dt  ;	
		%LOCAL UUID ;
		%LET UUID = &SYSJOBID._&SYSINDEX. ; 
		%PUT NOTE: UUID = &UUID. ; 
	    %LOCAL valid_from_dttm ;
	    %LET valid_from_dttm = %SYSFUNC(INPUTN(&tran_dttm. ,NLDATM19.)) ; 

		/*parameter information*/
	    %LOCAL identifier ; 
	    %LET identifier = %sysfunc(scan(&DW_TBL. , -1 , %str(.) ) ) ;
	    %LOCAL IN_identifier ; 
	    %LET IN_identifier = %sysfunc(scan(&IN_TBL. , -1 , %str(.) ) ) ;

		%LOCAL DW_TBL_DS ;
		%LET DW_TBL_DS = %SYSFUNC(KSCAN( %SYSFUNC(KSCAN( &DW_TBL. , -1 , %STR(.) ) ) , 1 , %STR(%() ) );
		%PUT  NOTE:staring scd type 2 loading process , in  table  = &IN_TBL.  , out table = &DW_TBL.  ;
		%PUT NOTE:tran_dttm = &tran_dttm.  valid_to_dttm = &valid_to_dttm.  ;
		%LOCAL checkSum ;

		/* if DW_TBL is not exist , it does an initial load */ 
	    %IF %SYSFUNC( exist(&DW_TBL.) ) EQ 0 %THEN %DO;
			%PUT NOTE:Building Initial load .... ;
			proc contents data=&IN_TBL. out=_&UUID._Hash_diff nodetails noprint ; run; 
			proc sql noprint ; 
				select name 
				into: checkSum separated by ' ' 
				from _&UUID._Hash_diff
				WHERE UPCASE(NAME) NOT IN ("VALID_FROM_DTTM" , 
	                                       "VALID_TO_DTTM" )
				ORDER BY VARNUM
				;
			quit ;
			data &DW_TBL. ;
				format valid_from_dttm 
	                   valid_to_dttm 
					   &checkSum.
					   ;
				format VALID_FROM_DTTM  NLDATM19. ; 
				format VALID_TO_DTTM NLDATM19. ;
				set &IN_TBL. ;
				array CHR(*) _CHARACTER_ ;
				do i = 1 to DIM(CHR) ; 
					CHR(i) = kstrip( CHR(i) ) ; 
				end ;
				drop i  ;
				VALID_FROM_DTTM = &valid_from_dttm.  ;
				VALID_TO_DTTM = &valid_to_dttm. ;
			run ; %IF &syserr. gt 6 %THEN %ABORT cancel ;
			%GOTO exit ;
		%END;
		proc contents data=&DW_TBL. out=_&UUID._Hash_diff nodetails noprint ; run; 
		proc sql noprint ; 
			select name 
			into: checkSum separated by ' ' 
			from _&UUID._Hash_diff
			WHERE UPCASE(NAME) NOT IN ("VALID_FROM_DTTM" , 
	                                   "VALID_TO_DTTM" )
			ORDER BY VARNUM
			;
		quit ; 
		
	    /*define checkSum by removing left and right parentheses*/
		%PUT checkSum = &checkSum. ;
	    
		proc sort data = &DW_TBL. nodupkey sortsize=max threads out=&DW_TBL. force ;
			by VALID_TO_DTTM &checkSum. ;
		run;%IF &syserr. gt 6 %THEN %ABORT cancel ;
	    
		%PUT NOTE:extrating and sorting come in table ;

	    /* generate IN_TBL's checkSum and strip unprintable character */
		data _&UUID._IN  ;
			set &IN_TBL.(KEEP = &checkSum. ) ;
			array CHR{*} _CHARACTER_ ;
			do i = 1 to dim(CHR) ; 
				CHR(i) = kstrip( CHR(i) ) ; 
			end ;
			drop i ;
			VALID_TO_DTTM = &valid_to_dttm. ;
		run ; %IF &syserr. gt 6 %THEN %ABORT cancel ;
		proc sort data=_&UUID._IN nodupkey sortsize=max threads force out=_&UUID._IN ;
			by valid_to_dttm &checkSum. ;
		run ; %IF &syserr. gt 6 %THEN %ABORT cancel ;
		%PUT NOTE:merge by valid_to_dttm &checkSum. processing ... ;
		data &DW_TBL.;
			format valid_from_dttm 
	               valid_to_dttm 
				   &checkSum.
				   ;
			FORMAT valid_from_dttm NLDATM19. ;
			FORMAT valid_to_dttm NLDATM19. ;
			merge _&UUID._IN( in= Coming )  &DW_TBL.( in= haveExist ) ;
			by valid_to_dttm &checkSum. ;
			if not Coming and haveExist and valid_to_dttm = &valid_to_dttm. then do ;
				valid_to_dttm = %SYSEVALF( &valid_from_dttm. - 1 ) ;
			end ;
			if not haveExist and Coming then do;
				valid_from_dttm = &valid_from_dttm. ;
				valid_to_dttm = &valid_to_dttm. ;
			end  ;
		run ; %IF &syserr. gt 6 %THEN %ABORT cancel ;

	%exit:
	    /*kill temp file*/
		proc datasets lib=WORK nolist NOWARN NODETAILS ;
			delete _&UUID._:  ;
		QUIT; %IF &syserr. gt 6 %THEN %ABORT cancel ;

	%MEND;
	PROC FCMP OUTLIB=WORK.FUNCS.SCD2Loading ;
		FUNCTION SCD2Loading( IN_TBL $ ,DW_TBL $ ,TRAN_DTTM $ ) ;
			length RC 8 ;
			RC = run_macro( '_SCD2Loading' ,
							IN_TBL ,
                            DW_TBL ,
                            TRAN_DTTM ) ;
			return(RC) ;
		endsub ;
	RUN ;
	%ins_func_dict( DDS函數 ,
                    SCD2Loading( 本次快照資料集 ,歷程資料集 ,交易時間 ) , 
                    "進行Slowly Changing Type 2 歷程" )
