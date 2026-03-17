WITH
PAT_POP AS
(
SELECT DISTINCT
    pat.PAT_ID
    , pat.PAT_MRN_ID "MRN"
    , peh.PAT_ENC_CSN_ID  "CSN"
    , peh.INPATIENT_DATA_ID
    , pat.PAT_NAME "Patient Name"
    , FLOOR((peh.HOSP_ADMSN_TIME - pat.BIRTH_DATE) / 365.25) "Age at Admission"
    , eap.PROC_NAME "Procedure Name"
    , eap.PROC_NAME
    , adt.ADT_DEPARTMENT_NAME "Procedure Location"
    , EPIC_UTIL.EFN_UTC_TO_LOCAL(hno.DATE_OF_SERVIC_DTTM)  "Note's Date of Service"
    , adt.IN_DTTM
    , adt.OUT_DTTM
    , hno.NOTE_ID
    , zc_nt.NAME "Note Type"
    , emp.NAME "Author Name"
    , zc_svc.NAME "Author Service"
    , ser.PROV_ID "ProvID"
    , ser.PROV_NAME "ProvName"
    , ser.PROV_TYPE "ProvType"
    , ser2.PROV_ID "CosignID"
    , ser2.PROV_NAME "CosignName"
    , ser2.PROV_TYPE "CosignType"
    , CASE
        WHEN ser.PROV_TYPE = 'Physician' THEN ser.PROV_NAME
        WHEN ser2.PROV_TYPE = 'Physician' THEN ser2.PROV_NAME
        ELSE ser.PROV_NAME
    END AS "Provider Name"
    , CASE
        WHEN ser.PROV_TYPE = 'Physician' THEN ser.PROV_TYPE
        WHEN ser2.PROV_TYPE = 'Physician' THEN ser2.PROV_TYPE
        ELSE ser.PROV_TYPE
    END AS "Provider Type"

FROM PAT_ENC_HSP peh 
    INNER JOIN HSP_ACCOUNT hsp ON peh.PAT_ENC_CSN_ID = hsp.PRIM_ENC_CSN_ID
    LEFT OUTER JOIN PATIENT pat ON peh.PAT_ID = pat.PAT_ID
    LEFT OUTER JOIN HNO_INFO hno ON peh.PAT_ENC_CSN_ID = hno.PAT_ENC_CSN_ID
    LEFT OUTER JOIN ZC_NOTE_TYPE_IP zc_nt ON hno.IP_NOTE_TYPE_C = zc_nt.TYPE_IP_C
    LEFT OUTER JOIN CLARITY_EMP emp ON hno.CURRENT_AUTHOR_ID = emp.USER_ID
    LEFT OUTER JOIN CLARITY_SER ser ON emp.PROV_ID = ser.PROV_ID
    LEFT OUTER JOIN NOTES_PROC_PROCS npp ON hno.NOTE_ID = npp.NOTE_ID
    LEFT OUTER JOIN CLARITY_EAP eap ON npp.PROC_NOTE_PROCEDUR = eap.PROC_ID
    LEFT OUTER JOIN NOTE_ENC_INFO info ON hno.NOTE_ID = info.NOTE_ID
        AND info.NOTE_STATUS_C = 2
    LEFT OUTER JOIN ZC_CLINICAL_SVC zc_svc ON info.AUTHOR_SERVICE_C = zc_svc.CLINICAL_SVC_C
    -- Cosigner
    LEFT OUTER JOIN NOTE_ENC_INFO enc_info ON hno.NOTE_ID = enc_info.NOTE_ID
    LEFT OUTER JOIN CLARITY_EMP emp2 ON enc_info.CSGN_RECPNT_USER_ID = emp2.USER_ID
    LEFT OUTER JOIN CLARITY_SER ser2 ON emp2.PROV_ID = ser2.PROV_ID
    LEFT OUTER JOIN V_PAT_ADT_LOCATION_HX adt ON peh.PAT_ENC_CSN_ID = adt.PAT_ENC_CSN
        AND EPIC_UTIL.EFN_UTC_TO_LOCAL(hno.DATE_OF_SERVIC_DTTM) > adt.IN_DTTM
        AND EPIC_UTIL.EFN_UTC_TO_LOCAL(hno.DATE_OF_SERVIC_DTTM) < adt.OUT_DTTM
    
WHERE
    hsp.ACCT_BASECLS_HA_C = 1
    AND FLOOR((peh.HOSP_ADMSN_TIME - pat.BIRTH_DATE) / 365.25) < 18
    AND hno.IP_NOTE_TYPE_C = 3
    AND hno.CRT_INST_LOCAL_DTTM >= EPIC_UTIL.EFN_DIN('mb-1')
    AND hno.CRT_INST_LOCAL_DTTM <= EPIC_UTIL.EFN_DIN('me-1')    
--    AND TRUNC(EPIC_UTIL.EFN_UTC_TO_LOCAL(hno.DATE_OF_SERVIC_DTTM)) >= '01-JAN-2021'
--    AND TRUNC(EPIC_UTIL.EFN_UTC_TO_LOCAL(hno.DATE_OF_SERVIC_DTTM)) <= '31-JUL-2021'
    AND EPIC_UTIL.EFN_UTC_TO_LOCAL(hno.DATE_OF_SERVIC_DTTM) >= peh.HOSP_ADMSN_TIME
    AND (peh.HOSP_DISCH_TIME IS NULL
        OR EPIC_UTIL.EFN_UTC_TO_LOCAL(hno.DATE_OF_SERVIC_DTTM) <= peh.HOSP_DISCH_TIME)
    AND hno.CURRENT_AUTHOR_ID <> 'EDIDEFAUTH'
--    AND pat.PAT_MRN_ID = '4935631'


ORDER BY 
    pat.PAT_MRN_ID
    , EPIC_UTIL.EFN_UTC_TO_LOCAL(hno.DATE_OF_SERVIC_DTTM)
)

, LINKED_ORDER
AS
(
SELECT
    pp.PAT_ID
    , pp.NOTE_ID
    , pp."Procedure Name"
    , hsl.LINKED_ORDER_ID
    , op.DESCRIPTION
FROM PAT_POP pp
    INNER JOIN HNO_SMARTFORM_LINK hsl ON pp.NOTE_ID = hsl.NOTE_ID
    INNER JOIN ORDER_PROC op ON hsl.LINKED_ORDER_ID = op.ORDER_PROC_ID

)

, ANESTHESIA
AS
(
SELECT
    "CSN"
    , NOTE_ID
    , "Anes Case?"
FROM
    (
    SELECT DISTINCT
        pp."MRN"
        , pp."CSN"
        , pp."Note's Date of Service"
        , pp.NOTE_ID
        , fan.AN_LOG_ID
        , fan.LOG_ID
        , fan.AN_START_DATETIME
        , CASE 
            WHEN fan.AN_START_DATETIME IS NOT NULL
                AND pp."Note's Date of Service" >= fan.AN_START_DATETIME
                AND pp."Note's Date of Service" <= fan.AN_START_DATETIME + 12/24
            THEN fan.AN_LOG_ID
               ELSE NULL
        END AS "Anes Case?"
        , fan.AN_53_ENC_CSN_ID
        , fan.AN_52_ENC_CSN_ID
        , fan.AN_PREOP_NOTE_ID
    FROM PAT_POP pp
        LEFT OUTER JOIN F_AN_RECORD_SUMMARY fan ON pp.PAT_ID = fan.AN_PAT_ID
    WHERE
        pp."Note's Date of Service" <= fan.AN_START_DATETIME + 12/24
        AND pp."Note's Date of Service" >= fan.AN_START_DATETIME        
    )
WHERE
    "Anes Case?" IS NOT NULL
)

SELECT DISTINCT
    pp."Note's Date of Service"
    , pp."MRN"
    , pp."Patient Name"
    , pp."Age at Admission"
    , COALESCE(pp."Procedure Name", lnk.DESCRIPTION) "Procedure Name"
    , ans."Anes Case?"
    , pp."Procedure Location"
    , pp."Note Type"
    , pp."Author Service"
    , pp."Provider Name"
    , pp."Provider Type"
FROM PAT_POP pp
    LEFT OUTER JOIN LINKED_ORDER lnk ON pp.NOTE_ID = lnk.NOTE_ID
    LEFT OUTER JOIN ANESTHESIA ans ON pp."CSN" = ans."CSN"
        AND pp.NOTE_ID = ans.NOTE_ID
    
WHERE
    COALESCE(pp."Procedure Name", lnk.DESCRIPTION) NOT LIKE '%EEG%'
    AND COALESCE(pp."Procedure Name", lnk.DESCRIPTION) <> 'LONG TERM MONITORING'
    
ORDER BY 
    pp."MRN"
    , pp."Note's Date of Service"

