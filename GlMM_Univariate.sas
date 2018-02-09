*Generate p-value for GLMM Univariate;

*output: work.glim;

*cov: covariate list;
*Ncat: threshold for defining continous variables;

%macro glim(indata=, cov=, Ncat=,lib=, out=);
%let k = 1;
proc datasets library=&lib.;
delete glim;
run;
data glim;
run;
%do %while (%scan(&cov.,&k.) NE );
	%let var_now = %scan(&cov.,&k.);
  		proc freq data = &indata. noprint;
    	table &var_now. / out = number;
  		run;

  		data number;
    	set number;
		call symput('cats', _N_); *macro variable assignment: return number of categories into "cats";
 		run;

  		%if &cats. > &Ncat. %then 
			%do;
	  		*continous variable;
			proc glimmix data=&indata. NAMELEN=32;
			class char_id;
			model &out.= &var_now.  /dist=binary;
			random intercept /subject=char_id;
			ods output tests3=p_value ConvergenceStatus=converge;
			run;
			%end;
		%else
			%do;
			*categorical variable;
			proc glimmix data=&indata. NAMELEN=32;
			class char_id &var_now.;
			model &out. = &var_now.  /dist=binary;
			random intercept /subject=char_id;
			ods output tests3=p_value ConvergenceStatus=converge;
			run;
			%end;

			data _null_;
			set converge;
			call symput ("status", status);
			run;
			
			%if &status.=1 %then %let k=&k.+1; %else 
			%do;
			data glim;
			format effect $100.;
			set glim p_value;
			run;
			%end;
			%let k = %eval(&k.+1);
%end;
%mend;
