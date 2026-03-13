select DISTINCT
'WAKE FOREST' SITE_ID
,cdep.DEPARTMENT_NAME
,fsch.PAT_ENC_CSN_ID
,pat.PAT_MRN_ID
,pat.PAT_FIRST_NAME
,pat.PAT_LAST_NAME
,TO_CHAR(pat.BIRTH_DATE, 'MM/DD/YYYY') BIRTH_DATE
,zcsex.NAME GENDER
,pat.HOME_PHONE PATIENT_PHONE
,pat.EMAIL_ADDRESS PATIENT_EMAIL
,cser.PROV_ID PROVIDER_ID
,SUBSTR(cser.PROV_NAME, INSTR(cser.PROV_NAME,',', 1, 1)+1) PROVIDER_FIRST_NAME
,SUBSTR(cser.PROV_NAME, 1 ,INSTR(cser.PROV_NAME, ',', 1, 1)-1) PROVIDER_LAST_NAME
,'25311,31487,31488' EMMI_PROG_CODE--- to be determined
,TO_CHAR(fsch.APPT_DTTM, 'MM/DD/YYYY')   VIEW_BY_DATE
,'F72D58B4-C2CD-486A-A3D2-B8599132E96A' CLIENT_ID
,'' BLANK
,(CASE WHEN pmyc.MYCHART_STATUS_C = 1
        THEN 1
           ELSE 0 END) PORTAL_STATUS
from F_SCHED_APPT fsch
LEFT OUTER JOIN (
SELECT
par.PAT_ID
,par.REGISTRY_ID
,regc.REGISTRY_NAME
FROM PAT_ACTIVE_REG par
INNER JOIN REGISTRY_CONFIG regc ON par.REGISTRY_ID = regc.REGISTRY_ID
WHERE
regc.REGISTRY_NAME LIKE '%ACO%'
)ACOS ON ACOS.PAT_ID = fsch.PAT_ID
left outer join HSP_ACCOUNT ha on fsch.HSP_ACCOUNT_ID = ha.HSP_ACCOUNT_ID
left outer join HSP_ATND_PROV hap on fsch.PAT_ENC_CSN_ID = hap.PAT_ENC_CSN_ID
and hap.line = (select max(hap1.line) from HSP_ATND_PROV hap1 where hap1.PAT_ENC_CSN_ID = hap.PAT_ENC_CSN_ID and (hap1.ED_ATTEND_YN = 'N' or hap1.ED_ATTEND_YN is null))
left outer join PATIENT pat on fsch.PAT_ID = pat.PAT_ID
left outer join PATIENT_MYC pmyc on pat.PAT_ID = pmyc.PAT_ID
left outer join CLARITY_DEP cdep on fsch.DEPARTMENT_ID = cdep.DEPARTMENT_ID
left outer join ZC_SEX zcsex on pat.SEX_C = zcsex.RCPT_MEM_SEX_C
left outer join CLARITY_SER cser on hap.PROV_ID = cser.PROV_ID
where
fsch.APPT_DTTM >= EPIC_UTIL.EFN_DIN(sysdate)
and fsch.CONTACT_DATE < EPIC_UTIL.EFN_DIN(sysdate+30)  and
fsch.PRC_ID in (1594,1003)--- RETURN SPECIALTY VISIT
and cdep.DEPARTMENT_ID in (1000103042,1028001074)---MC CC 02 CANCER SURVIVORSHIP & HPMC CC 01 Radiation Oncology 
and fsch.APPT_STATUS_C in (1,6)

AND ACOS.PAT_ID IS NULL --- Exclude ACO patients (Accountable Care Organizations)