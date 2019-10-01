	%MACRO _genDQR()  ;

		%LET ruleid_prefix = %SYSFUNC(DEQUOTE(&ruleid_prefix.)) ;
		%LET metadata = %SYSFUNC(DEQUOTE( &metadata. )) ; 
		%LET INOBS = %SYSFUNC(DEQUOTE( &INOBS. )) ;

		%LOCAL UUID ; 
		%LET UUID = &SYSJOBID._&SYSINDEX. ; 
				
		PROC SQL ; 
			CREATE TABLE _&UUID._1( INDEX=( TRGT_COM ) ) AS
				SELECT * 
				FROM &metadata. 
				WHERE TRGT_TBL = "%KSCAN(&ruleid_prefix.,-1 ,%STR(.))"
				;
		QUIT ; 
		%LOCAL BAS_STMT JNR_STMT TAG_STMT ERR_STMT ;
		PROC SQL NOPRINT ; 
			SELECT CASE	
						WHEN COM_SER = 1 THEN "( " || KSTRIP(EXPR) ||  ") " || ALIAS  
						ELSE "INNER JOIN (" || 
	                         KSTRIP(EXPR)   || 
	                         ")"            || 
	                         KSTRIP(ALIAS)  || 
	                         "ON"           ||
	                         KSTRIP(ASMP)   
				   END
			INTO : BAS_STMT SEPARATED BY "%SYSFUNC(BYTE(10))"
			FROM _&UUID._1
			WHERE TRGT_COM = "BAS"
			ORDER BY COM_SER  
			;
			SELECT "LEFT JOIN (" || 
		           KSTRIP(EXPR)  ||
		           ") "          ||
		           KSTRIP(ALIAS) || 
		           " ON "        ||
		           KSTRIP(ASMP)
			INTO : JNR_STMT SEPARATED BY "%SYSFUNC(BYTE(10))"
			FROM _&UUID._1 
			WHERE TRGT_COM = "JNR"
			;
			SELECT CASE 
						WHEN CMISS(ASMP) THEN KSTRIP(EXPR) || 
	                                          " AS "       || 
	                                          KSTRIP( ALIAS ) 
						ELSE "CASE %SYSFUNC(BYTE(10))" ||
							 " WHEN "                  ||  
							 KSTRIP(ASMP)              || 
	                         " THEN "                  ||  
	                         KSTRIP( EXPR )            || 
	                         " END AS "                || 
	                         KSTRIP(ALIAS) 
				   END 
			INTO : ERR_STMT SEPARATED BY ','
			FROM _&UUID._1
			WHERE TRGT_COM = "ERR"
			;
			SELECT CASE 
						WHEN CMISS(ASMP) THEN KSTRIP(EXPR) || 
	                                          " AS "       || 
	                                          KSTRIP( ALIAS ) 
						ELSE "CASE %SYSFUNC(BYTE(10))" ||
							 " WHEN "                  ||  
							 KSTRIP(ASMP)              || 
	                         " THEN "                  ||  
	                         KSTRIP( EXPR )            || 
	                         " END AS "                || 
	                         KSTRIP(ALIAS) 
				   END 
			INTO : TAG_STMT SEPARATED BY ','
			FROM _&UUID._1
			WHERE TRGT_COM = "TAG"
			;
		QUIT ;  	
		%PUT ********************************************************************** ;
		%PUT NOTE: &BAS_STMT. ;
		%PUT ********************************************************************** ;
		%PUT NOTE: &JNR_STMT. ; 
		%PUT ********************************************************************** ;
		%PUT NOTE: &TAG_STMT. ;  
		%PUT ********************************************************************** ;
		%PUT NOTE: &ERR_STMT. ;  
		%PUT ********************************************************************** ;
		PROC SQL %IF %SYSEVALF( &INOBS. > 0 ) %THEN %DO ; inobs=&inobs. %END ; 
                 THREADS MAGIC = 103 _METHOD STIMER FEEDBACK ERRORSTOP  ;
			CREATE TABLE &ruleid_prefix._DTL AS 
				SELECT *
	                   %IF %SYSEVALF(%SUPERQ(ERR_STMT) ^= ,BOOLEAN) %THEN %DO ; %STR(,) &ERR_STMT. %END; 
					   %IF %SYSEVALF(%SUPERQ(TAG_STMT) ^= ,BOOLEAN) %THEN %DO ; %STR(,) &TAG_STMT. %END; 
				FROM &BAS_STMT.
			    &JNR_STMT.
		        ;
		QUIT;%IF &SYSERR. > 6 %THEN %ABORT CANCEL ;
		%LOCAL SUM_STMT ;
		PROC SQL NOPRINT ;  
			SELECT "SUM(" || KSTRIP(ALIAS ) || ") AS " || KSTRIP(ALIAS ) ||"_CNT" 
			INTO :SUM_STMT SEPARATED BY ','
			FROM _&UUID._1
			WHERE TRGT_COM = "ERR"
			;
		QUIT ;
		%IF %SYSEVALF(%SUPERQ(SUM_STMT) ^= , BOOLEAN) %THEN %DO ; 
			PROC SQL ; 
				CREATE TABLE _&UUID._2 AS 
				SELECT &SUM_STMT. 
				FROM &ruleid_prefix._DTL
				;
			QUIT ; 
			PROC TRANSPOSE DATA=_&UUID._2 
			               NAME=ERR_VAR
			               OUT=_&UUID._3(RENAME=(COL1=ERR_CNT)) ;
			RUN ;
			PROC SQL ; 
				CREATE TABLE &ruleid_prefix._MST AS 
					SELECT A.* , B.ERR_CNT 
					FROM _&UUID._1(WHERE=( TRGT_COM = "ERR")) A 
					LEFT JOIN _&UUID._3 B 
					ON ( CATS(A.ALIAS,"_CNT") = B.ERR_VAR ) 
					ORDER BY ERR_CNT
					;
			QUIT ; 
			%LOCAL TOTAL_CNT ;
			%IF %SYSEVALF( %SUPERQ(inobs) = , BOOLEAN) %THEN %DO ;
				PROC SQL NOPRINT ; 
					SELECT COUNT(*) 
					INTO :TOTAL_CNT 
					FROM &ruleid_prefix._DTL
					;
				QUIT ;
				%END;
			%ELSE %DO ; 
				%LET TOTAL_CNT = &INOBS. ;
			%END ; 
			DATA _&UUID._INDEX ;
				set &ruleid_prefix._MST end=eof ;
				length index_list $2000 ;
				retain index_list ;
				if err_cnt / &TOTAL_CNT. < 0.15 then do ;
					index_list = catx(" " , index_list , ALIAS ) ;
				end ;
				if eof then do ; 
					out_dtl = "&ruleid_prefix._dtl" ;
					call execute( 'data ' || kstrip(out_dtl) || '( index = ( ' || kstrip(index_list) || ')) ;' ) ;
					call execute( ' set ' ||  kstrip(out_dtl) || ' ; ' ) ;
					call execute( 'run ;' ) ;
				end ;
			RUN ; 
		%END;

		PROC DATASETS LIB=WORK NOLIST NODETAILS NOWARN ;
			DELETE _&UUID._: ; 
		RUN ;
	%MEND;  
	PROC FCMP OUTLIB=WORK.FUNCS.genDQR ;
		FUNCTION genDQR( ruleid_prefix $ ,METADATA $ , INOBS ) ;
			length RC 8 ;
			RC = run_macro( '_genDQR' ,
                            ruleid_prefix ,
                            METADATA ,
							INOBS ) ;
			return(RC) ;
		endsub ;
	RUN ;
	%ins_func_dict( 元數據管理 ,
                    genDQR( 報表檔名稱前綴 ,規則控制檔 ,最大檢核筆數_0為全檢) ,
                    "產出規則檢核統計表/明細表" )
