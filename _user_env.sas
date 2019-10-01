/*程式名稱	: _user_env 													*/
/*作者		: Andy                                                   */
/*處理概要	: 準備專案環境                                     			
	1. 環境相關參數設定
	2. OPTIONS設定
	3. 重要資料來源設定
	4. 倉儲資料存放設定
*/
%LET ENV_SET_STR = %SYSFUNC(DATETIME()) ;
%PUT 1.0 環境相關參數設定 ;
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
	%PUT NOTE: 判斷伺服器環境為 &SYSSCP.，路徑分隔字元為 &pathDlm.. ; 

%PUT 2.0 OPTIONS設定 ;
	OPTIONS MPRINT 
			NOQUOTELENMAX
			DLCREATEDIR 
			CMPLIB=WORK.FUNCS ;

%PUT 2.0 共用函數參數設定 ;
	%LET STRING_MAX_LEN = 20000 ;
	PROC DATASETS LIB=WORK NODETAILS NOLIST NOWARN ; 
		DELETE FUNCS ;
	RUN ;
	DATA WORK.FUNCS_DICT ;
		LENGTH FUNC_TYPE $20 ;
		LENGTH FUNC_NAME $100 ; 
		LENGTH FUNC_DESC $200 ;
		LABEL FUNC_TYPE = "函數應用種類" ;
		LABEL FUNC_NAME = "函數名稱與參數" ; 
		LABEL FUNC_DESC = "函數使用說明" ; 
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

%PUT 3.0 共用函數編譯 ;
	%LET FUN_DIR = &ROOTDIR.\FUN ; 
	filename FUN "&FUN_DIR.";
	%INCLUDE FUN('*.sas');
	PROC SORT DATA=WORK.FUNCS_DICT ;
		BY FUNC_TYPE FUNC_NAME ;
	RUN ;

%PUT 4.0 共用巨集編譯 ;
	DATA WORK.MCR_DICT ;
		LENGTH MCR_TYPE $20 ;
		LENGTH MCR_NAME $100 ; 
		LENGTH MCR_DESC $200 ;
		LABEL MCR_TYPE = "巨集應用種類" ;
		LABEL MCR_NAME = "巨集名稱與參數" ; 
		LABEL MCR_DESC = "巨集使用說明" ; 
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
		LABEL DESC = "專案說明事項" ;
		INPUT DESC $char1000.; 
DATALINES4;
1.專案目錄下檔案勿異動
        A. _user_env.sas : 專案環境設定程式.
        B. _user_lib.sas : 資料館宣告程式.
2.專案目錄下目錄說明
        A. CSV : 逗號分隔CSV檔.
        B. TXT : PIPE 分隔文字檔.
        C. EGP : EG專案.
        D. FUN : 專案函數原始碼.
        E. MCR : 專案巨集原始碼.
        F. JOB : ETL程式，程式前綴命名如下:
                F1. DQR 品質報表.
                F2. MET 程式元數據.
                F3. STG ETL程式.
                F4. DDS 歷程滾存程式.
                F5. MDB 分析型表格程式.
3.使用者可開自己的目錄，自行開發程式可透過已下指令編譯
        DATA TEST; 
             DIR = "相對專案目錄名稱" ;
             IF dirInclude( DIR ) THEN DO ;
                 ERR_DESC = "編譯錯誤" ;
                END;
        RUN ;
4.執行 _user_env 後資料館 WORK 會產生四個檔案
        A. FUNC / FUNCS_DICT : 專案支援函數相關資訊.
        B. MCR_DICT : 專案支援巨集相關資訊.
        C. README : 專案說明.
5. 環境說明:
        A. STG : 資料清洗區
        B. MET : 元數據儲存區
        C. DQR : 品質報表
        D. SHARE : 報表交付區
;;;;
	RUN;
	TITLE "專案說明";
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
		TITLE "專案支援函數清單" ;
	RUN ;
	TITLE "";
	FOOTNOTE "";
	PROC SORT DATA=WORK.MCR_DICT ;
		BY MCR_TYPE MCR_NAME ;
	RUN ;
	PROC PRINT DATA=WORK.MCR_DICT LABEL ; 
		TITLE "專案支援巨集清單" ;
	RUN ;

%LET ENV_SET_END = %SYSFUNC(DATETIME()) ;
%PUT 環境設定開始於: %SYSFUNC( PUTN( &ENV_SET_STR. , NLDATM19. )) ;
%PUT 環境設定結束於: %SYSFUNC( PUTN( &ENV_SET_END. , NLDATM19. )) ;

