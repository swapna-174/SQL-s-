WITH PAT_POP
AS
(SELECT DISTINCT
    vlb.LOG_ID "Log ID"
    , vlb.CASE_SCHEDULED_START_DTTM "Scheduled Date/Time"
    , vlb.PAT_ID "Pat ID"
    , pat.PAT_MRN_ID "MRN"
    , pat.PAT_MRN_ID || ';' || (TO_CHAR(vlb.CASE_SCHEDULED_START_DTTM, 'mm/dd/yyyy')) "MRN Date"
    , pat.PAT_NAME "Patient Name"
    , vlb.PRIMARY_PROCEDURE_NM "Procedure Name"
    , vlb.PRIMARY_PHYSICIAN_NM  "Primary Surgeon"
    , ser2.PROV_NAME "Assisting Surgeon"
    , olas.SERVICE_C "Service Number"
    , vlb.SERVICE_NM "Service Name"
--    , cev."Outside Hospital Date"
--    , cev."Outside Hospital Procedure"
--    , cev."Outside Hospital Department"
--    , cev."Outside Hospital Name"

FROM V_LOG_BASED vlb
    LEFT OUTER JOIN CLARITY_SER ser ON vlb.PRIMARY_PHYSICIAN_ID = ser.PROV_ID
    LEFT OUTER JOIN OR_LOG_ALL_SURG olas ON vlb.LOG_ID = olas.LOG_ID
        AND olas.ROLE_C = '2'
    LEFT OUTER JOIN CLARITY_SER ser2 ON olas.SURG_ID = ser2.PROV_ID
    LEFT OUTER JOIN PATIENT pat ON vlb.PAT_ID = pat.PAT_ID
    INNER JOIN SMRTDTA_ELEM_DATA sed ON vlb.PAT_ID = sed.PAT_LINK_ID
        AND sed.ELEMENT_ID = 'WH#1111'
    INNER JOIN SMRTDTA_ELEM_VALUE sev ON sed.HLV_ID = sev.HLV_ID

WHERE
    (TRUNC(TO_NUMBER(sev.SMRTDTA_ELEM_VALUE) + TO_DATE('1840-12-31', 'YYYY-MM-DD' )))
        = (TRUNC(vlb.CASE_SCHEDULED_START_DTTM))
)
        
--, CARE_EVERYWHERE
--AS
--(
SELECT
    rcv.PAT_ID
    , det.EVENT_START_DTTM "OSH Surgery Date"
    , det.EVENT_DESC "OSH Procedure Name"
    , det.EVENT_DEPT_NAME "OSH Surgical Department"
    , det.EVENT_SPECIALTY_NAME "OSH Specialty Name"
    , det.EVENT_LOC_NAME "OSH Name"
    , det.*
FROM PAT_POP pp
    INNER JOIN DOCS_RCVD rcv ON pp."Pat ID" = rcv.PAT_ID
    INNER JOIN DOCS_RCVD_ENCOUNTERS det ON rcv.DOCUMENT_ID = det.DOCUMENT_ID
WHERE
    det.EVENT_START_DTTM > pp."Scheduled Date/Time"
    AND det.EVENT_ENC_TYPE_C = 51
    AND det.EVENT_SRC_DXR_CSN IS NOT NULL
)

SELECT *
FROM PAT_POP pp
    LEFT OUTER JOIN CARE_EVERYWHERE cev ON pp."Pat ID" = cev.PAT_ID