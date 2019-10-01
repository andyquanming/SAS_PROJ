/*�{���W��  : mcr_mergeCmpr                                  */
/*�@��      : Andy                                              */
/*�B�z���n  : �N�D��(MST)�H�έn���p����(DTL) �ھ����(DIMs)Join��     
             1. �h���]����ӷ��y�������i���r��
             2. �i��ҥ~�B�z��Ʊư�EXCLDs
             3. �ھڳW�h��metadata �إ��ˮ־���K��
             4. ���X�@�P����/�t������/�p������
             5. �۰ʤ��ۦP���W�٭ȬO�_�@�P�ò��X���ҳ��i 
              */
/*��J      : MST(�D��/���������ɮ�)
             DTL(������/�n��X�h����)                                               
             DIMs(�n�ꪺ���סA�q�`�O�D�ɪ��D��A�Y�Ǫŭȶi�ӷ|�۰ʤ�� MST DTL�@�P���ק@���걵��key "DIM1,DIM2,...,DIMn" )
             OUTPREF(���X��ƶ����ɮצW�٪��e��)
             MSTABBR(�D�ɦW��²�١A�w�] MST�A���i�P���W�٭��| )
             CMPABBR(����ܼƦW�٫e��A�Y MST_DIM <> DTL_DIM �h CMP_DIM �� 1 )
             FIRSTSHOW ( �n��ܦb�e�������� "DIM1,DIM2,...,DIMn" )
             EXCLDs( �Ƕi�Ӫ��ҥ~�B�z��ƶ��W�١A�Ψӱư��ҥ~��� "DS1,DS2,....,DSn" )
             ruleMeta( �W�h��metadata )
             ruleID( metadata ���W�hID�ܼƦW�� )
             rulePower( metadata ���W�h�u�����ܼƦW�� )
             ruleCOND( metadata ���W�h�����ܼƦW�� )
             ruleSTMT( metadata ���W�h�ԭz�ܼƦW�� )
             mcr_loop( �j����O�V�q�ƪ� MACRO )
			 mcr_genRule ( �ѪRRULEMETA�� MACRO )
		     mcr_genRuleVars( �ѪR�PRULE���p���ܼ� MACRO )
             mcr_exportXls ( ����EXCEL���ҳ��i�� MACRO )
             SAVE_MODE( �w�] TRUE ���β����p���`�٪Ŷ� )
             CMP_REPORT( �w�] TRUE �������ҳ��i )
             XLSX_DIR ( ���ҳ��i���ͪ��ؿ� )
             fileDlm( �t���ɮ׸��|�����j�r�� ) 
             */
/*��X      : &OUTPREF.&MSTABBR.(����ɥ涰)
             &OUTPREF.&MSTABBR._ONLY(�Ȧs�b��D�ɪ����)
             &OUTPREF.DTL_ONLY(�Ȧs�b������ɪ����)
             &OUTPREF._UNION(����ɪ��p��)
             &OUTPREF.RPT_LOG( ���Ҳέp���i )
             _ERRDIM ( ���ҿ��~���� )
             */
%MACRO mcr_mergeCmpr(MST ,
	                 DTL ,
	                 DIMs ,
	                 OUTPREF ,
	                 MSTABBR=Mst ,
					 CMPABBR=Cmp ,
	                 FIRSTSHOW= ,
	                 EXCLDs= ,
	                 ruleMeta= ,
					 ruleID=rule_id ,
	                 rulePower=rule_power ,
	                 ruleCOND=COND , 
	                 ruleSTMT=STMT ,
                     mcr_loop=rtn_doOver ,
                     mcr_genRule=mcr_genRule ,
					 mcr_exportXls=mcr_exportXls ,
					 mcr_genRuleVars=mcr_genRuleVars,
					 MERGE_ONLY=FALSE ,
                     SAVE_MODE=TRUE ,
                     CMP_REPORT=TRUE ,
                     XLSX_DIR=rootDir ,
                     fileDlm=pathDlm )   ;
	%LOCAL UUID ;
	%LET UUID = &SYSJOBID._&SYSINDEX. ;
	%LET mcr_loop = %SYSFUNC(DEQUOTE(%SUPERQ(mcr_loop) ) );
	%LET FIRSTSHOW = %QSYSFUNC(DEQUOTE(%SUPERQ(FIRSTSHOW))) ;
	%LET OUTPREF = %SYSFUNC(DEQUOTE(%SUPERQ(OUTPREF))) ;
	%LET MSTABBR = %SYSFUNC(DEQUOTE(%SUPERQ(MSTABBR))) ;
	%LET CMPABBR = %SYSFUNC(DEQUOTE(%SUPERQ(CMPABBR))) ;
	%LET EXCLDs = %QSYSFUNC(DEQUOTE(%SUPERQ(EXCLDs))) ;
	%LET ruleMeta = %SYSFUNC(DEQUOTE(%SUPERQ(ruleMeta))) ;
	%LET SAVE_MODE = %SYSFUNC(DEQUOTE( %SUPERQ(SAVE_MODE) ) ) ;
	%LET XLSX_DIR = %SYSFUNC(KSTRIP( %SYSFUNC(DEQUOTE( %SUPERQ(XLSX_DIR) ) ) ) ) ;
	%LET fileDlm = %SYSFUNC(KSTRIP( %SYSFUNC(DEQUOTE(%SUPERQ(fileDlm))) ));
	%PUT ***************************************************************************;
	%PUT NOTE: �ˬd�Ѽƥ��T��. ;
	%PUT NOTE: �����X��m %UNQUOTE(%NRSTR(&)&XLSX_DIR.) ; 
    %PUT NOTE: �ɮפ��j�r�� %UNQUOTE(%NRSTR(&)&fileDlm.) ;
	%IF %SYSEVALF(%SUPERQ(MSTABBR) EQ , BOOLEAN ) %THEN %DO ; 
		%PUT ERROR: MSTABBR NAME INVALID ;
		%ABORT CANCEL ;
	%END ;
	%LOCAL OUTPREF_LEN MSTABBR_LEN CMPABBR_LEN VAR_MAX_LEN ; 
	%LET VAR_MAX_LEN = 32 ;
	%LET OUTPREF_LEN = %SYSFUNC(LENGTH(%SUPERQ(OUTPREF) )) ;
	%LET MSTABBR_LEN = %SYSFUNC(LENGTH(%SUPERQ(MSTABBR) )) ;
	%LET CMPABBR_LEN = %SYSFUNC(LENGTH(%SUPERQ(CMPABBR) )) ;
	%IF %SYSEVALF( &OUTPREF_LEN. + &MSTABBR_LEN.  > &VAR_MAX_LEN. ) OR 
		%SYSEVALF( &OUTPREF_LEN. + &MSTABBR_LEN. + 7 > &VAR_MAX_LEN. ) OR
  		%SYSEVALF( &OUTPREF_LEN. + 7 > &VAR_MAX_LEN. ) %THEN %DO ;
		%PUT NOTE: DATASET NAME TOO LONG. ;
		%PUT NOTE: &=OUTPREF_LEN. ;
		%PUT NOTE: &=MSTABBR_LEN. ;
		%ABORT CANCEL ;
	%END ;
	%IF %SYSEVALF( &CMPABBR_LEN. > 5 ) %THEN %DO ; 
		%PUT NOTE: CMPABBR ���׳̪��� 5. ;
		%ABORT CANCEL ;
	%END ;
	/* �ˬd���L�P���W�٭��| */
	PROC CONTENTS DATA = &MST. NOPRINT OUT = _&UUID._MST ; RUN ;
	DATA _&UUID._MST ; 
		SET _&UUID._MST ; 
		NAME = UPCASE(NAME) ; 
	RUN ;
	PROC CONTENTS DATA = &DTL. NOPRINT OUT = _&UUID._DTL ; RUN ;
	DATA _&UUID._DTL ; 
		SET _&UUID._DTL ; 
		NAME = UPCASE(NAME) ; 
	RUN ;
	PROC SQL NOPRINT ;
		CREATE TABLE _&UUID._ALLCOL AS 
			SELECT LIBNAME,MEMNAME,NAME
			FROM _&UUID._MST 
			UNION ALL 
			SELECT LIBNAME,MEMNAME,NAME
			FROM _&UUID._DTL 
			;
	QUIT ;
	%LOCAL CMP_INVAR MST_INVAR DTL_INVAR ;
	%LET CMP_INVAR = ;
	%LET MST_INVAR = ;
	%LET DTL_INVAR = ;
	PROC SQL NOPRINT ; 
		SELECT	CATX(".",LIBNAME,MEMNAME,NAME) 
		INTO :CMP_INVAR SEPARATED BY ','
		FROM _&UUID._ALLCOL
		WHERE NAME CONTAINS "&CMPABBR._" 
		;
		SELECT	CATX(".",LIBNAME,MEMNAME,NAME) 
		INTO :MST_INVAR SEPARATED BY ','
		FROM _&UUID._ALLCOL
		WHERE NAME CONTAINS "&MSTABBR._" 
		;
	QUIT ;
	%IF %SYSEVALF( %SUPERQ(CMP_INVAR) ^= ,BOOLEAN ) %THEN %DO ;	
		%PUT NOTE: CMPABBR �P���W�٭��|. &=CMP_INVAR. ;
		%ABORT CANCEL ;
	%END ;
	%IF %SYSEVALF( %SUPERQ(MST_INVAR) ^= ,BOOLEAN ) %THEN %DO ;	
		%PUT NOTE: MSTABBR �P���W�٭��|. &=MST_INVAR. ;
		%ABORT CANCEL ;
	%END ;

	%PUT NOTE: �ˬd�Q�ۨ� MACRO Code �O�_�s�b ;
	%PUT NOTE: �j�� &=mcr_loop. ;
	%PUT NOTE: ���� Rule SAS Code &=mcr_genRule. ;
	%PUT ***************************************************************************;

	%IF %SYSMACEXIST(&mcr_loop.) EQ 0 %THEN %DO ;
		%PUT NOTE: macro for loop doing does not exist. &=mcr_loop..  ;
		%abort cancel ;
	%END;
	%IF %SYSMACEXIST(&mcr_genRule.) EQ 0 %THEN %DO ;
		%PUT NOTE: macro for generating code does not exist. &=mcr_genRule..  ;
		%abort cancel ;
	%END;
	%IF %SYSMACEXIST(&mcr_exportXls.) EQ 0 %THEN %DO ;
		%PUT NOTE: macro for export excel report does not exist. &=mcr_exportXls..  ;
		%abort cancel ;
	%END;
	%IF %SYSMACEXIST(&mcr_genRuleVars.) EQ 0 %THEN %DO ;
		%PUT NOTE: macro for generate metadata does not exist. &=mcr_genRuleVars..  ;
		%abort cancel ;
	%END;
	%IF %SYMEXIST(&XLSX_DIR.) EQ 0 %THEN %DO ; 
		%PUT NOTE: path for export excel report does not exist. &=XLSX_DIR..  ;
		%abort cancel ;
	%END;
	%IF %SYMEXIST(&fileDlm.) EQ 0 %THEN %DO ; 
		%PUT NOTE: path delimiter does not exist. &=fileDlm..  ;
		%abort cancel ;
	%END;
	%PUT ***************************************************************************;
	%PUT NOTE: ���ͨϥΪ̦ۭq�W�h SAS Code. ;
	%PUT ***************************************************************************;
	%LOCAL i  ;
	%IF %SYSEVALF( %SUPERQ(RULEMETA) NE , BOOLEAN ) %THEN %DO ;
		%UNQUOTE(%nrstr(%%)%superq(mcr_genRule)(&ruleMeta. ,
							                   _&UUID._rule ,
							                   ID=&ruleID. ,
							                   power=&rulePower. ,
							                   condition=&ruleCOND. , 
							                   statement=&ruleSTMT. ,
                                               OUTDS_MCR = _&UUID._outDSs ) )	
	%END;

	%LOCAL MSTVALs DTLVALs MSTFMTs DTLFMTs MSTLENs DTLLENs COMMON_DIMs ;
	%LET DIMs = %QUPCASE(%QSYSFUNC(DEQUOTE(%SUPERQ(DIMs)))) ;
	PROC SQL NOPRINT ;
		SELECT A.NAME 
		INTO  : COMMON_DIMs SEPARATED BY ','
		FROM _&UUID._MST A INNER JOIN _&UUID._DTL B 
		ON (A.NAME = B.NAME)
		;
		SELECT A.NAME 
		INTO  : COMMON_VALs SEPARATED BY ','
		FROM _&UUID._MST A INNER JOIN _&UUID._DTL B 
		ON (A.NAME = B.NAME)
		WHERE A.NAME NOT IN ( %UNQUOTE( %UNQUOTE(%nrstr(%%)%superq(mcr_loop)( "&DIMs." ,'"?"' , OUT_DLM="%STR(,)")) )) 
		;
	QUIT ;
	%PUT ***************************************************************************;
	%PUT NOTE: Ū����ƶ���METADATA �]�t�ܼ� �W�� ���� FORMAT  ;
	%PUT NOTE: �@�P���׬� &COMMON_DIMs. ;
	%IF %SYSEVALF( &DIMs. = , BOOLEAN ) %THEN %DO ;
		%PUT NOTE: ���w���׬��šA�H�@�P���ר��N�B�� ; 
		%LET DIMs = %SUPERQ(COMMON_DIMs) ;
	%END;
	%PUT ***************************************************************************;
	%LET MSTVALs = ;
    %LET DTLVALs = ;
	%LET MSTFMTs = ;
	%LET DTLFMTs = ;
	%LET MSTLENs = ; 
	%LET DTLLENs = ;
	PROC SQL NOPRINT ;
		SELECT NAME 
        INTO :MSTVALs SEPARATED BY ','
		FROM _&UUID._MST
		WHERE NAME NOT IN ( %UNQUOTE( %UNQUOTE(%nrstr(%%)%superq(mcr_loop)( "&DIMs." ,'"?"' , OUT_DLM="%STR(,)")) )) ;
	QUIT;
	PROC SQL NOPRINT ;
		SELECT CASE 
                  WHEN FORMAT IN ( "DATE" , "DATETIME" )
                  THEN " FORMAT " || KSTRIP(NAME) || " " || KSTRIP(FORMAT) || KSTRIP(PUTN(FORMATL,"8.")) ||"."
				  ELSE " " END AS FMT_STMT
        INTO :MSTFMTs SEPARATED BY ','
		FROM _&UUID._MST
		WHERE NAME NOT IN ( %UNQUOTE( %UNQUOTE(%nrstr(%%)%superq(mcr_loop)( "&DIMs." ,'"?"' , OUT_DLM="%STR(,)")) )) 
		AND CALCULATED FMT_STMT is not missing
	    ;
		SELECT CASE 
                  WHEN TYPE EQ 2 
                  THEN " LENGTH " || KSTRIP(NAME) || " $" || KSTRIP(PUTN(LENGTH,"8.")) 
				  END AS LEN_STMT
        INTO :MSTLENs SEPARATED BY ','
		FROM _&UUID._MST
		WHERE NAME NOT IN (%UNQUOTE( %UNQUOTE(%nrstr(%%)%superq(mcr_loop)( "&DIMs." ,'"?"' , OUT_DLM="%STR(,)")))) 
		AND CALCULATED LEN_STMT is not missing
		;
	QUIT;
	PROC SQL NOPRINT ;
		SELECT NAME 
        INTO :DTLVALs SEPARATED BY ','
		FROM _&UUID._DTL
		WHERE NAME NOT IN (%UNQUOTE( %UNQUOTE(%nrstr(%%)%superq(mcr_loop)( "&DIMs." ,'"?"' , OUT_DLM="%STR(,)")))) ;
	QUIT;
	PROC SQL NOPRINT ;
		SELECT CASE 
	              WHEN FORMAT IN ( "DATE" , "DATETIME" )
	              THEN " FORMAT " || KSTRIP(NAME) || " " || KSTRIP(FORMAT) || KSTRIP(PUTN(FORMATL,"8.")) ||"." 
				  ELSE " " END AS FMT_STMT
	    INTO :DTLFMTs SEPARATED BY ','
		FROM _&UUID._DTL
		WHERE NAME NOT IN (%UNQUOTE( %UNQUOTE(%nrstr(%%)%superq(mcr_loop)( "&DIMs." ,'"?"' , OUT_DLM="%STR(,)")))) 
		AND CALCULATED FMT_STMT is not missing
		;
		SELECT CASE 
                  WHEN TYPE EQ 2 
                  THEN " LENGTH " || KSTRIP(NAME) || " $" || KSTRIP(PUTN(LENGTH,"8.")) 
				  END AS LEN_STMT
        INTO :DTLLENs SEPARATED BY ','
		FROM _&UUID._DTL
		WHERE NAME NOT IN (%UNQUOTE(%UNQUOTE(%nrstr(%%)%superq(mcr_loop)( "&DIMs.",'"?"' , OUT_DLM="%STR(,)")))) 
		AND CALCULATED LEN_STMT is not missing
		;
	QUIT ;
	%PUT ***************************************************************************;
	%PUT NOTE: Ū����ƶ���METADATA ;
	%PUT NOTE: �n���p���@�P���׬� &DIMs. ;
	%PUT NOTE:�D�ɪ����צ� &MSTVALs.. ;
	%PUT NOTE:�����ɪ����צ� &DTLVALs.. ;
	%PUT NOTE: �D���l��쬰 &=MSTVALs. ; 
    %PUT NOTE: �����l��쬰 &=DTLVALs. ; 
    %PUT NOTE: �D�����榡�� &=MSTFMTs. ;
    %PUT NOTE: �������榡�� &=DTLFMTs. ;
	%PUT ***************************************************************************;
	
	%LOCAL i EXCLD EXCLD_LIST EXCLDs_CNT ; 
	%LET EXCLDs_CNT = %SYSFUNC(COUNTW(&EXCLDs. , %STR(,))) ;
	%PUT ***************************************************************************;
	%PUT NOTE: �קK�W�٭��ơA�ܼƥ[�W�e�󭫩R�W�B�z ; 
	%PUT NOTE: �ư��ҥ~��ƲM�� ;
	%DO i = 1 %TO &EXCLDs_CNT. ;
		%PUT NOTE:      %SYSFUNC(KSCAN(&EXCLDs. , &i. , %STR(,))) ;
	%END ;
	%PUT NOTE: �� %SYSFUNC(KSTRIP(%SUPERQ(DIMs))) ���Ƨ� ;
	%PUT ***************************************************************************;
	%DO i = 1 %TO &EXCLDs_CNT. ;
		%IF %SYSEVALF( &i. = 1 ) %THEN %DO;
			%LET EXCLD_LIST = &i. ;
			%END;
		%ELSE %DO ;
		    %LET EXCLD_LIST = &EXCLD_LIST.%STR(,)&i. ;
		    %END ;
		%LET EXCLD = %SYSFUNC(KSCAN(&EXCLDs. , &i. , %STR(,))) ;

		%LOCAL _&UUID._MST_&i  _&UUID._DTL_&i;
		%LOCAL _chkSum_&UUID._MST_&i. _chkSum_&UUID._DTL_&i. ;
		PROC CONTENTS DATA=&EXCLD. NOPRINT OUT=_&UUID._EXCLD ; RUN ;
		PROC SQL NOPRINT ;
			SELECT KSTRIP(A.NAME)
			INTO : _&UUID._MST_&i. SEPARATED BY ','
			FROM _&UUID._MST A INNER JOIN _&UUID._EXCLD B
			ON A.NAME = B.NAME 
			;
		QUIT;
		PROC SQL NOPRINT ;
			SELECT KSTRIP(A.NAME)
			INTO : _&UUID._DTL_&i. SEPARATED BY ','
			FROM _&UUID._DTL A INNER JOIN _&UUID._EXCLD B
			ON A.NAME = B.NAME 
			;
		QUIT;
		%IF %SYSEVALF( %SUPERQ(_&UUID._MST_&i.) NE ,BOOLEAN) %THEN %DO ;
			PROC SQL NOPRINT;
				SELECT '"' || PUTC( SHA256(CATX("|" , &&&_&UUID._MST_&i.)) , "HEX64.") || '"'
				INTO : _chkSum_&UUID._MST_&i. SEPARATED BY ','
				FROM &EXCLD. 
				;
			QUIT;
			%LET _&UUID._MST_&i. = PUTC(SHA256(CATX("|",&&&_&UUID._MST_&i.)),"HEX64.") ;
		%END;
		%IF %SYSEVALF( %SUPERQ(_&UUID._DTL_&i.) NE ,BOOLEAN) %THEN %DO ;
			PROC SQL NOPRINT;
				SELECT '"' || PUTC( SHA256(CATX("|" , &&&_&UUID._DTL_&i.)) , "HEX64.") || '"'
				INTO : _chkSum_&UUID._DTL_&i. SEPARATED BY ','
				FROM &EXCLD. 
				;
			QUIT;
			%LET _&UUID._DTL_&i. = PUTC(SHA256(CATX("|",&&&_&UUID._DTL_&i.)),"HEX64.") ;
		%END; 
	%END ;
	PROC SORT DATA = &MST.
	          THREADS 
	          SORTSIZE=MAX 
	          NODUPKEY 
			  DUPOUT=&OUTPREF._MSTDUP
	          OUT = _&UUID._SORTED_MST
			       (WHERE=( 1 = 1 
				   			%DO i = 1 %TO &EXCLDs_CNT. ; 
						  		%IF %SYSEVALF(%SUPERQ(_&UUID._MST_&i.) NE ,BOOLEAN) %THEN %DO ;
					            		AND &&&_&UUID._MST_&i. NOT IN ( &&&_chkSum_&UUID._MST_&i. )
								%END;
					        %END ;
                           )
                    )
	          	 ;
	  	BY %UNQUOTE(%UNQUOTE(%nrstr(%%)%superq(mcr_loop)( "&DIMs." ,'?') )) ;
	RUN;
	PROC SORT DATA = &DTL.
	          THREADS 
	          SORTSIZE=MAX
			      NODUP 
	          OUT = _&UUID._SORTED_DTL
                    (WHERE=( 1 = 1 
				   			%DO i = 1 %TO &EXCLDs_CNT. ; 
						  		%IF %SYSEVALF(%SUPERQ(_&UUID._DTL_&i.) NE ,BOOLEAN) %THEN %DO ;
					            		AND &&&_&UUID._DTL_&i. NOT IN ( &&&_chkSum_&UUID._DTL_&i. )
								%END;
					        %END ;
                           )
                    )
	          	 ;
	  	BY %UNQUOTE(%UNQUOTE(%nrstr(%%)%superq(mcr_loop)( "&DIMs." , '?' ) )) ;
	RUN;

	PROC DATASETS LIB=WORK NOLIST NOWARN NODETAILS ;
			MODIFY _&UUID._SORTED_MST ;
				RENAME %UNQUOTE(%UNQUOTE(%nrstr(%%)%superq(mcr_loop)("%SUPERQ(MSTVALs)" ,"? = &MSTABBR._? ")));
	RUN ;
	
	%PUT ***************************************************************************;
	%PUT NOTE: �����X�֧@�~ ; 
	%IF %SYSEVALF(%SUPERQ(RULEMETA) NE ,BOOLEAN) %THEN %DO ;
		%PUT NOTE: �W�hmetadata �B�~���ͲM��: ;
		%DO i = 1 %TO %SYSFUNC(COUNTW( %SUPERQ(_&UUID._outDSs) , %STR(,) ) );
			%PUT NOTE: 	    %SYSFUNC(KSCAN( %SUPERQ(_&UUID._outDSs) , &i. , %STR(,) ) ) ;
		%END;
	%END;
	%PUT ***************************************************************************;
	%LOCAL DIM_SPACE ; 
	%LET DIM_SPACE = %UNQUOTE(%UNQUOTE(%nrstr(%%)%superq(mcr_loop)( "&DIMs." , '?'))) ;
	DATA &OUTPREF.&MSTABBR.
		 %IF %SUPERQ(MERGE_ONLY)=TRUE %THEN %DO ; 
			(DROP = _TYPE_ &CMPABBR.: )
		 %END ;
		 %IF %SYSEVALF( %SUPERQ(MERGE_ONLY)=FALSE ) %THEN %DO ;
		     &OUTPREF.&MSTABBR._ONLY (
		        KEEP = %UNQUOTE( %UNQUOTE(%nrstr(%%)%superq(mcr_loop)( "&DIMs." , '?'))) &MSTABBR._:
		        RENAME=( %UNQUOTE(%UNQUOTE( %nrstr(%%)%superq(mcr_loop)( "%SUPERQ(MSTVALs)" , "&MSTABBR._? = ? ")))) )
		     &OUTPREF.DTL_ONLY( DROP = _TYPE_ &MSTABBR._: &CMPABBR._: )
			%IF %SYSEVALF(%SUPERQ(SAVE_MODE) ^= TRUE , BOOLEAN ) %THEN %DO ;
			     &OUTPREF.UNION( DROP = &CMPABBR._: )
			%END;
			%IF %SYSEVALF(%SUPERQ(RULEMETA) NE ,BOOLEAN) %THEN %DO ;
				%DO i = 1 %TO %SYSFUNC(COUNTW( %SUPERQ(_&UUID._outDSs) , %STR(,) ) );
					%SYSFUNC(KSCAN( %SUPERQ(_&UUID._outDSs) , &i. , %STR(,) ) )
				%END;
			%END;
		%END;
	     ;
	    /*��ܶ���*/
		FORMAT %UNQUOTE(%UNQUOTE(%nrstr(%%)%superq(mcr_loop)( "&FIRSTSHOW." , '?'))) 
               _TYPE_
			   &DIM_SPACE.
			   %UNQUOTE(%UNQUOTE(%nrstr(%%)%superq(mcr_loop)( "&MSTVALs." , '&MSTABBR._?')))
			   &CMPABBR._SUM
			   %UNQUOTE(%UNQUOTE(%nrstr(%%)%superq(mcr_loop)( "&MSTVALs." , '&CMPABBR._?')))
               ;
		/*��ƨӷ�*/
		MERGE _&UUID._SORTED_DTL(IN=DTL_ININDER) 
		      _&UUID._SORTED_MST(IN=MST_ININDER) ;
		BY &DIM_SPACE. ;

		/*�M�����k���i���r��*/
		ARRAY CHR(*) _CHARACTER_ ;
		DO i = 1 to DIM(CHR) ; 
			CHR(i) = kstrip( CHR(i) ) ; 
		END ;
		DROP i;
		/*���ᵲ�G����*/
		LENGTH _TYPE_ $20 ;
		_TYPE_ = "";

		/*OUTPUT �q��*/
		/*�Y���۩w�q�W�h�A���ƻs�ܼơA�M��p��A�i�঳ OUTPUT*/
		%IF %SYSEVALF( %SUPERQ(RULEMETA) NE , BOOLEAN ) %THEN %DO ;	
			%unquote(%superq(_&UUID._rule)) ;
		%END;
		IF _N_ = 1 THEN DO ;
			ARRAY NUM(*) _NUMERIC_ ;
			ARRAY CHAR(*) _CHARACTER_ ; 
			LENGTH VAR_LIST $32600;
			RETAIN VAR_LIST ;
			DO i = 1 to dim(CHAR) ;
				VAR_LIST = catx(",",kstrip(VAR_LIST) , '"'||vname(CHAR{i})||'"' ) ;
			END ;
			DO i = 1 to dim(NUM) ;
				VAR_LIST = catx(",",kstrip(VAR_LIST) , '"'||vname(NUM{i})||'"'  );
			END ;
			CALL SYMPUTX("_&UUID._LL",VAR_LIST) ;
			DROP VAR_LIST  ;
		END ;
	    %IF %SYSEVALF( %SUPERQ(RULEMETA) NE , BOOLEAN ) %THEN %DO ;		
			/* �۰ʤ��ۦP�W�r����� */
			%UNQUOTE(%UNQUOTE(%nrstr(%%)%superq(mcr_loop)( "%SUPERQ(MSTVALs)" , "&CMPABBR._? = 0 ; " )));
			%UNQUOTE(%UNQUOTE(%nrstr(%%)%superq(mcr_loop)( "%SUPERQ(MSTVALs)" ,
	                                                       "IF &MSTABBR._? NE ? THEN DO ; &CMPABBR._? = 1 ; END ; " )));
		%END;
		%ELSE %DO ;
		   /* �۰ʤ��ۦP�W�r����� */
			%UNQUOTE(%UNQUOTE(%nrstr(%%)%superq(mcr_loop)( "%SUPERQ(COMMON_VALs)" , "&CMPABBR._? = 0 ; " )));
			%UNQUOTE(%UNQUOTE(%nrstr(%%)%superq(mcr_loop)( "%SUPERQ(COMMON_VALs)" ,
	                                                       "IF &MSTABBR._? NE ? THEN DO ; &CMPABBR._? = 1 ; END ; " )));
		%END;
		&CMPABBR._SUM = SUM( OF &CMPABBR._:) ;
		
		IF DTL_ININDER AND MST_ININDER THEN DO ; 
			_TYPE_ = "bothExist" ;
			OUTPUT &OUTPREF.&MSTABBR.;
		END;

		%IF %SYSEVALF( %SUPERQ(MERGE_ONLY)=FALSE ) %THEN %DO ;
			IF DTL_ININDER AND NOT MST_ININDER THEN DO ;
				_TYPE_ = "onlyDetailExist" ;
				OUTPUT &OUTPREF.DTL_ONLY ;
			END ;
			IF MST_ININDER AND NOT DTL_ININDER THEN DO ; 
				_TYPE_ = "onlyMasterExist" ;
				OUTPUT &OUTPREF.&MSTABBR._ONLY ;
			END;
			%IF %SYSEVALF(%SUPERQ(SAVE_MODE) ^= TRUE , BOOLEAN ) %THEN %DO ;
				OUTPUT &OUTPREF.UNION ;
			%END;
		%END ;
	RUN;

	%IF %SYSEVALF( %SUPERQ(MERGE_ONLY)=FALSE ) %THEN %DO ;
		DATA &OUTPREF.STAT ;
			LENGTH TABLE $100 ;
			LENGTH OBS_CNT 8 ;
			TABLE = "&OUTPREF.MSTDUP" ; OUTPUT ;
			TABLE = "&OUTPREF.&MSTABBR." ; OUTPUT ;
			TABLE = "&OUTPREF.&MSTABBR._ONLY" ; OUTPUT ; 
			TABLE = "&OUTPREF.DTL_ONLY" ; OUTPUT ;
			TABLE = "%SUPERQ(MST)" ; OUTPUT ; 
			TABLE = "%SUPERQ(DTL)" ; OUTPUT ; 
			LABEL TABLE = "���W��" ;
			LABEL OBS_CNT = "��Ƶ���" ; 
		RUN ; 
		DATA &OUTPREF.STAT ;
			set &OUTPREF.STAT ;
			LENGTH LIBNAME $20 ; 
			LENGTH DSNAME $80 ;
			LIBNAME = UPCASE( KSCAN( "WORK." || KSTRIP(TABLE) , -2 , "." ) ) ;
			DSNAME = UPCASE( KSCAN( KSCAN( KSTRIP(TABLE) , 1 , "(" ) , -1 , "." ) ) ;		
			LABEL LIBNAME = "����]�W��" ; 
			LABEL DSNAME = "��ƶ��W��" ; 
		RUN ; 
		
		DATA &OUTPREF.STAT ; 
			SET &OUTPREF.STAT ;
			LENGTH SQL_CMD $20000 ; 
			SQL_CMD = " select nobs from dictionary.tables where libname = '" 
	                  || KSTRIP(LIBNAME) || "' AND MEMTYPE = 'DATA' AND MEMNAME = '" 
	                  || KSTRIP(DSNAME) || "'" ;
			OBS_CNT = sqlQry( KSTRIP(SQL_CMD) ) ;
			IF CMISS(OBS_CNT) THEN DO ; OBS_CNT = 0 ; END ;
		RUN ;
	%END;

	PROC DATASETS LIB=WORK NOLIST NOWARN NODETAILS ;
		DELETE _&UUID._: ;
	RUN ;

	%IF %SYSEVALF(%SUPERQ(CMP_REPORT) = TRUE , BOOLEAN) AND 
		%SUPERQ(MERGE_ONLY)=FALSE %THEN %DO ;
		%LOCAL DIRPATH ; 
		%LET DIRPATH = %UNQUOTE(%NRSTR(&)&XLSX_DIR..) ;
		%LOCAL fDlm ;
		%LET fDlm = %UNQUOTE(%NRSTR(&)&fileDlm..) ;

		PROC CONTENTS DATA=&OUTPREF.&MSTABBR._ONLY OUT=_&UUID._MST_META(KEEP=NAME) NOPRINT ; RUN ;
		PROC CONTENTS DATA=&OUTPREF.DTL_ONLY OUT=_&UUID._DTL_META(KEEP=NAME) NOPRINT ; RUN ;
		PROC SQL ; 
			CREATE TABLE &OUTPREF.MST_CHECKED AS 
				SELECT  A.NAME AS MST_LIST , 
					    CASE WHEN A.NAME IN ( &&_&UUID._LL. ) THEN "V" ELSE "" END AS CHECKED 
				FROM 	_&UUID._MST_META A 
				;
		QUIT ;
		%UNQUOTE(%nrstr(%%)%superq(mcr_exportXls)( "&OUTPREF.MST_CHECKED" , "&DIRPATH.&fDlm.&OUTPREF.&MSTABBR._ERR.xlsx" ))
		/* ��X����諸���� */
		%LOCAL CHECKED_LIST ;
		PROC SQL NOPRINT; 
			SELECT  "&CMPABBR._" || KSTRIP(MST_LIST) 
			INTO :  CHECKED_LIST SEPARATED BY ','
			FROM 	&OUTPREF.MST_CHECKED 
			WHERE CHECKED = 'V' 
			;
		QUIT ;

		/*���X�D��DUP���*/
		%IF %sysfunc(exist(&OUTPREF.&MSTABBR.DUP)) %THEN %DO ;
			%UNQUOTE(%nrstr(%%)%superq(mcr_exportXls)( "&OUTPREF.&MSTABBR.DUP" , "&DIRPATH.&fDlm.&OUTPREF.&MSTABBR._ERR.xlsx" ))
		%END;
 
		/* ���X�u�s�b�D�ɩΩ����ɿ��~��� */
		%IF %sysfunc(exist(&OUTPREF.&MSTABBR._ONLY)) %THEN %DO ;
			%UNQUOTE(%nrstr(%%)%superq(mcr_exportXls)( "&OUTPREF.&MSTABBR._ONLY" , "&DIRPATH.&fDlm.&OUTPREF.&MSTABBR._ERR.xlsx" ))
		%END;
		%IF %sysfunc(exist(&OUTPREF.DTL_ONLY)) %THEN %DO ;
			%UNQUOTE(%nrstr(%%)%superq(mcr_exportXls)( "&OUTPREF.DTL_ONLY" , "&DIRPATH.&fDlm.&OUTPREF.&MSTABBR._ERR.xlsx" ))
		%END;

		/* ���X��靈�~����`��*/
		%LOCAL ERR_ALL ; 
		%LET ERR_ALL = &CMPABBR._ALLErr ;
		PROC SQL ;
			CREATE TABLE _&UUID._&ERR_ALL. as 
				SELECT 	* 
				FROM 	&OUTPREF.&MSTABBR.(KEEP = &DIM_SPACE. &CMPABBR._: )
				WHERE &CMPABBR._SUM > 0 
				;
		QUIT ;
		PROC CONTENTS DATA=_&UUID._&ERR_ALL. NOPRINT OUT=_&UUID._cmprList(KEEP=NAME) ; RUN ; 

		%IF %SYSEVALF(%SUPERQ(ruleMeta) NE , BOOLEAN ) %THEN %DO ; 
			%GLOBAL mcr_varScope ;
			%LET mcr_varScope = "xx" ;
			PROC SQL NOPRINT;
				SELECT NAME
				INTO :mcr_varScope separated by ","
				FROM _&UUID._DTL_META
				;
			QUIT ;
		%END;
		DATA &OUTPREF.RPT_LOG;
			SET _&UUID._cmprList ;
			IF NAME NOT IN ( %UNQUOTE(%UNQUOTE(%nrstr(%%)%superq(mcr_loop)( "&CHECKED_LIST." , '"?"',OUT_DLM=','))) ) THEN DELETE ; 
			IF NAME IN ( %UNQUOTE(%UNQUOTE(%nrstr(%%)%superq(mcr_loop)( "&DIMs." , '"?"',OUT_DLM=',')))  ) THEN DELETE ;
			_VAR = TRANWRD( NAME , "&CMPABBR._" , "" ) ; 
			CMP_VAR = "&CMPABBR._" || KSTRIP( _VAR ) ;
			MST_VAR = "&MSTABBR._" || KSTRIP( _VAR ) ;
			DTL_VAR = KSTRIP( _VAR ) ;
			MST_DTL = "&OUTPREF.&MSTABBR." ;
			_VAR_CNT_MCR = KSTRIP(_VAR) || '_CNT' ;
			ERR_DTLName = "_" || KSTRIP( _VAR ) ; 
			MCR_RelVars = "MCR_VAR_" || KSTRIP(_VAR) ; 
			MCR_RelRules = "MCR_RUL_" || KSTRIP(_VAR) ;
			%IF %SYSEVALF(%SUPERQ(ruleMeta) NE , BOOLEAN ) %THEN %DO ; 
				LENGTH VAR_SCOPE $ 1000 ;
				VAR_SCOPE = SYMGET('mcr_varScope') ;
				CALL EXECUTE( '%nrstr(%%)%superq(mcr_genRuleVars)( "' || 
	                                    KSTRIP(VAR_SCOPE) || '" ,' ||
										KSTRIP(_VAR) || " , &ruleMeta. ," || ' rtn_VARs=' ||
										KSTRIP(MCR_RelVars) || ', rtn_IDs=' || 
										KSTRIP(MCR_RelRules) || ' )' ) ;
			%END;
			OUTPATH = "&DIRPATH." ;
			OUTFILE = KSTRIP(OUTPATH) || "&fDlm." || KSTRIP(MST_DTL) || '_ERR.xlsx' ;
			PKEYs = %UNQUOTE(%STR(%')%UNQUOTE(%UNQUOTE(%nrstr(%%)%superq(mcr_loop)( "&DIMs." , '?' , OUT_DLM=',' )))%STR(%')) ;
			LABEL _VAR = "�t���ܼƦW��" ; 
			LABEL CMP_VAR = "�O�_���t��" ;
			LABEL MST_VAR = "�D���ܼƤ��e" ; 
			LABEL DTL_VAR = "�������ܼƤ��e" ; 
			LABEL MST_DTL = "���ӷ�" ; 
            LABEL OUTPATH = "���i���X��Ƨ�" ; 
			LABEL OUTFILE = "���i���|" ;
		RUN; 
		DATA &OUTPREF.RPT_LOG;
			SET &OUTPREF.RPT_LOG;
			LENGTH _RelVars $10000 ;
			LENGTH _RelRules $10000 ;
			%IF %SYSEVALF(%SUPERQ(ruleMeta) NE , BOOLEAN ) %THEN %DO ; 
				_RelVars = SYMGET( MCR_RelVars ) ; 
				_RelRules = SYMGET( MCR_RelRules ) ; 
			%END;
			LABEL _RelVars = "Rule Meta ���������ܼ�" ; 
			LABEL _RelRules = "Rule Meta ���������W�h" ; 
		RUN ;
		DATA &OUTPREF.RPT_LOG;
			SET &OUTPREF.RPT_LOG ;
			LENGTH _q_RelVars $ 1000 ;
			LENGTH self_q_RelVars $1000 ;
			IF CMISS( KSTRIP(_RelVars) ) THEN DO ; 
				_q_RelVars = "" ;
				_RelDim = "" ;
				END ;
			ELSE DO ;
				self_q_RelVars = "";
				DO i = 1 to countw(_RelVars ,",") ;
					if cmiss(kstrip(self_q_RelVars)) then do ;
						self_q_RelVars = kstrip( kscan(_RelVars , i , "," ) ) ; 
						end ; 
					else do ; 
						self_q_RelVars = kstrip(self_q_RelVars) || "," || kstrip( kscan(_RelVars , i , "," ) ) ;
					end ;
				END;
				_q_RelVars = self_q_RelVars ;
				_RelDim = "," ;
			END;
			drop i self_q_RelVars;
			CALL EXECUTE( 'PROC SQL ;' ) ;
			CALL EXECUTE( '		CREATE TABLE ' || KSTRIP(ERR_DTLName) || ' AS ' ) ;
			CALL EXECUTE( '        	SELECT ' || KSTRIP(PKEYs)  )   ;
			CALL EXECUTE( ' , ' || KSTRIP( MST_VAR) || ' , ' ||KSTRIP( DTL_VAR) || " "
	                            || 	KSTRIP(_RelDim) || 	KSTRIP(_q_RelVars) ) ;
			CALL EXECUTE( ' FROM ' || KSTRIP(MST_DTL) ) ;
			CALL EXECUTE( ' WHERE ' || KSTRIP( CMP_VAR ) || ' > 0 ;' ) ;
			CALL EXECUTE( ' QUIT ; ' ) ;
			CALL EXECUTE( ' PROC SQL NOPRINT ; ' ) ; 
			CALL EXECUTE( ' 	SELECT COUNT(*) ' ) ;
			CALL EXECUTE( '		INTO : ' ||KSTRIP(_VAR_CNT_MCR) || ' SEPARATED BY "," ' ) ;
			CALL EXECUTE( '		FROM ' ||KSTRIP( ERR_DTLName ) ) ;
			CALL EXECUTE( ' ; QUIT ;' ) ;
		RUN;
		DATA &OUTPREF.RPT_LOG (KEEP=_VAR OUTFILE _ERR_CNT _RelRules) ;
			SET &OUTPREF.RPT_LOG ; 
			_ERR_CNT = SYMGET( _VAR_CNT_MCR ) ;
			IF CMISS( KSTRIP(_RelRules) ) THEN DO ;
				_RelRules = '' ;
				END ;
			ELSE DO ;
				_RelRules = KSTRIP(TRANWRD( _RelRules , '"' , "'" ) )  ;
			END;
			IF _ERR_CNT EQ 0 THEN DO ; 
				CALL EXECUTE( ' PROC SQL ; DROP TABLE ' || KSTRIP(ERR_DTLName) || ' ; QUIT ; ' ) ; 
			END ;
			export_mcr = "&mcr_exportXls." ;
			IF _ERR_CNT GT 0 THEN DO ; 
				CALL EXECUTE( ' %NRSTR(%%)' ||
                                KSTRIP( export_mcr ) || 
                                '( ' || KSTRIP( ERR_DTLName) || ' ,' ||
								KSTRIP( OUTFILE ) || ' ) ' ) ; 
			END ; 
		RUN;
		%UNQUOTE(%nrstr(%%)%superq(mcr_exportXls)( "&OUTPREF.RPT_LOG" , 
                                                   "&DIRPATH.&fDlm.&OUTPREF.&MSTABBR._ERR.xlsx" ))
		%PUT ***************************************************************************;
		%PUT NOTE: �����s�@�~ ; 
		%PUT NOTE: ���s���| &DIRPATH.&fDlm.&OUTPREF.&MSTABBR._ERR.xlsx ;
		%PUT ***************************************************************************;
	%END; 

	PROC DATASETS LIB=WORK NOLIST NOWARN NODETAILS ;
		DELETE _&UUID._: ;
	RUN ;
%MEND ;

%ins_mcr_dict( ��ƫ~�� , 
               mcr_mergeCmpr( �D�n��ƶ� ,
	                          �������� ,
	                          �걵����   ,
	                          ���X����e�� ) ,
			   �N�D��(MST)�H�έn���p����(DTL) �ھ����(DIMs)Join��     
	             1. �h���]����ӷ��y�������i���r��
	             2. �i��ҥ~�B�z��Ʊư�EXCLDs
	             3. �ھڳW�h��metadata �إ��ˮ־���K��
	             4. ���X�@�P����/�t������/�p������
	             5. �۰ʤ��ۦP���W�٭ȬO�_�@�P�ò��X���ҳ��i )
