WITH PAT_POP
AS
(SELECT 
    vlb.LOG_ID "Log ID"
    , vlb.PAT_ID "Pat ID"
--    , peh.PAT_ENC_CSN_ID "CSN"
    , fans.AN_53_ENC_CSN_ID "CSN"
    , vlb.PRIMARY_PHYSICIAN_NM "Surgeon Name"
--    , loc2.LOC_ID
    , loc2.LOC_NAME "Parent Location"
    , vlb.SERVICE_NM "Service"
    , vlb.LOCATION_NM "Location"
    , vlb.ROOM_NM "Room"
    , vlb.PROC_DATE "Procedure Date"
    , zc_pat.NAME "Patient Class"
    , zc_cc.NAME "Case Class"
    , vlb.PRIMARY_PROCEDURE_NM "Procedure Name"
    , pat.PAT_MRN_ID "Patient MRN"
    , FLOOR((vlb.PROC_DATE - pat.BIRTH_DATE) / 365.25) "Age at Encounter"
    , pat.CITY "Patient City"
    , zc_st.NAME "Patient State"
    , pat.ZIP "Patient Zipcode"

FROM V_LOG_BASED vlb
    INNER JOIN PATIENT pat ON pat.PAT_ID = vlb.PAT_ID
    INNER JOIN ZC_OR_CASE_CLASS zc_cc ON vlb.CASE_CLASS_C = zc_cc.CASE_CLASS_C
    LEFT OUTER JOIN ZC_PAT_CLASS zc_pat ON vlb.PATIENT_CLASS_C = zc_pat.ADT_PAT_CLASS_C
    LEFT OUTER JOIN CLARITY_LOC loc ON vlb.LOCATION_ID = loc.LOC_ID
    LEFT OUTER JOIN CLARITY_LOC loc2 ON loc.HOSP_PARENT_LOC_ID = loc2.LOC_ID
    LEFT OUTER JOIN ZC_STATE zc_st ON pat.STATE_C = zc_st.STATE_C
--    INNER JOIN PAT_OR_ADM_LINK pal ON vlb.LOG_ID = pal.LOG_ID
--    INNER JOIN PAT_ENC_HSP peh ON pal.OR_LINK_CSN = peh.PAT_ENC_CSN_ID
    LEFT OUTER JOIN F_AN_RECORD_SUMMARY fans ON vlb.LOG_ID = fans.LOG_ID
WHERE 
    vlb.LOG_STATUS_C IN (2,5)
--                    AND TRUNC(vlb.PROC_DATE) >= EPIC_UTIL.EFN_DIN('{?StartDate}')
--                    AND TRUNC(vlb.PROC_DATE) <= EPIC_UTIL.EFN_DIN('{?EndDate}')
    AND TRUNC(vlb.PROC_DATE) >= '01-JUL-2020'
--    AND TRUNC(vlb.PROC_DATE) <= '30-JUN-2020'
--    AND TRUNC(vlb.PROC_DATE) >= EPIC_UTIL.EFN_DIN('mb-1')
--    AND TRUNC(vlb.PROC_DATE) <= EPIC_UTIL.EFN_DIN('me-1')
    AND loc2.LOC_ID IN (100000, 100002)
    AND vlb.CASE_CLASS_C IN (10, 60, 110)
)
    
, SNC_CALL
AS
(
SELECT *
FROM 
    (
    SELECT *
    FROM
            (
            SELECT
                pp."Log ID"
--                , meas.FSD_ID "Flowsheet Record"
                , meas.FLO_MEAS_ID "Measure ID"
--                , meas.RECORDED_TIME "Recorded DateTime"
--                , dat.FLO_MEAS_NAME "Flowsheet Name"
                , meas.MEAS_VALUE "Measure Value"
                , RANK() OVER ( PARTITION BY pp."Log ID", meas.FLO_MEAS_ID
                    ORDER BY meas.RECORDED_TIME DESC) rank
            FROM PAT_POP pp
                INNER JOIN PAT_OR_ADM_LINK pal ON pp."Log ID" = pal.LOG_ID
                INNER JOIN IP_FLWSHT_REC rec ON pal.OR_LINK_INP_ID = rec.INPATIENT_DATA_ID
                INNER JOIN IP_FLWSHT_MEAS meas ON rec.FSD_ID = meas.FSD_ID
                INNER JOIN IP_FLO_GP_DATA dat ON meas.FLO_MEAS_ID = dat.FLO_MEAS_ID
            WHERE 
                meas.FLO_MEAS_ID IN ('9270', '8985')
            ORDER BY
                RECORD_DATE DESC
            )
    WHERE rank = 1
    )
    PIVOT 
          (LISTAGG ("Measure Value") WITHIN GROUP (ORDER BY "Measure ID") FOR  "Measure ID" IN 
                            ('9270' AS "SNC Call Completed"
                            ,'8985' AS "Navigator Reached Patient")
          )
)

--
-- Was a PAC appt completed prior to surgery?
--
, PAC_VISIT
AS
(
SELECT *
FROM
    (
    SELECT
        orl.LOG_ID
        , enc2.CONTACT_DATE
    FROM OR_CASE orc
        INNER JOIN PAT_OR_ADM_LINK lnk ON orc.LOG_ID = lnk.LOG_ID
        INNER JOIN PAT_ENC enc ON lnk.OR_LINK_CSN = enc.PAT_ENC_CSN_ID
        INNER JOIN PAT_ENC enc2 ON enc.HSP_ACCOUNT_ID = enc2.HSP_ACCOUNT_ID
            AND enc2.DEPARTMENT_ID IN ('1000106010 ','1012301018')
            AND enc2.APPT_STATUS_C <> 3 --Not a cancelled visit ---PAC visit
        INNER JOIN OR_LOG orl ON orc.LOG_ID = orl.LOG_ID
            AND orl.OR_TIME_EVTS_ENT_C = 2  -- surgery completed
        INNER JOIN PAT_POP pp ON pp."Log ID" = orl.LOG_ID
    WHERE
        enc2.APPT_TIME IS NOT NULL 
        AND orc.RECORD_CREATE_DATE <= enc2.APPT_TIME
        AND pp."Log ID" = orl.LOG_ID
    ORDER BY
        enc2.CONTACT_DATE DESC
    )
)
             
--
-- Was a PAC appt completed prior to surgery (PAC appointment not linked to the surgery)?
--
, UNLINKED_PAC_VISIT
AS
(
SELECT *
FROM
    (SELECT DISTINCT
        pp."Log ID"
        , enc.CONTACT_DATE
    FROM PAT_POP pp
        INNER JOIN PAT_ENC enc ON pp."Pat ID" = enc.PAT_ID
            AND enc.DEPARTMENT_ID IN ('1000106010 ','1012301018')
            AND enc.APPT_STATUS_C <> 3 --Not a cancelled visit ---PAC visit
    WHERE
        enc.APPT_TIME IS NOT NULL 
        AND enc.CONTACT_DATE >= pp."Procedure Date" - 60
        AND enc.CONTACT_DATE <= pp."Procedure Date"
        AND NOT EXISTS
            (SELECT
                pacv.LOG_ID
            FROM PAC_VISIT pacv
            WHERE pp."Log ID" = pacv.LOG_ID        
            )
    ORDER BY
        enc.CONTACT_DATE DESC
    )
)


, CASE_SCORES
AS
(
SELECT DISTINCT
    orc.LOG_ID
    , pp."Pat ID"
--    , orc.TOTAL_TIME_NEEDED
    , CASE
        WHEN orc.TOTAL_TIME_NEEDED <= 60 THEN 1
        WHEN orc.TOTAL_TIME_NEEDED > 60 AND orc.TOTAL_TIME_NEEDED <= 180 THEN 2
        WHEN orc.TOTAL_TIME_NEEDED > 180 THEN 3
    END AS "Surgical Time Points"
--    , orl.ASA_RATING_C
    , CASE
        WHEN orl.ASA_RATING_C IS NULL THEN 0
        WHEN orl.ASA_RATING_C = 1 THEN 0
        WHEN orl.ASA_RATING_C = 2 THEN 1
        WHEN orl.ASA_RATING_C = 3 THEN 2
        WHEN orl.ASA_RATING_C >= 4 THEN 3
    END AS "ASA Points"
--    , orc.SERVICE_C
    , CASE
        WHEN orc.SERVICE_C IN (10, 100, 230, 340) THEN 1
        WHEN orc.SERVICE_C = 90 THEN 2
        WHEN orc.SERVICE_C IN (110, 120, 190, 250, 410) THEN 3
        WHEN orc.SERVICE_C IN (40, 390, 420) THEN 1
        ELSE 0
    END AS "Surgical Service Points" 
--    , srg.SCORE_SURGICAL_RISK
    , CASE
        WHEN srg.SCORE_SURGICAL_RISK IS NULL THEN 0
        WHEN TO_NUMBER(srg.SCORE_SURGICAL_RISK) <= '4' THEN 1
        WHEN TO_NUMBER(srg.SCORE_SURGICAL_RISK) > '4' AND TO_NUMBER(srg.SCORE_SURGICAL_RISK) <= '8' THEN 2
        WHEN TO_NUMBER(srg.SCORE_SURGICAL_RISK) > '8' THEN 3
    END AS "Surgical Risk Points"  

FROM PAT_POP pp
    INNER JOIN OR_CASE orc ON pp."Log ID" = orc.LOG_ID
    INNER JOIN OR_LOG orl ON pp."Log ID" = orl.LOG_ID
    LEFT OUTER JOIN X_DM_SURGICAL_RISK srg ON pp."Pat ID" = srg.PAT_ID
)

, FRAILTY_INDEX
AS
(
SELECT DISTINCT
    pp."Pat ID"
    , sed.ELEMENT_ID
    , sed.CONTEXT_NAME
    , sev.SMRTDTA_ELEM_VALUE
    , CASE
        WHEN SUBSTR(sev.SMRTDTA_ELEM_VALUE, 1, 5) < 0.210 THEN 0
        WHEN SUBSTR(sev.SMRTDTA_ELEM_VALUE, 1, 5) >= 0.210 THEN 1
    END AS "Frailty Risk Points"
FROM PAT_POP pp
    INNER JOIN SMRTDTA_ELEM_DATA sed ON pp."Pat ID" = sed.PAT_LINK_ID
    INNER JOIN SMRTDTA_ELEM_VALUE sev ON sed.HLV_ID = sev.HLV_ID
WHERE 
    sed.ELEMENT_ID = 'WH#1660'

)

SELECT
    pp."Log ID"
    , pp."Surgeon Name"
    , pp."Parent Location"
    , pp."Service"
    , pp."Location"
    , pp."Room"
    , pp."Procedure Date"
    , pp."Patient Class"
    , pp."Case Class"
    , pp."Procedure Name"
    , pp."Patient MRN"
    , pp."Age at Encounter"
    , pp."Patient City"
    , pp."Patient State"
    , pp."Patient Zipcode"
    , snc."SNC Call Completed"
    , snc."Navigator Reached Patient"
    , CASE  WHEN pac.CONTACT_DATE IS NOT NULL OR upv.CONTACT_DATE IS NOT NULL THEN 'Yes' ELSE 'No' END AS "PAC Visit?"    
    , (css."Surgical Time Points" + css."ASA Points" + css."Surgical Service Points"  + css."Surgical Risk Points"  
        + (CASE WHEN frx."Frailty Risk Points" IS NULL THEN 0 ELSE frx."Frailty Risk Points" END))
        AS "Surgery Risk Score"
--    , css."Surgical Time Points"
--    , css."ASA Points"
--    , css."Surgical Service Points" 
--    , css."Surgical Risk Points"   
--    , frx."Frailty Risk Points"
FROM PAT_POP pp
    LEFT OUTER JOIN SNC_CALL snc ON pp."Log ID" = snc."Log ID"
    LEFT OUTER JOIN PAC_VISIT pac ON pp."Log ID" = pac.LOG_ID
    LEFT OUTER JOIN UNLINKED_PAC_VISIT upv ON pp."Log ID" = upv."Log ID"
    LEFT OUTER JOIN CASE_SCORES css ON pp."Log ID" = css.LOG_ID
    LEFT OUTER JOIN FRAILTY_INDEX frx ON pp."Pat ID" = frx."Pat ID"
