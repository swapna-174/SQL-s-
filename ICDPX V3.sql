SELECT
	CASE WHEN icdpx.REF_BILL_CODE IN ('68.31','68.39','68.41','68.49','68.61','68.69') THEN 'Hysterectomy' ELSE 'Colon' END "Procedure Type"
	,pat.PAT_NAME "Patient Name"
	,pat.PAT_MRN_ID "Patient MRN"
	,acct.HSP_ACCOUNT_ID "HAR"
	,sex.NAME "Gender"
	,pat.BIRTH_DATE "Birth Date"
	,PAT_SURG.SURGERY_DATE "Date of Procedure"
	,acct.ADM_DATE_TIME "Admit Date"
	,acct.DISCH_DATE_TIME "Discharge Date"
	,icdpx.REF_BILL_CODE "ICD9 Code"
	,icdpx.ICD_PX_NAME "ICD9 Name"
	
FROM
	HSP_ACCT_PX_LIST pxlist
	INNER JOIN CL_ICD_PX icdpx ON pxlist.FINAL_ICD_PX_ID = icdpx.ICD_PX_ID
	INNER JOIN HSP_ACCOUNT acct ON pxlist.HSP_ACCOUNT_ID = acct.HSP_ACCOUNT_ID
	INNER JOIN (SELECT
									min(hsptran.SERVICE_DATE) "SURGERY_DATE"
									,hsptran.HSP_ACCOUNT_ID
							   FROM 
							   		HSP_TRANSACTIONS hsptran 
									INNER JOIN OR_LOG log ON hsptran.OPTIME_LOG_ID = log.LOG_ID
								GROUP BY hsptran.HSP_ACCOUNT_ID) PAT_SURG ON acct.HSP_ACCOUNT_ID = PAT_SURG.HSP_ACCOUNT_ID
	INNER JOIN CLARITY_DEP dep ON acct.DISCH_DEPT_ID = dep.DEPARTMENT_ID
	INNER JOIN PATIENT pat ON acct.PAT_ID = pat.PAT_ID
		LEFT JOIN ZC_SEX sex ON pat.SEX_C = sex.RCPT_MEM_SEX_C
			
WHERE
	acct.DISCH_DATE_TIME BETWEEN to_date('2015-05-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss') AND to_date('2015-06-15 23:59:59', 'yyyy-mm-dd hh24:mi:ss')
	AND dep.REV_LOC_ID = 10083
	AND pxlist.FINAL_ICD_PX_ID IN ('5643','5656','5665','5668','5671','5675','5676','5677','5678','5679','5680','5681','5685','5686','5687','5688','5691','5692','5693','5694','5695','5696'
																		,'5708','5711','5721','5722','5731','6350','6351','6352','6353','6356','6357','8152','8153','8154','8155','8156','8157','8158','8172','8173','8174')
	
ORDER BY
"Procedure Type"
,"Patient Name"