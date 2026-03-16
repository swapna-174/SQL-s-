SELECT
	pat.PAT_NAME "Patient Name"
	,pat.PAT_MRN_ID "Patient MRN"
	,acct.HSP_ACCOUNT_ID
	,pat.BIRTH_DATE "Birth Date"
	,sex.NAME "Sex"
	,acct.ADM_DATE_TIME "Admit Date"
	,acct.DISCH_DATE_TIME "Discharge Date"
	,icdpx.REF_BILL_CODE "ICD9 Code"
	,icdpx.ICD_PX_NAME "ICD9 Name"
	--,CASE WHEN icdpx.REF_BILL_CODE IN ('68.31','68.39','68.41','68.49','68.61','68.69') THEN 'Hysterectomy' ELSE 'Colon'
	
	
FROM
	HSP_ACCT_PX_LIST pxlist
	INNER JOIN CL_ICD_PX icdpx ON pxlist.FINAL_ICD_PX_ID = icdpx.ICD_PX_ID
	INNER JOIN HSP_ACCOUNT acct ON pxlist.HSP_ACCOUNT_ID = acct.HSP_ACCOUNT_ID
	INNER JOIN CLARITY_DEP dep ON acct.DISCH_DEPT_ID = dep.DEPARTMENT_ID
	INNER JOIN PATIENT pat ON acct.PAT_ID = pat.PAT_ID
		LEFT JOIN ZC_SEX sex ON pat.SEX_C = sex.RCPT_MEM_SEX_C



WHERE
	TRUNC(acct.DISCH_DATE_TIME) BETWEEN to_date('2014-06-01', 'yyyy-mm-dd') AND to_date('2014-07-31', 'yyyy-mm-dd')
	AND dep.REV_LOC_ID = 10083
	AND icdpx.REF_BILL_CODE IN
	('17.31'
	,'17.32'
	,'17.33'
	,'17.34'
	,'17.35'
	,'17.36'
	,'17.39'
	,'45.03'
	,'45.26'
	,'45.41'
	,'45.49'
	,'45.52'
	,'45.71'
	,'45.72'
	,'45.73'
	,'45.74'
	,'45.75'
	,'45.76'
	,'45.79'
	,'45.81'
	,'45.82'
	,'45.83'
	,'45.92'
	,'45.93'
	,'45.94'
	,'45.95'
	,'46.03'
	,'46.04'
	,'46.10'
	,'46.11'
	,'46.13'
	,'46.14'
	,'46.43'
	,'46.52'
	,'46.75'
	,'46.76'
	,'46.94'
	,'68.31'
	,'68.39'
	,'68.41'
	,'68.49'
	,'68.61'
	,'68.69')