WITH PAC_APPTS
AS
(
    SELECT DISTINCT
        pat.PAT_MRN_ID "MRN"
        , pat.PAT_ID "Pat ID"
        , pat.PAT_NAME "Patient Name"
        , enc.HSP_ACCOUNT_ID "PAC HAR"
        , TRUNC(enc.APPT_TIME) "PAC Appt Date"
        , enc.DEPARTMENT_ID
        , dep.DEPARTMENT_NAME "Department Name"
        , enc.PAT_ENC_CSN_ID "CSN"
        , CASE
            WHEN enc.PAT_ENC_CSN_ID = enc.APPT_SERIAL_NO THEN ocap.OR_CASE_ID
            WHEN enc.PAT_ENC_CSN_ID <> enc.APPT_SERIAL_NO THEN ocap2.OR_CASE_ID
        END AS "Log ID"
        
    FROM PAT_ENC enc
        INNER JOIN PATIENT pat ON enc.PAT_ID = pat.PAT_ID
        INNER JOIN CLARITY_SER ser ON enc.VISIT_PROV_ID = ser.PROV_ID
        INNER JOIN CLARITY_DEP dep ON enc.DEPARTMENT_ID = dep.DEPARTMENT_ID
        LEFT OUTER JOIN OR_CASE_APPTS_PR ocap ON enc.PAT_ENC_CSN_ID = ocap.ASN
        LEFT OUTER JOIN OR_CASE_APPTS_PR ocap2 ON enc.APPT_SERIAL_NO = ocap2.ASN

    WHERE
        enc.APPT_TIME IS NOT NULL 
        AND enc.DEPARTMENT_ID = '1000106010'
        AND enc.APPT_STATUS_C IN (2,6)  --  2 = Completed, 6 = Arrived
        AND TRUNC(enc.APPT_TIME) >= '01-APR-2021'
        AND TRUNC(enc.APPT_TIME) <= '31-MAY-2021'
--        AND pat.PAT_MRN_ID = '3370431'
--        AND pat.PAT_MRN_ID IN ('1640693', '1745434', '948292', '4502844', '160720', '4465517', '939986')
)

, LOG_FROM_HAR
AS
(
SELECT DISTINCT
    pac."MRN"
    , pac."Pat ID"
    , pac."Patient Name"
    , pac."PAC HAR"
    , pac."PAC Appt Date"
    , pac."Department Name"
--    , pac."CSN"
--    , enc.PAT_ENC_CSN_ID
--    , pac."Log ID"
--    , orc.OR_CASE_ID
    , CASE
        WHEN pac."Log ID" IS NOT NULL THEN pac."Log ID"
        WHEN pac."Log ID" IS NULL AND orc.OR_CASE_ID IS NOT NULL THEN orc.OR_CASE_ID 
        WHEN pac."Log ID" IS NULL AND orc.OR_CASE_ID IS NULL THEN NULL
    END AS "Log ID"
                
FROM PAC_APPTS pac
    LEFT OUTER JOIN PAT_ENC enc ON pac."PAC HAR" = enc.HSP_ACCOUNT_ID
    LEFT OUTER JOIN PAT_OR_ADM_LINK lnk ON enc.PAT_ENC_CSN_ID = lnk.OR_LINK_CSN
    LEFT OUTER JOIN OR_CASE orc ON lnk.CASE_ID = orc.OR_CASE_ID
)

, SURGICAL_LOG
AS
(
SELECT
    orc.OR_CASE_ID "Log ID"
    , lfh."PAC HAR"
    , orc.SCHED_STATUS_C
    , zc_ss.NAME "Scheduling Status"
    , lfh."PAC Appt Date"
    , CASE
        WHEN orl.SURGERY_DATE IS NOT NULL THEN orl.SURGERY_DATE ELSE orc.SURGERY_DATE
    END AS "Original Surgery Date"
    , ((CASE WHEN orl.SURGERY_DATE IS NOT NULL THEN orl.SURGERY_DATE ELSE orc.SURGERY_DATE END) - lfh."PAC Appt Date") AS "Days BT PAC and Surgery"
    , orc.PREOP_VISIT_YN
    , orc.SERVICE_C
    , CASE WHEN orl.LOC_ID IS NOT NULL THEN loc2.LOC_NAME ELSE loc.LOC_NAME END AS "Surgery Location"
    , CASE WHEN ser.PROV_NAME IS NOT NULL THEN ser.PROV_NAME ELSE ser3.PROV_NAME END AS "Room"
    , zc_or.NAME "Service"
    , CASE
        WHEN orc.SCHED_STATUS_C = 2 THEN orc.CANCEL_DATE ELSE NULL
    END AS "Surgery Cancel Date"
    , enc.HSP_ACCOUNT_ID "Surgery HAR"
    , orc2.OR_CASE_ID "Rescheduled Surgery Log ID"
    , enc2.HSP_ACCOUNT_ID "Rescheduled Surgery HAR"
    , CASE
        WHEN orl2.SURGERY_DATE IS NOT NULL THEN orl2.SURGERY_DATE ELSE orc2.SURGERY_DATE
    END AS "Rescheduled Surgery Date"
    , orc2.LOC_ID 
    , loc3.LOC_NAME "Rescheduled Surgery Location"
    , ser2.PROV_NAME "Rescheduled Surgery Room"
    , CASE
        WHEN orc2.LOC_ID IS NOT NULL AND orc.LOC_ID = orc2.LOC_ID THEN 'Yes' 
        WHEN orc2.LOC_ID IS NOT NULL AND orc.LOC_ID <> orc2.LOC_ID THEN 'No'
    END AS "Same Location?"
--    , CASE
--        WHEN orc2.LOC_ID IS NOT NULL THEN '1'
--        WHEN orc.LOC_ID = orc2.LOC_ID THEN 'Yes' ELSE 'No'
--    END AS "Same Location?"
    , ((CASE WHEN orl2.SURGERY_DATE IS NOT NULL THEN orl2.SURGERY_DATE ELSE orc2.SURGERY_DATE END) - lfh."PAC Appt Date") 
        AS "Days BT PAC and Resched Surg"

FROM LOG_FROM_HAR lfh
    INNER JOIN OR_CASE orc ON lfh."Log ID" = orc.OR_CASE_ID
    LEFT OUTER JOIN CLARITY_SER ser3 ON orc.OR_ID = ser3.PROV_ID
    LEFT OUTER JOIN CLARITY_LOC loc ON orc.LOC_ID = loc.LOC_ID
    INNER JOIN ZC_OR_SCHED_STATUS zc_ss ON orc.SCHED_STATUS_C = zc_ss.SCHED_STATUS_C
    LEFT OUTER JOIN ZC_OR_SERVICE zc_or ON orc.SERVICE_C = zc_or.SERVICE_C
    LEFT OUTER JOIN OR_LOG orl ON lfh."Log ID" = orl.LOG_ID
    LEFT OUTER JOIN CLARITY_LOC loc2 ON orl.LOC_ID = loc2.LOC_ID
    LEFT OUTER JOIN PAT_OR_ADM_LINK lnk ON orc.OR_CASE_ID = lnk.LOG_ID
    LEFT OUTER JOIN PAT_ENC enc ON lnk.OR_LINK_CSN = enc.PAT_ENC_CSN_ID
    LEFT OUTER JOIN CLARITY_SER ser ON orl.ROOM_ID = ser.PROV_ID
    LEFT OUTER JOIN OR_CASE_2 orc_2 ON orc.OR_CASE_ID = orc_2.CASE_ID_COPIED_FROM
    LEFT OUTER JOIN OR_CASE orc2 ON orc_2.CASE_ID = orc2.OR_CASE_ID
    LEFT OUTER JOIN CLARITY_SER ser2 ON orc2.OR_ID = ser2.PROV_ID
    LEFT OUTER JOIN CLARITY_LOC loc3 ON orc2.LOC_ID = loc3.LOC_ID
    LEFT OUTER JOIN PAT_OR_ADM_LINK lnk2 ON orc2.OR_CASE_ID = lnk2.LOG_ID
    LEFT OUTER JOIN PAT_ENC enc2 ON lnk2.OR_LINK_CSN = enc2.PAT_ENC_CSN_ID
    LEFT OUTER JOIN OR_LOG orl2 ON orc2.OR_CASE_ID = orl2.LOG_ID
    
)

, ISSUES
AS
(
SELECT *
FROM
(
SELECT DISTINCT
    CASE
        WHEN srg."Scheduling Status" = 'Completed' AND srg."Days BT PAC and Surgery" > 31 THEN 'PAC Completed, Surgery COMPLETED > 31 Days After PAC'
        WHEN srg."Scheduling Status" = 'Scheduled' AND srg."Days BT PAC and Surgery" > 31 THEN 'PAC Completed, Surgery SCHEDULED > 31 Days After PAC'
        WHEN srg."Scheduling Status" = 'Not Scheduled' AND srg."Days BT PAC and Surgery" > 31 THEN 'PAC Completed, Surgery NOT SCHEDULED > 31 Days After PAC'
        WHEN srg."Scheduling Status" = 'Canceled' THEN 'PAC Completed, Surgery CANCELLED' 
        WHEN srg."Scheduling Status" = 'Voided' THEN 'PAC Completed, Surgery VOIDED' 
        WHEN srg."Scheduling Status" IS NULL THEN 'PAC Completed, No Linked Surgery Found'         
        ELSE ''
    END AS "Issue With PAC Visit"
    , lfh."Pat ID"
    , lfh."MRN"
    , lfh."PAC HAR"
    , lfh."Patient Name"
    , lfh."PAC Appt Date"
    , lfh."Department Name"
    , srg."Log ID"
    , srg."Surgery HAR"
    , srg."Service"
    , srg."Surgery Location"
    , srg."Room"
    , srg."Scheduling Status"
    , srg."Original Surgery Date"
    , srg."Days BT PAC and Surgery"
    , srg."Surgery Cancel Date"
    , srg."Rescheduled Surgery Log ID"
    , srg."Rescheduled Surgery HAR"
    , srg."Rescheduled Surgery Date"
    , srg."Rescheduled Surgery Location"
    , srg."Rescheduled Surgery Room"
    , srg."Same Location?"
    , srg."Days BT PAC and Resched Surg"
FROM LOG_FROM_HAR lfh
    LEFT OUTER JOIN SURGICAL_LOG srg ON lfh."PAC HAR" = srg."PAC HAR"
)
WHERE
    "Issue With PAC Visit" IS NOT NULL
)

--, UNLINKED_PROCEDURE
--AS
--(
SELECT
    iss.*
    
FROM ISSUES iss

WHERE iss."Issue With PAC Visit" = 'PAC Completed, No Linked Surgery Found' 

--)
