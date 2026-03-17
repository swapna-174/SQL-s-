SELECT DISTINCT
    pat.PAT_MRN_ID "MRN"
    , pat.PAT_NAME "Name"
    , FLOOR((pbt.SERVICE_DATE - pat.BIRTH_DATE) / 365.25) "Age at Encounter"
    , pat.BIRTH_DATE "Date of Birth"
    , pbt.SERVICE_DATE "Date of Service"
    , loc.LOC_NAME "Location of Service"
    , pbt.CPT_CODE "CPT Code"
    , dx.PRIMARY_DX_YN "Primary Dx?"
    , edg.CURRENT_ICD10_LIST "ICD10 Code"
    , edg.DX_NAME "Dx Name"
FROM ARPB_TRANSACTIONS pbt
    LEFT OUTER JOIN PATIENT pat ON pbt.PATIENT_ID = pat.PAT_ID
    LEFT OUTER JOIN PAT_ENC_DX dx ON pbt.PAT_ENC_CSN_ID = dx.PAT_ENC_CSN_ID
    LEFT OUTER JOIN CLARITY_EDG edg on dx.DX_ID = edg.DX_ID
    LEFT OUTER JOIN CLARITY_LOC loc ON pbt.LOC_ID = loc.LOC_ID
WHERE
    pbt.SERVICE_DATE >= '01-Jan-2017'
    AND pbt.SERVICE_DATE < '01-Jan-2019'
    AND pbt.VOID_DATE IS NULL
    AND pbt.CPT_CODE = '23515'
ORDER BY
    pbt.SERVICE_DATE
    , pat.PAT_MRN_ID
    

