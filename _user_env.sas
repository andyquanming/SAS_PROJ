/*�{���W��	: _user_env 													*/
/*�@��		: Andy                                                   */
/*�B�z���n	: �ǳƱM������                                     			
	1. ���Ҭ����ѼƳ]�w
	2. OPTIONS�]�w
	3. ���n��ƨӷ��]�w
	4. ���x��Ʀs��]�w
*/
%LET ENV_SET_STR = %SYSFUNC(DATETIME()) ;
%PUT 1.0 ���Ҭ����ѼƳ]�w ;
	%LET envFullName=&_SASPROGRAMFILE.%sysfunc(getoption(sysin)) ; 
	%LET ROOTDIR = %SYSFUNC(DEQUOTE(%SYSFUNC(TRANSTRN(%SUPERQ(envFullName) ,\_user_env.sas ,%STR())))) ;
	%PUT &ROOTDIR. ;
	
	%MACRO check_pathDlm() ;
		%GLOBAL pathDlm ;
		%IF &SYSSCP. = WIN %THEN %DO ;
			%LET pathDlm = %STR(\) ;
			%END;
		%ELSE %DO;
			%LET pathDlm = %STR(/) ;
			%END ;
	%MEND;
	%check_pathDlm
	%PUT NOTE: �P�_���A�����Ҭ� &SYSSCP.�A���|���j�r���� &pathDlm.. ; 

%PUT 2.0 OPTIONS�]�w ;
	OPTIONS MPRINT 
			NOQUOTELENMAX
			DLCREATEDIR 
			CMPLIB=WORK.FUNCS ;

%PUT 2.0 �@�Ψ�ưѼƳ]�w ;
	%LET STRING_MAX_LEN = 20000 ;
	PROC DATASETS LIB=WORK NODETAILS NOLIST NOWARN ; 
		DELETE FUNCS ;
	RUN ;
	DATA WORK.FUNCS_DICT ;
		LENGTH FUNC_TYPE $20 ;
		LENGTH FUNC_NAME $100 ; 
		LENGTH FUNC_DESC $200 ;
		LABEL FUNC_TYPE = "������κ���" ;
		LABEL FUNC_NAME = "��ƦW�ٻP�Ѽ�" ; 
		LABEL FUNC_DESC = "��ƨϥλ���" ; 
		STOP ; 
	RUN ; 
	%MACRO ins_func_dict( func_type , func_name , func_desc )  ;
		%LET FUNC_TYPE = %QSYSFUNC(DEQUOTE(%SUPERQ(func_type)));
		%LET func_name = %QSYSFUNC(DEQUOTE(%SUPERQ(func_name)));
		%LET func_desc = %QSYSFUNC(DEQUOTE(%SUPERQ(func_desc)));

		PROC SQL; 
			INSERT INTO WORK.FUNCS_DICT VALUES( "&func_type." ,
										   %SYSFUNC(COMPBL("&func_name.")) ,
                                           %SYSFUNC(COMPBL("&func_desc.")) ) ;
		QUIT ;
	%MEND; 

%PUT 3.0 �@�Ψ�ƽsĶ ;
	%LET FUN_DIR = &ROOTDIR.\FUN ; 
	filename FUN "&FUN_DIR.";
	%INCLUDE FUN('*.sas');
	PROC SORT DATA=WORK.FUNCS_DICT ;
		BY FUNC_TYPE FUNC_NAME ;
	RUN ;

%PUT 4.0 �@�Υ����sĶ ;
	DATA WORK.MCR_DICT ;
		LENGTH MCR_TYPE $20 ;
		LENGTH MCR_NAME $100 ; 
		LENGTH MCR_DESC $200 ;
		LABEL MCR_TYPE = "�������κ���" ;
		LABEL MCR_NAME = "�����W�ٻP�Ѽ�" ; 
		LABEL MCR_DESC = "�����ϥλ���" ; 
		STOP ; 
	RUN ; 
	%MACRO ins_mcr_dict( mcr_TYPE , mcr_name , mcr_desc )  ;
		%LET mcr_TYPE = %QSYSFUNC(DEQUOTE(%SUPERQ(mcr_TYPE)));
		%LET mcr_name = %QSYSFUNC(DEQUOTE(%SUPERQ(mcr_name)));
		%LET mcr_desc = %QSYSFUNC(DEQUOTE(%SUPERQ(mcr_desc)));

		PROC SQL; 
			INSERT INTO WORK.MCR_DICT VALUES( "&mcr_TYPE." ,
										   %SYSFUNC(COMPBL("&mcr_name.")) ,
                                           %SYSFUNC(COMPBL("&mcr_desc.")) ) ;
		QUIT ;
	%MEND; 
	%LET MCR_DIR = &ROOTDIR.\MCR ; 
	filename MCR "&MCR_DIR.";
	%INCLUDE MCR('*.sas');

%PUT 999.0 README ;
	DATA WORK.README;
		INFILE DATALINES4 DLM='|' DSD TRUNCOVER;
		LENGTH DESC $1000 ;
		LABEL DESC = "�M�׻����ƶ�" ;
		INPUT DESC $char1000.; 
DATALINES4;
1.�M�ץؿ��U�ɮפŲ���
        A. _user_env.sas : �M�����ҳ]�w�{��.
        B. _user_lib.sas : ����]�ŧi�{��.
2.�M�ץؿ��U�ؿ�����
        A. CSV : �r�����jCSV��.
        B. TXT : PIPE ���j��r��.
        C. EGP : EG�M��.
        D. FUN : �M�ר�ƭ�l�X.
        E. MCR : �M�ץ�����l�X.
        F. JOB : ETL�{���A�{���e��R�W�p�U:
                F1. DQR �~�����.
                F2. MET �{�����ƾ�.
                F3. STG ETL�{��.
                F4. DDS ���{�u�s�{��.
                F5. MDB ���R�����{��.
3.�ϥΪ̥i�}�ۤv���ؿ��A�ۦ�}�o�{���i�z�L�w�U���O�sĶ
        DATA TEST; 
             DIR = "�۹�M�ץؿ��W��" ;
             IF dirInclude( DIR ) THEN DO ;
                 ERR_DESC = "�sĶ���~" ;
                END;
        RUN ;
4.���� _user_env �����] WORK �|���ͥ|���ɮ�
        A. FUNC / FUNCS_DICT : �M�פ䴩��Ƭ�����T.
        B. MCR_DICT : �M�פ䴩����������T.
        C. README : �M�׻���.
5. ���һ���:
        A. STG : ��ƲM�~��
        B. MET : ���ƾ��x�s��
        C. DQR : �~�����
        D. SHARE : �����I��
;;;;
	RUN;
	TITLE "�M�׻���";
	PROC REPORT data=WORK.README  nowd;
	  columns DESC;
	  define DESC / style(column)={asis=on};
	RUN;
	TITLE "";
	FOOTNOTE "";
	PROC SORT DATA=WORK.FUNCS_DICT ;
		BY FUNC_TYPE FUNC_NAME ;
	RUN ;
	PROC PRINT DATA=WORK.FUNCS_DICT LABEL ; 
		TITLE "�M�פ䴩��ƲM��" ;
	RUN ;
	TITLE "";
	FOOTNOTE "";
	PROC SORT DATA=WORK.MCR_DICT ;
		BY MCR_TYPE MCR_NAME ;
	RUN ;
	PROC PRINT DATA=WORK.MCR_DICT LABEL ; 
		TITLE "�M�פ䴩�����M��" ;
	RUN ;

%LET ENV_SET_END = %SYSFUNC(DATETIME()) ;
%PUT ���ҳ]�w�}�l��: %SYSFUNC( PUTN( &ENV_SET_STR. , NLDATM19. )) ;
%PUT ���ҳ]�w������: %SYSFUNC( PUTN( &ENV_SET_END. , NLDATM19. )) ;

