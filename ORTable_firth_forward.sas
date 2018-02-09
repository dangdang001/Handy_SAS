*macro created on 04/07/2016 to do multivariable logistic regression with forward selectin and firth correction;

*only applied when both the covariates and outcome are categorical;
*have to define format: "1Yes", "2No" for all the binary variables(0/1) first;

*in: input dataset;
*out: output dataset;
*var: outcome variable in the logistic regression;
*sig: significant variables selected fron the univariate descriptive analysis;
*z: the variable we care about, want it to be displayed in the final results anyway;
*dir: directory to store the rtf files;

%macro oddstableff(in=,var=,sig=,z=,out=,dir=);

proc contents data = &in. noprint
  out = &in._log;
run;
proc sort data = &in._log;
  by varnum;
run;
data &in._reg;
  set &in._log;
  if label = '' then label = name;
run;


*forward selection;

proc logistic data = &in. NAMELEN=32;
class &sig.;
model &var. (event = '1Yes') = &sig. /selection=forward;
ods output Type3=temp1; *store the variables selected by the forward selection at "temp1";
run ;

*delete the replicated variable "z" if "z" is also selected by last step;
data temp2;
set temp1;
if Effect in ("&z.") then delete;
run;

*store the significant variables into macro variable: sig1->sig2;

proc sql noprint;
select effect
into :sig1 separated by " "
from temp2;
quit;

%put &sig1;
%if %symexist(sig1) %then %let sig2= &z. &sig1;
%else %let sig2= &z. ;
%put sig2;

*add statement as a macro into the proc logistic later(function as print);
%macro oddstat(var_now);
  oddsratio &var_now. /cl=pl;
%mend;

ods output type3=type3_&var.  OddsRatiosPL=odds_&var. ;
proc logistic data = &in. NAMELEN=32;
class  &sig2.;
model &var. (event = '1Yes') = &sig2. /firth clodds=pl;
*add oddsratio statement for pairwise odds ratio comparision for levels of each variable;
%let k = 1;
%do %while (%scan(&sig2.,&k.) NE );
  %let var_now = %scan(&sig2.,&k.);
%oddstat(&var_now.);
%let k = %eval(&k.+1);
%end;
run;

%symdel sig2;


%macro mergerd(odd,test,outdata,vlabel);
data &odd.;
	set &odd.;
	ord +1;
	variable=scan(effect,1);
	levels=substr(effect,length(variable)+2);
	ci=strip(put(LowerCL,8.2))||"-"||strip(put(Uppercl,8.2));
run;
proc sql;
	create table &outdata. as
	select c.*,d.label
	from
	(select a.ord, a.variable,a.levels, a.OddsRatioEst,a.ci,b.ProbChiSq
	from &odd. as a left join &test. as b
	on a.variable=b.effect) as c
	left join &vlabel. as d
	on c.variable=d.name
    order by c.ord;
quit;
%mend mergerd;


%mergerd(odds_&var., type3_&var., &out. , &in._reg);

proc format;
value ftotal
low - 0.05 = 'red';
value btotal
low - 0.05 = 'white';
run;
%put &today;
ods escapechar = '^';
options orientation=portrait center nodate;
ods rtf file="&dir.\temp\reg_&var..rtf" bodytitle style=custom1;
proc report data = &out. spanrows nowd
style(header)=[ fontsize=3]
style(column)=[fontsize=3];
  column label levels -- ProbChiSq;
  title "Estimated odds ratios and their 95% confidence intervals for &var.";
define levels--label/center;
define levels/"Levels";
define label/ "Variable" order order = data ;
define ci/"95% CI";
define ProbChiSq/ "P-value"  order center missing style(column)=[just=center cellwidth=1.25in] format=pvalue6.4 style={background=btotal. foreground=ftotal.};
run;
ods rtf close;

%mend oddstableff;
