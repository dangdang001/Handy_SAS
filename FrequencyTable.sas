/*This macro is for generating the freqency tables for variable*/

*dir: the directory you want to save the output rtf file;
*filename: the name of the rtf file;
*var: variable name;
*in: input dataset;
*sort: 1: by descending count 2:by variable values;

%macro freqtable(dir=,filename=,var=, in=, sort=);

proc freq data=&in.;
tables &var./nocum out=&in._&filename.;
run;

data &in._&filename.;
set &in._&filename.;
PERCENT_new=round(trim(left(PERCENT)),0.01)||"%";
run;

%if sort=1 %then;
%do;
proc sort data=&in._&filename.;
by descending count;
run;
%end;

%if sort=2 %then;
%do;
proc sort data=&in._&filename.;
by &var.;
run;
%end;

options nodate nonumber;
ods escapechar = '^';
options orientation=portrait center;
ods rtf file="&dir.\&in._&filename..rtf" bodytitle style=custom1;
proc report data = &in._&filename. spanrows nowd 
style(header)=[ fontsize=3]
style(column)=[fontsize=3];
	column &var. count PERCENT_new;
  	title "Frequency table for &var.";
define &var. --PERCENT_new/center;
define COUNT/"Frequency";
define PERCENT_new/"Percent" ;
run; 
ODS RTF CLOSE;

%mend freqtable;
