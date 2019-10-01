	%MACRO _dirSpaceGB()  ;
		%LET dir = %SYSFUNC(DEQUOTE(%SUPERQ(dir))) ;
		%LET rtn_space = 0;

		filename oscmd pipe "dir /s &dir.";

		data _null_;
			infile oscmd end=eof;
			input;
			if eof then do ; 
				put "aaa" _infile_ ;
				zz = kscan( _infile_ , 2 , "錄" ) ; 
				zz1 = kscan( zz , 1 , "位" ) ;
				ZZ2 = INPUTN( ZZ1 , "COMMA32.") ;
				zz3 = zz2/1073741824 ;
				call symputx( 'rtn_space' , zz3 ) ;
			end;
		run;
		
	%MEND; 
	PROC FCMP OUTLIB=WORK.FUNCS.dirSpaceGB ;
		FUNCTION dirSpaceGB( DIR $ )  ;
			length rtn_space 8 ;
			RC = run_macro( '_dirSpaceGB' ,
							DIR ,
                            rtn_space ) ;
			return(rtn_space) ;
		endsub ;
	RUN ;
	%ins_func_dict( 系統資訊 ,
                    dirSpaceGB( 目錄 ) , 
                    "返回目錄剩餘GB數" )
