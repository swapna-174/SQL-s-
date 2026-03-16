SELECT
    vlb.LOG_ID "Log ID"
    , vlb.PROC_DATE "Surgery Date"
    , TRUNC(sysdate)
    , (TRUNC(sysdate) - vlb.PROC_DATE) "Days Since Procedure"
    , pat.PAT_ID "Pat ID"
    , pat.PAT_MRN_ID "MRN"
    , FLOOR((vlb.PROC_DATE - pat.BIRTH_DATE) / 365.25) "Age at Encounter"
    , pat.PAT_NAME "Patient Name"
    , loc2.LOC_NAME "Parent Location"
    , loc.LOC_NAME
    , vlb.SERVICE_NM "Service"
    , zc_cc.NAME "Case Class Name"
    , vlb.ROOM_NM "OR Room"
    , vlb.PRIMARY_PHYSICIAN_NM "Primary Physician"
    , vlb.PRIMARY_PROCEDURE_NM "Primary Procedure"

FROM V_LOG_BASED vlb
    INNER JOIN PATIENT pat ON vlb.PAT_ID = pat.PAT_ID
    LEFT OUTER JOIN ZC_OR_CASE_CLASS zc_cc ON vlb.CASE_CLASS_C = zc_cc.CASE_CLASS_C
    LEFT OUTER JOIN CLARITY_LOC loc ON vlb.LOCATION_ID = loc.LOC_ID
    LEFT OUTER JOIN CLARITY_LOC loc2 ON loc.HOSP_PARENT_LOC_ID = loc2.LOC_ID
    INNER JOIN PAT_OR_ADM_LINK pal ON vlb.LOG_ID = pal.LOG_ID
    INNER JOIN PAT_ENC_HSP peh ON pal.OR_LINK_CSN = peh.PAT_ENC_CSN_ID
    
WHERE 
    vlb.PROC_DATE > '29-FEB-2020'
    AND FLOOR((vlb.PROC_DATE - pat.BIRTH_DATE) / 365.25) >= 18
    AND peh.HOSP_DISCH_TIME IS NULL
