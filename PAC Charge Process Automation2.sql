WITH PAC_APPTS
AS
(
    SELECT
        pat.PAT_MRN_ID "MRN"
        , pat.PAT_ID "Pat ID"
        , pat.PAT_NAME "Patient Name"
        , enc.HSP_ACCOUNT_ID "HAR"
        , TRUNC(enc.APPT_TIME) "PAC Appt Date"
        , dep.DEPARTMENT_NAME "Department Name"
        
    FROM PAT_ENC enc
        INNER JOIN PATIENT pat ON enc.PAT_ID = pat.PAT_ID
        INNER JOIN CLARITY_SER ser ON enc.VISIT_PROV_ID = ser.PROV_ID
        INNER JOIN CLARITY_DEP dep ON enc.DEPARTMENT_ID = dep.DEPARTMENT_ID
        
    WHERE
        enc.APPT_TIME IS NOT NULL 
        AND enc.DEPARTMENT_ID IN ('1000106010 ','1008301044','1012301018', '1024301059')
        AND enc.APPT_STATUS_C IN (2,6)  --  2 = Completed, 6 = Arrived
        AND TRUNC(enc.APPT_TIME) >= '01-JAN-2021'
        AND TRUNC(enc.APPT_TIME) <= '28-FEB-2021'
        AND pat.PAT_MRN_ID = '4821210'
        
    ORDER BY
        enc.APPT_TIME
)

, SURGICAL_LOG
AS
(
SELECT
    orc.OR_CASE_ID "Log ID"
    , pac."HAR"
    , orc.SCHED_STATUS_C
    , zc_ss.NAME "Scheduling Status"
    , pac."PAC Appt Date"
    , orc.SURGERY_DATE "Surgery Date"
    , (orc.SURGERY_DATE - pac."PAC Appt Date") AS "Days BT PAC and Surgery"
    , orc.PREOP_VISIT_YN
    , orc.SERVICE_C
    , zc_or.NAME "Service"

FROM OR_CASE orc
    INNER JOIN PAT_OR_ADM_LINK lnk ON orc.OR_CASE_ID = lnk.LOG_ID
    INNER JOIN PAT_ENC enc ON lnk.OR_LINK_CSN = enc.PAT_ENC_CSN_ID
    INNER JOIN ZC_OR_SCHED_STATUS zc_ss ON orc.SCHED_STATUS_C = zc_ss.SCHED_STATUS_C
    LEFT OUTER JOIN ZC_OR_SERVICE zc_or ON orc.SERVICE_C = zc_or.SERVICE_C
    INNER JOIN PAC_APPTS pac ON enc.HSP_ACCOUNT_ID = pac."HAR"
)

, UNLINKED_SURGICAL_LOG
AS
(
SELECT
    orc.OR_CASE_ID "Log ID"
    , pac."HAR"
    , orc.SCHED_STATUS_C
    , zc_ss.NAME "Scheduling Status"
    , pac."PAC Appt Date"
    , orc.SURGERY_DATE "Surgery Date"
    , (orc.SURGERY_DATE - pac."PAC Appt Date") AS "Days BT PAC and Surgery"
    , orc.PREOP_VISIT_YN
    , orc.SERVICE_C
    , zc_or.NAME "Service"

FROM OR_CASE orc
    INNER JOIN PAT_OR_ADM_LINK lnk ON orc.OR_CASE_ID = lnk.LOG_ID
    INNER JOIN PAT_ENC enc ON lnk.OR_LINK_CSN = enc.PAT_ENC_CSN_ID
    INNER JOIN ZC_OR_SCHED_STATUS zc_ss ON orc.SCHED_STATUS_C = zc_ss.SCHED_STATUS_C
    LEFT OUTER JOIN ZC_OR_SERVICE zc_or ON orc.SERVICE_C = zc_or.SERVICE_C
    INNER JOIN PAC_APPTS pac ON enc.PAT_ID = pac."Pat ID"
    
WHERE
    pac."PAC Appt Date" >= '01-JAN-2021'
    AND pac."PAC Appt Date" <= '28-FEB-2021'
    AND pac."PAC Appt Date" >= orc.SURGERY_DATE - 60
    AND pac."PAC Appt Date" <= orc.SURGERY_DATE
    AND 
    NOT EXISTS
        (SELECT
            srg."Log ID"
        FROM SURGICAL_LOG srg
        WHERE srg."Log ID" = orc.LOG_ID    
        )
)


SELECT
    CASE
        WHEN srg."Scheduling Status" = 'Completed' AND srg."Days BT PAC and Surgery" > 31 THEN 'PAC Completed, Surgery OCCURED > 31 Days Afterward'
        WHEN srg."Scheduling Status" = 'Scheduled' AND srg."Days BT PAC and Surgery" > 31 THEN 'PAC Completed, Surgery SCHEDULED > 31 Days Afterward'
        WHEN srg."Scheduling Status" = 'Canceled' THEN 'PAC Completed, Surgery CANCELLED' 
        WHEN srg."Scheduling Status" = 'Voided' THEN 'PAC Completed, Surgery VOIDED' 
        WHEN srg."Scheduling Status" = NULL THEN 'PAC Completed, Surgery VOIDED' 
        
        ELSE ''
    END AS "Issue With PAC Visit"
    , pac."MRN"
    , pac."Patient Name"
    , pac."HAR"
    , pac."PAC Appt Date"
    , pac."Department Name"
    , srg."Service"
    , srg."Log ID"
    , srg."Scheduling Status"
    , srg."PAC Appt Date"
    , srg."Surgery Date"
    , srg."Days BT PAC and Surgery"
FROM PAC_APPTS pac
    INNER JOIN SURGICAL_LOG srg ON pac."HAR" = srg."HAR"
    
UNION ALL

SELECT
    CASE
        WHEN usl."Scheduling Status" = 'Completed' AND usl."Days BT PAC and Surgery" > 31 THEN 'PAC Completed, Surgery OCCURED > 31 Days Afterward'
        WHEN usl."Scheduling Status" = 'Scheduled' AND usl."Days BT PAC and Surgery" > 31 THEN 'PAC Completed, Surgery SCHEDULED > 31 Days Afterward'
        WHEN usl."Scheduling Status" = 'Canceled' THEN 'PAC Completed, Surgery CANCELLED' 
        WHEN usl."Scheduling Status" = 'Voided' THEN 'PAC Completed, Surgery VOIDED' 
        WHEN usl."Scheduling Status" = NULL THEN 'PAC Completed, Surgery VOIDED' 
        
        ELSE ''
    END AS "Issue With PAC Visit"
    , pac."MRN"
    , pac."Patient Name"
    , pac."HAR"
    , pac."PAC Appt Date"
    , pac."Department Name"
    , usl."Service"
    , usl."Log ID"
    , usl."Scheduling Status"
    , usl."PAC Appt Date"
    , usl."Surgery Date"
    , usl."Days BT PAC and Surgery"
FROM PAC_APPTS pac
    INNER JOIN UNLINKED_SURGICAL_LOG usl ON pac."HAR" = usl."HAR"