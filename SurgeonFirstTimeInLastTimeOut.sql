WITH 
--
-- The time the primary surgeon ENTERED the OR.
-- The surgeon can enter and exit the OR multiple times during a case.
-- This field is not populated in all cases.
--
ORDRIN
AS
(
SELECT
    surgin.LOG_ID
    , surgin.LINE
    , surgin.SURG_ID
    , surgin.ROLE_C
    , surgin.START_TIME
    , surgin.END_TIME
    , surgin.PANEL
    , ROW_NUMBER() OVER (PARTITION BY surgin.LOG_ID  ORDER BY surgin.LINE ) AS SEQ_NUM_in
FROM 
    OR_LOG_ALL_SURG surgin
WHERE 
    surgin.ROLE_C = 1
    AND surgin.PANEL = 1
ORDER BY surgin.SURG_ID, surgin.LOG_ID, surgin.LINE
)
, 
--
-- The time the primary surgeon EXITED the OR.
-- The surgeon can enter and exit the OR multiple times during a case.
-- This field is not populated in all cases.
--
ORDROUT
AS
(
SELECT
    surgout.LOG_ID
    , surgout.LINE
    , surgout.SURG_ID
    , surgout.ROLE_C
    , surgout.START_TIME
    , surgout.END_TIME
    , surgout.PANEL
    , ROW_NUMBER() OVER (PARTITION BY surgout.LOG_ID  ORDER BY surgout.LINE DESC) AS SEQ_NUM_out
FROM 
    OR_LOG_ALL_SURG surgout
WHERE 
    surgout.ROLE_C = 1
    AND surgout.PANEL = 1
ORDER BY surgout.SURG_ID, surgout.LOG_ID, surgout.LINE DESC
)
,ORLOG1
AS
(
SELECT *
FROM
(
    SELECT *
    FROM
    (
                 SELECT 
                olc.LOG_ID
                , vlb.NUMBER_OF_PANELS
                , ordrin.PANEL
                , ordrin.SEQ_NUM_in
                , ordrout.SEQ_NUM_out
                , vlb.ROOM_PREVIOUS_LOG_ID
                , olc.TRACKING_EVENT_C
                , olc.TRACKING_TIME_IN
                , vlb.PRIMARY_PHYSICIAN_ID
                , vlb.PRIMARY_PHYSICIAN_NM
                , ordrin.START_TIME
                , ordrout.END_TIME
                , vlb.ROOM_ID
                , vlb.ROOM_NM_WID
                , vlb.PROC_DATE
                , vlb.CASE_ID
                , vlb.CASE_CLASS_C
                , zc_cc.NAME
                , vlb.PRIMARY_PROCEDURE_NM_WID
                , pat.PAT_MRN_ID
                , pat.PAT_ID
                , pat.PAT_NAME
                , pat.BIRTH_DATE
                FROM OR_LOG_CASE_TIMES  olc
                    INNER JOIN ZC_OR_PAT_EVENTS zo ON zo.TRACKING_EVENT_C = olc.TRACKING_EVENT_C
                    LEFT OUTER JOIN ORDRIN ordrin ON ordrin.LOG_ID = olc.LOG_ID 
                        AND ordrin.SEQ_NUM_in = 1
                    LEFT OUTER JOIN ORDROUT ordrout ON ordrout.LOG_ID = olc.LOG_ID 
                        AND ordrout.SEQ_NUM_out = 1
                    INNER JOIN V_LOG_BASED vlb ON vlb.LOG_ID = olc.LOG_ID
                    INNER JOIN PATIENT pat ON pat.PAT_ID = vlb.PAT_ID
                    INNER JOIN ZC_OR_CASE_CLASS zc_cc ON vlb.CASE_CLASS_C = zc_cc.CASE_CLASS_C
                WHERE olc.TRACKING_EVENT_C IN ('60','360','70','80','90','100','110')
                    AND vlb.NUMBER_OF_PANELS = 1
                    AND vlb.PROC_DATE >= '01-Jan-2017'
                    AND vlb.PROC_DATE <= '31-Dec-2017'
--                    AND vlb.PRIMARY_PHYSICIAN_ID IN ('10019', '10060', '10239')
                ORDER BY vlb.PRIMARY_PHYSICIAN_ID, CASE WHEN olc.TRACKING_EVENT_C = '80' THEN olc.TRACKING_TIME_IN END
    )
)     

pivot

  (
               MAX(TRACKING_TIME_IN)
                                FOR TRACKING_EVENT_C IN ('60' AS INROOM1,'360' AS ANESREADY1, '70' AS ANESSTART1,'80' AS PROCSTART1,
                                                                                            '90'AS PROCEND1,'100' AS ANESEND1,'110'AS OUTROOM1)
  ) 
  
    ORDER BY PROCSTART1 
)  

--, BLOOD_LOSS
--AS
--(SELECT
--    orl.LOG_ID
--    , SUM(meas.MEAS_VALUE) "Estimated Blood Loss"
--FROM IP_FLWSHT_REC rec
--    LEFT OUTER JOIN IP_FLWSHT_MEAS meas ON rec.FSD_ID = meas.FSD_ID
--    LEFT OUTER JOIN IP_FLO_GP_DATA dat ON meas.FLO_MEAS_ID = dat.FLO_MEAS_ID
--    LEFT OUTER JOIN PAT_ENC enc ON rec.INPATIENT_DATA_ID = enc.INPATIENT_DATA_ID
--    LEFT OUTER JOIN F_AN_RECORD_SUMMARY fans ON enc.PAT_ENC_CSN_ID = fans.AN_52_ENC_CSN_ID
--    LEFT OUTER JOIN AN_HSB_LINK_PROCS apr ON fans.AN_EPISODE_ID = apr.SUMMARY_BLOCK_ID
--    LEFT OUTER JOIN PAT_OR_ADM_LINK lnk ON apr.EPT_PROC_CSN = lnk.PAT_ENC_CSN_ID
--    LEFT OUTER JOIN OR_LOG orl ON lnk.LOG_ID = orl.LOG_ID
--    LEFT OUTER JOIN ORLOG1 orl1 ON orl.LOG_ID = orl1.LOG_ID
--WHERE 
--    meas.FLO_MEAS_ID = '400620'
--    AND meas.FLT_ID = '1120010009'
--GROUP BY orl.LOG_ID)

, BLOOD_LOSS
AS
(SELECT
    LOG_ID
    , SUM(MEAS_VALUE) "Estimated Blood Loss"
FROM
    (SELECT DISTINCT
        orl.LOG_ID
        , meas.FSD_ID
        , meas.LINE
        , meas.MEAS_VALUE
    FROM IP_FLWSHT_REC rec
        LEFT OUTER JOIN IP_FLWSHT_MEAS meas ON rec.FSD_ID = meas.FSD_ID
        LEFT OUTER JOIN IP_FLO_GP_DATA dat ON meas.FLO_MEAS_ID = dat.FLO_MEAS_ID
        LEFT OUTER JOIN PAT_ENC enc ON rec.INPATIENT_DATA_ID = enc.INPATIENT_DATA_ID
        LEFT OUTER JOIN F_AN_RECORD_SUMMARY fans ON enc.PAT_ENC_CSN_ID = fans.AN_52_ENC_CSN_ID
        LEFT OUTER JOIN AN_HSB_LINK_PROCS apr ON fans.AN_EPISODE_ID = apr.SUMMARY_BLOCK_ID
        LEFT OUTER JOIN PAT_OR_ADM_LINK lnk ON apr.EPT_PROC_CSN = lnk.PAT_ENC_CSN_ID
        LEFT OUTER JOIN OR_LOG orl ON lnk.LOG_ID = orl.LOG_ID
        LEFT OUTER JOIN ORLOG1 orl1 ON orl.LOG_ID = orl1.LOG_ID
    WHERE 
        meas.FLO_MEAS_ID = '400620'
        AND meas.FLT_ID = '1120010009')
GROUP BY 
    LOG_ID
    , FSD_ID)

SELECT 
orl1.LOG_ID   "Log ID"
--
-- Ordering the cases for a given primary surgeon by incision start time.
--
--, DENSE_RANK () OVER (PARTITION BY orl1.PRIMARY_PHYSICIAN_ID, orl1.PROC_DATE  ORDER BY orl1.PROCSTART1, orl1.LOG_ID) AS SEQ_NUM1
--, orl1.SEQ_NUM_in
--, orl1.SEQ_NUM_out
--, orl1.PAT_ID "Pat ID"
, orl1.PAT_MRN_ID "MRN"
, orl1.PAT_NAME "Patient Name"
, orl1.BIRTH_DATE "Date of Birth"
, orl1.PROC_DATE  "Date of Surgery"
, orl1.PRIMARY_PHYSICIAN_ID "Primary Surgeon ID"
, orl1.PRIMARY_PHYSICIAN_NM "Primary Surgeon Name"
, orl1.PRIMARY_PROCEDURE_NM_WID "Procedure Name"
, orl1.INROOM1  "Patient In Room Time"
, orl1.ANESSTART1  "Anesthesia Start Time"        
, orl1.START_TIME "Surgeon in Room Time"
, orl1.PROCSTART1  "Incision Start Time"
, orl1.PROCEND1  "Procedure End Time" 
, orl1.END_TIME  "Surgeon Out Room Time"
, orl1.ANESEND1  "Anesthesia End Time"               
, orl1.OUTROOM1  "Patient Out of Room Time"  
, bls."Estimated Blood Loss"

FROM ORLOG1 orl1
    INNER JOIN CLARITY_SER ser ON ser.PROV_ID = orl1.PRIMARY_PHYSICIAN_ID
    LEFT OUTER JOIN BLOOD_LOSS bls ON orl1.LOG_ID = bls.LOG_ID
WHERE 
--    orl1.PROC_DATE >= '01-Jan-2017'
--    AND orl1.PROC_DATE <= '31-Dec-2017'
--    AND 
    orl1.PROCSTART1 IS NOT NULL
    AND orl1.PROCEND1 IS NOT NULL
    AND orl1.SEQ_NUM_in = orl1.SEQ_NUM_out
    AND FLOOR((orl1.PROC_DATE - orl1.BIRTH_DATE) / 365.25) < 18
ORDER BY orl1.LOG_ID, orl1.PROCSTART1, orl1.SEQ_NUM_IN, orl1.SEQ_NUM_OUT