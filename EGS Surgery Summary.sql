WITH PAT_POP
AS
(
    SELECT
        pat.PAT_ID
        , pat.PAT_MRN_ID "MRN"
        , vlb.LOG_ID "Log ID"
        , vlb.PROC_DATE "Procedure Date"
        , vlb.PRIMARY_PROCEDURE_NM "Procedure Name"
        , vlb.SERVICE_NM "Service"
        , vlb.PRIMARY_PHYSICIAN_ID "Provider ID"
        , vlb.PRIMARY_PHYSICIAN_NM "Provider Name"
        , dep.DEPARTMENT_ID
        , dep.DEPARTMENT_NAME "Discharge Department"
        , dep.SPECIALTY
        , peh.HOSP_DISCH_TIME "Discharge DateTime"
    FROM V_LOG_BASED vlb
        INNER JOIN PAT_OR_ADM_LINK pal ON vlb.LOG_ID = pal.LOG_ID
        INNER JOIN PAT_ENC_HSP peh ON pal.OR_LINK_CSN = peh.PAT_ENC_CSN_ID
        INNER JOIN CLARITY_DEP dep ON peh.DEPARTMENT_ID = dep.DEPARTMENT_ID
        INNER JOIN PATIENT pat ON vlb.PAT_ID = pat.PAT_ID
    WHERE 
        peh.HOSP_DISCH_TIME >= '25-May-2019'
        AND peh.HOSP_DISCH_TIME < '01-MAR-2020'
        AND peh.DEPARTMENT_ID IN (1000106017, 1000106011)
    --    AND vlb.SERVICE_NM IN ('Emergency General Surgery', 'Gynecology')
--         AND vlb.SERVICE_NM = 'Emergency General Surgery'
         AND vlb.SERVICE_NM IN ('Emergency General Surgery', 'Trauma')
 )
 
 , ER_VISIT
 AS
(
    SELECT
        pp.PAT_ID
        , pp."Procedure Date"
        , pp."Procedure Date" + 30 "Proc Date + 30"        
        , peh.HOSP_ADMSN_TIME
        , 'Yes' AS "ER Visit Within 30 Days"
    FROM PAT_POP pp
        INNER JOIN PAT_ENC_HSP peh ON pp.PAT_ID = peh.PAT_ID
    WHERE 
        peh.ED_EPISODE_ID IS NOT NULL
        AND TRUNC(peh.HOSP_ADMSN_TIME) <= pp."Procedure Date" + 30
        AND TRUNC(peh.HOSP_ADMSN_TIME) > TRUNC(pp."Discharge DateTime")
)

, READMISSION
AS
(
    SELECT
        pp.PAT_ID
        , pp."Procedure Date"
        , pp."Procedure Date" + 30 "Proc Date + 30"        
        , peh.HOSP_ADMSN_TIME
        , 'Yes' AS "Readmission Within 30 Days"
    FROM PAT_POP pp
        INNER JOIN PAT_ENC_HSP peh ON pp.PAT_ID = peh.PAT_ID
        INNER JOIN HSP_ACCOUNT hsp ON peh.HSP_ACCOUNT_ID = hsp.HSP_ACCOUNT_ID
    WHERE 
        peh.ED_EPISODE_ID IS NULL
        AND TRUNC(peh.HOSP_ADMSN_TIME) <= pp."Procedure Date" + 30
        AND TRUNC(peh.HOSP_ADMSN_TIME) > TRUNC(pp."Discharge DateTime")
        AND hsp.ACCT_BASECLS_HA_C = 1
)

, URGENT_CARE
AS
(
    SELECT
        pp.PAT_ID
        , pp."Procedure Date"
        , pp."Procedure Date" + 14 "Proc Date + 14"     
        , enc.CHECKIN_TIME
        , 'Yes' AS "Urgent Care Within 14 Days"
    FROM PAT_POP pp
        INNER JOIN PAT_ENC enc ON pp.PAT_ID = enc.PAT_ID
        INNER JOIN CLARITY_DEP dep ON enc.DEPARTMENT_ID = dep.DEPARTMENT_ID
    WHERE 
        TRUNC(enc.CHECKIN_TIME) <= pp."Procedure Date" + 14
        AND TRUNC(enc.CHECKIN_TIME) > TRUNC(pp."Discharge DateTime")
        AND dep.SPECIALTY = 'Urgent Care'       
)

SELECT DISTINCT
    pp."MRN"
    , pp."Log ID"
    , pp."Procedure Date"
    , pp."Procedure Name"
    , pp."Provider ID"
    , pp."Provider Name"
    , pp."Service"
    , pp."Discharge Department"
    , pp."Discharge DateTime"
    , erv."ER Visit Within 30 Days"
    , rdm."Readmission Within 30 Days"
    , urc."Urgent Care Within 14 Days"
FROM PAT_POP pp
    LEFT OUTER JOIN ER_VISIT erv ON pp.PAT_ID = erv.PAT_ID
        AND pp."Procedure Date" = erv."Procedure Date"
    LEFT OUTER JOIN READMISSION rdm ON pp.PAT_ID = rdm.PAT_ID
        AND pp."Procedure Date" = rdm."Procedure Date"
    LEFT OUTER JOIN URGENT_CARE urc ON pp.PAT_ID = urc.PAT_ID
        AND pp."Procedure Date" = urc."Procedure Date"