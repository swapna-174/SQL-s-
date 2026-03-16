WITH
PAT_POP AS
(
SELECT
    INDEX_CASE.*
    , CASE
        WHEN "Previous Surgeon" IS NOT NULL AND "Primary Surgeon" <> "Previous Surgeon" THEN 'Yes'
            ELSE 'No'
    END AS "Change in Surgeon?"
    , CASE
        WHEN "Previous Procedure" IS NOT NULL AND "Procedure Name" <> "Previous Procedure" THEN 'Yes'
            ELSE 'No'
    END AS "Change in Procedure?"
    , CASE
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 0 AND 8 THEN '6 Mo'
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 8.1 AND 15 THEN '1 Yr'
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 15.1 AND 28 THEN '2 Yr'
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 28.1 AND 40 THEN '3 Yr'
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 40.1 AND 52 THEN '4 Yr'
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 52.1 AND 65.9 THEN '5 Yr'
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 66 AND 77.9 THEN '6 Yr'
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 78 AND 89.9 THEN '7 Yr'
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 90 AND 101.9 THEN '8 Yr'
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 102 AND 113.9 THEN '9 Yr'
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 114 AND 125.9 THEN '10 Yr'
    END AS "Next Follow-up Period"      
    , CASE
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 0 AND 8 THEN 0
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 8.1 AND 15 THEN 8.1
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 15.1 AND 28 THEN 15.1
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 28.1 AND 40 THEN 28.1
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 40.1 AND 52 THEN 40.1        
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 52.1 AND 65.9 THEN 52.1
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 66 AND 77.9 THEN 66
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 78 AND 89.9 THEN 78
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 90 AND 101.9 THEN 90
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 102 AND 113.9 THEN 102
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 114 AND 125.9 THEN 114
    END AS "Next Follow-up Period Low"   
    , CASE
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 0 AND 8 THEN 8
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 8.1 AND 15 THEN 15
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 15.1 AND 28 THEN 28
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 28.1 AND 40 THEN 40
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 40.1 AND 52 THEN 52      
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 52.1 AND 65.9 THEN 65.9
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 66 AND 77.9 THEN 77.9
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 78 AND 89.9 THEN 89.9
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 90 AND 101.9 THEN 101.9
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 102 AND 113.9 THEN 113.9
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 114 AND 125.9 THEN 125.9
    END AS "Next Follow-up Period High"   
    , CASE
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 0 AND 8 THEN ADD_MONTHS("Index Case Date", 6)
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 8.1 AND 15 THEN ADD_MONTHS("Index Case Date", 12)
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 15.1 AND 28 THEN ADD_MONTHS("Index Case Date", 24)
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 28.1 AND 40 THEN ADD_MONTHS("Index Case Date", 36)
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 40.1 AND 52 THEN ADD_MONTHS("Index Case Date", 48)        
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 52.1 AND 65.9 THEN ADD_MONTHS("Index Case Date", 60)
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 66 AND 77.9 THEN ADD_MONTHS("Index Case Date", 72)
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 78 AND 89.9 THEN ADD_MONTHS("Index Case Date", 84)
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 90 AND 101.9  THEN ADD_MONTHS("Index Case Date", 96)
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 102 AND 113.9 THEN ADD_MONTHS("Index Case Date", 108)
        WHEN ROUND(MONTHS_BETWEEN (sysdate, "Index Case Date"), 1) BETWEEN 114 AND 125.9 THEN ADD_MONTHS("Index Case Date", 120)
    END AS "Due Date"   
FROM
    (   
    SELECT 
        CHANGE.*
        , CASE
            WHEN "Index Case?" = 'Yes' THEN "Scheduled Date/Time"
            WHEN LAG ("Index Case?", 1) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time") = 'Yes' 
                THEN LAG("Scheduled Date/Time",1) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time")
            WHEN LAG ("Index Case?", 2) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time") = 'Yes'
                THEN LAG("Scheduled Date/Time",2) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time")
            WHEN LAG ("Index Case?", 3) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time") = 'Yes'
                THEN LAG("Scheduled Date/Time",3) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time")
            WHEN LAG ("Index Case?", 4) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time") = 'Yes'
                THEN LAG("Scheduled Date/Time",4) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time")
            WHEN LAG ("Index Case?", 5) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time") = 'Yes'
                    THEN LAG("Scheduled Date/Time",5) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time")
        END AS "Index Case Date"
        , CASE
            WHEN "Index Case?" = 'Yes' THEN "Primary Surgeon"
            WHEN LAG ("Index Case?", 1) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time") = 'Yes' 
                THEN LAG("Primary Surgeon",1) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time")
            WHEN LAG ("Index Case?", 2) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time") = 'Yes'
                THEN LAG("Primary Surgeon",2) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time")
            WHEN LAG ("Index Case?", 3) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time") = 'Yes'
                THEN LAG("Primary Surgeon",3) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time")
            WHEN LAG ("Index Case?", 4) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time") = 'Yes'
                THEN LAG("Primary Surgeon",4) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time")
            WHEN LAG ("Index Case?", 5) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time") = 'Yes'
                    THEN LAG("Primary Surgeon",5) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time")
        END AS "Index Case Surgeon"
        , CASE
            WHEN "Index Case?" = 'Yes' THEN "Procedure Name"
            WHEN LAG ("Index Case?", 1) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time") = 'Yes' 
                THEN LAG("Procedure Name",1) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time")
            WHEN LAG ("Index Case?", 2) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time") = 'Yes'
                THEN LAG("Procedure Name",2) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time")
            WHEN LAG ("Index Case?", 3) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time") = 'Yes'
                THEN LAG("Procedure Name",3) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time")
            WHEN LAG ("Index Case?", 4) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time") = 'Yes'
                THEN LAG("Procedure Name",4) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time")
            WHEN LAG ("Index Case?", 5) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time") = 'Yes'
                    THEN LAG("Procedure Name",5) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time")
        END AS "Index Case Procedure"
    FROM
        (
        SELECT DISTINCT
            "Log ID"
            , "Scheduled Date/Time"
            , "Pat ID"
            , "MRN"
    --        , "MRN Date"
            , "Patient Name"
            , "Death Date"
            , "Procedure Name"
            , "Primary Surgeon"
            , "Assisting Surgeon"
    --        , "Service Number"
    --        , "Service Name"    
            , case_order
            , CASE
                WHEN case_order = 1 THEN 'Yes' ELSE 'No'
            END AS "Index Case?"
            , LAG ("Primary Surgeon", 1) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time") "Previous Surgeon"
            , LAG ("Procedure Name", 1) OVER (PARTITION BY "Pat ID" ORDER BY "Scheduled Date/Time") "Previous Procedure"
        FROM
            (
            SELECT DISTINCT
                vlb.LOG_ID "Log ID"
                , vlb.CASE_SCHEDULED_START_DTTM "Scheduled Date/Time"
                , vlb.PAT_ID "Pat ID"
                , pat.PAT_MRN_ID "MRN"
                , pat.PAT_MRN_ID || ';' || (TO_CHAR(vlb.CASE_SCHEDULED_START_DTTM, 'mm/dd/yyyy')) "MRN Date"
                , pat.PAT_NAME "Patient Name"
                , pat.DEATH_DATE "Death Date"
                , vlb.PRIMARY_PROCEDURE_NM "Procedure Name"
                , vlb.PRIMARY_PHYSICIAN_NM  "Primary Surgeon"
                , ser2.PROV_NAME "Assisting Surgeon"
                , olas.SERVICE_C "Service Number"
                , vlb.SERVICE_NM "Service Name"
                , RANK() OVER ( PARTITION BY vlb.PAT_ID ORDER BY vlb.PAT_ID, vlb.CASE_SCHEDULED_START_DTTM) case_order
        
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
    --            AND pat.PAT_MRN_ID IN ('580621', '3491222', '13743780', '3454705', '3540950', '1073552', '499820')
    --            AND pat.PAT_MRN_ID IN ('25776', '153837', '261394', '399812')
    --            AND pat.PAT_MRN_ID IN ('1001480', '1010970')
    --            AND vlb.LOG_ID = 406250
        --        AND pat.PAT_MRN_ID  = '1073552'
            ORDER BY
                vlb.PAT_ID
                , vlb.CASE_SCHEDULED_START_DTTM
            )
        ) CHANGE
    ) INDEX_CASE
) 
   
SELECT DISTINCT
    pp."Pat ID"
    , pp."MRN"
    , pp."Patient Name"
    , det.EVENT_START_DTTM "OSH Surgery Date"
    , det.EVENT_DESC "OSH Procedure Name"
    , det.EVENT_DEPT_NAME "OSH Surgical Department"
    , det.EVENT_SPECIALTY_NAME "OSH Specialty Name"
    , det.EVENT_LOC_NAME "OSH Name"
    , CASE 
        WHEN det.DOCUMENT_ID IS NOT NULL THEN 'Yes' ELSE 'No'
    END AS  "Outside Hospital Surgery?"
FROM PAT_POP pp
    INNER JOIN DOCS_RCVD rcv ON pp."Pat ID" = rcv.PAT_ID
    INNER JOIN DOCS_RCVD_ENCOUNTERS det ON rcv.DOCUMENT_ID = det.DOCUMENT_ID
WHERE
    det.EVENT_START_DTTM > pp."Scheduled Date/Time"
    AND det.EVENT_ENC_TYPE_C = 51
    AND det.EVENT_SRC_DXR_CSN IS NOT NULL
