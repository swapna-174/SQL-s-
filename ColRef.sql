-- *** SqlDbx Personal Edition ***
-- !!! Not licensed for commercial use beyound 90 days evaluation period !!!
-- For version limitations please check http://www.sqldbx.com/personal_edition.htm
-- Number of queries executed: 5580, number of rows retrieved: 12767567


SELECT --*
refr.REFERRAL_ID
,refr.pat_id
,refr.SERV_DATE
,refr.SVC_DATE_REAL
,refr.SCHED_STATUS_C
,zcss.NAME              "SCHED_STATUS"
,refr.SCHED_BY_DATE
,ref_dx.DX_ID
,enc.ENC_TYPE_C
,zcde.NAME          "ENCOUNTERY_TYPE"
,enc.CONTACT_DATE
,enc.APPT_STATUS_C
,zcas.NAME           "APPOINTMENT_STATUS"
,hsp.ACCT_BILLSTS_HA_C
,edg.DX_NAME
,dep.DEPARTMENT_NAME
,dep.DEPARTMENT_ID
,parloc.LOC_NAME
,enc.HSP_ACCOUNT_ID
FROM REFERRAL refr
INNER JOIN referral_dx ref_dx ON refr.REFERRAL_ID = ref_dx.REFERRAL_ID
INNER JOIN pat_enc enc ON refr.REFERRAL_ID = enc.REFERRAL_ID
LEFT OUTER JOIN hsp_account hsp ON enc.HSP_ACCOUNT_ID = hsp.HSP_ACCOUNT_ID 
LEFT OUTER JOIN EDG_CURRENT_ICD10 icd10 ON ref_dx.DX_ID = icd10.DX_ID
LEFT OUTER JOIN CLARITY_EDG edg ON ref_dx.DX_ID = edg.DX_ID
LEFT OUTER JOIN clarity_dep dep ON refr.REFD_BY_DEPT_ID = dep.DEPARTMENT_ID
LEFT OUTER JOIN clarity_loc loc ON dep.REV_LOC_ID = loc.LOC_ID
LEFT OUTER JOIN clarity_loc parloc ON loc.HOSP_PARENT_LOC_ID = parloc.LOC_ID
LEFT OUTER JOIN ZC_SCHED_STATUS zcss ON refr.SCHED_STATUS_C = zcss.SCHED_STATUS_C
LEFT OUTER JOIN ZC_DISP_ENC_TYPE zcde ON enc.ENC_TYPE_C = zcde.DISP_ENC_TYPE_C
LEFT OUTER JOIN ZC_APPT_STATUS zcas ON enc.APPT_STATUS_C = zcas.APPT_STATUS_C
WHERE
icd10.CODE = 'Z12.11' 
AND refr.SERV_DATE >= '1-jan-2019'
AND refr.SERV_DATE <= '31-jan-2019'
AND parloc.LOC_ID <> 100000
AND hsp.ACCT_FIN_CLASS_C = 4  --- uninsured




SELECT *
FROM CLARITY_EDG edg
WHERE
edg.CURRENT_ICD9_LIST LIKE '%V76.51%'

edg.REF_BILL_CODE = 'V76.51'
edg.PARENT_DX_ID = 15334


SELECT *
FROM EDG_CURRENT_ICD10 icd10
WHERE
icd10.CODE =  'Z12.11'