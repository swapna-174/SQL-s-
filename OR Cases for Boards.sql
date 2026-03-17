--SELECT *
--FROM CLARITY_SER ser
--WHERE ser.PROV_NAME LIKE 'WILSON, SCOTT%'
--    AND ser.PROV_TYPE = 'Physician'

WITH
PAT_POP AS

(SELECT
    vs.LOG_ID "Log ID"
    , vs.SCHED_SURGERY_DATETIME "Surgery Date/Time"   
    , peh.PAT_ENC_CSN_ID
    , vs.PAT_ID "Patient ID"
    , vs.PAT_MRN "Patient MRN"
    , pat.PAT_NAME "Patient Name"
    , FLOOR((peh.HOSP_ADMSN_TIME - pat.BIRTH_DATE) / 365.25) "Age at Encounter"
    , zcs.NAME "Gender"
    , vs.PNL_1_PRIM_PROC_NM_WID "Procedure"
    , vs.PNL_1_PRIM_SURG_ID "Provider ID"
    , vs.PNL_1_PRIM_SURG_NM_WID "Provider"
    , vs.PNL_1_PRIM_PROC_ID 
    , vs.PNL_1_PRIM_SURG_PROC_ID
    , hsp.HSP_ACCOUNT_ID
    , edg.REF_BILL_CODE "Primary Diagnosis Code"
    , edg.DX_NAME "Primary Diagnosis Name"
FROM V_SURGERY vs
    LEFT OUTER JOIN PATIENT pat ON vs.PAT_ID = pat.PAT_ID
    LEFT OUTER JOIN PAT_OR_ADM_LINK pal ON vs.LOG_ID = pal.LOG_ID
    LEFT OUTER JOIN PAT_ENC_HSP peh ON pal.OR_LINK_CSN = peh.PAT_ENC_CSN_ID
    LEFT OUTER JOIN HSP_ACCOUNT hsp ON peh.HSP_ACCOUNT_ID = hsp.HSP_ACCOUNT_ID
    LEFT OUTER JOIN HSP_ACCT_DX_LIST dx ON hsp.HSP_ACCOUNT_ID = dx.HSP_ACCOUNT_ID
        AND dx.LINE = 1
    LEFT OUTER JOIN CLARITY_EDG edg ON dx.DX_ID = edg.DX_ID
    LEFT OUTER JOIN ZC_SEX zcs ON pat.SEX_C = zcs.RCPT_MEM_SEX_C
    LEFT OUTER JOIN OR_LOG orl ON vs.LOG_ID = orl.LOG_ID
WHERE  vs.PNL_1_PRIM_SURG_ID = 10588
    AND vs.SCHED_SURGERY_DATETIME >= '01-Jan-2016'
    AND vs.SCHED_SURGERY_DATETIME < '01-Jan-2017'
    AND vs.CASE_SCHED_STATUS_C = 8  -- Completed
),

--
-- Look for Reoperation on same area within 90 days
--
--REOPERATE AS
--(SELECT
--    pp."Log ID"
--    , pp."Patient ID"
--    , vs.SCHED_SURGERY_DATETIME "Reoperation Date/Time"
--    , vs.PNL_1_PRIM_PROC_NM_WID "Reoperation Procedure"
--    , vs.PNL_1_PRIM_SURG_ID "Reoperation Provider ID"
--    , vs.PNL_1_PRIM_SURG_NM_WID "Reoperation Provider"
--FROM PAT_POP pp
--    LEFT OUTER JOIN V_SURGERY vs ON pp."Patient ID" = vs.PAT_ID 
--WHERE vs.SCHED_SURGERY_DATETIME <= TRUNC(pp."Surgery Date/Time") + 90
--    AND pp."Surgery Date/Time" < vs.SCHED_SURGERY_DATETIME
--    AND pp."Log ID" <> vs.LOG_ID
--    
--),

REOPERATE AS
(SELECT *
FROM
    (SELECT
        pp."Log ID"
        , pp."Patient ID"
        , vs.SCHED_SURGERY_DATETIME "Reoperation Date/Time"
        , vs.PNL_1_PRIM_PROC_NM_WID "Reoperation Procedure"
        , vs.PNL_1_PRIM_SURG_ID "Reoperation Provider ID"
        , vs.PNL_1_PRIM_SURG_NM_WID "Reoperation Provider"
        , RANK () OVER (PARTITION BY pp."Log ID" ORDER BY vs.LOG_ID) AS Rank
    FROM PAT_POP pp
        LEFT OUTER JOIN V_SURGERY vs ON pp."Patient ID" = vs.PAT_ID 
    WHERE vs.SCHED_SURGERY_DATETIME <= TRUNC("Surgery Date/Time") + 90
        AND vs.SCHED_SURGERY_DATETIME > TRUNC("Surgery Date/Time")
        AND pp."Log ID" <> vs.LOG_ID
    ORDER BY vs.LOG_ID
    ) 
WHERE Rank = 1
),

----
---- Soft Coded CPT
----
--SC_CPT AS
--(SELECT
--    pp.HSP_ACCOUNT_ID
--    , cpt.CPT_CODE "CPT Code"
--FROM PAT_POP pp
--    INNER JOIN HSP_ACCT_CPT_CODES cpt ON pp.HSP_ACCOUNT_ID = cpt.HSP_ACCOUNT_ID
--)
--
----
---- Hard Coded CPT
----
--HC_CPT AS
--(SELECT
--    pp.HSP_ACCOUNT_ID
--    , tx.CPT_CODE "CPT Code"
--FROM PAT_POP pp
--    INNER JOIN HSP_TRANSACTIONS tx ON pp.HSP_ACCOUNT_ID = tx.HSP_ACCOUNT_ID
--)
 
--
-- CPT Codes
--
CPT_CODES AS
(SELECT
    arpb.PAT_ENC_CSN_ID
    , arpb.CPT_CODE "CPT Code"
FROM PAT_POP pp 
    INNER JOIN ARPB_TRANSACTIONS arpb ON pp.PAT_ENC_CSN_ID = arpb.PAT_ENC_CSN_ID
WHERE arpb.SERV_PROVIDER_ID = '10588'
    AND TRUNC(pp."Surgery Date/Time") = arpb.SERVICE_DATE
)

--CPT_CODES AS
--((SELECT
--    pp.HSP_ACCOUNT_ID "HSP_ACCOUNT_ID"
--    , cpt.CPT_CODE "CPT Code"
--    , 'Soft' AS "Code Type"
--FROM PAT_POP pp
--    INNER JOIN HSP_ACCT_CPT_CODES cpt ON pp.HSP_ACCOUNT_ID = cpt.HSP_ACCOUNT_ID
--WHERE cpt.CPT_PERF_PROV_ID = '10588'
--)
--
--UNION
--
--(SELECT
--    pp.HSP_ACCOUNT_ID "HSP_ACCOUNT_ID"
--    , tx.CPT_CODE "CPT Code"
--    , 'Hard' AS "Code Type"
--FROM PAT_POP pp
--    INNER JOIN HSP_TRANSACTIONS tx ON pp.HSP_ACCOUNT_ID = tx.HSP_ACCOUNT_ID
--WHERE tx.PERFORMING_PROV_ID = '10588'
--))



SELECT DISTINCT
    pp."Log ID"
    , pp."Surgery Date/Time"
    , pp.HSP_ACCOUNT_ID
--    , pp."Patient ID"
    , pp."Patient MRN"
    , pp."Patient Name"
    , pp."Age at Encounter"
    , pp."Gender"
    , pp."Procedure"
    , pp."Provider ID"
    , pp."Provider"
    , pp."Primary Diagnosis Code"
    , pp."Primary Diagnosis Name"
    , cpt."CPT Code"
--    , CASE WHEN rdt."Log ID" IS NOT NULL THEN 'YES' ELSE 'NO' END AS "30 Day Readmission?"
    , CASE WHEN rpr."Log ID" IS NOT NULL THEN 'YES' ELSE 'NO' END AS "90 Day Reoperation?"
    , rpr."Reoperation Date/Time"
    , rpr."Reoperation Procedure"
    , rpr."Reoperation Provider ID"
    , rpr."Reoperation Provider"

--    , cpt."Code Type"
    
FROM PAT_POP pp
    LEFT OUTER JOIN REOPERATE rpr ON pp."Log ID" = rpr."Log ID"
--    LEFT OUTER JOIN CPT_CODES cpt ON pp.HSP_ACCOUNT_ID = cpt."HSP_ACCOUNT_ID"
    LEFT OUTER JOIN CPT_CODES cpt ON pp.PAT_ENC_CSN_ID = cpt.PAT_ENC_CSN_ID
ORDER BY 
    pp."Patient Name"
    , pp."Surgery Date/Time"  