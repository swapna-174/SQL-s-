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
--    , ROW_NUMBER() OVER (PARTITION BY surgout.LOG_ID  ORDER BY surgout.LINE DESC) AS SEQ_NUM_out
    , ROW_NUMBER() OVER (PARTITION BY surgout.LOG_ID  ORDER BY surgout.LINE) AS SEQ_NUM_out
FROM 
    OR_LOG_ALL_SURG surgout
WHERE 
    surgout.ROLE_C = 1
    AND surgout.PANEL = 1
--ORDER BY surgout.SURG_ID, surgout.LOG_ID, surgout.LINE DESC
ORDER BY surgout.SURG_ID, surgout.LOG_ID, surgout.LINE
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
--                , vlb.CASE_ID
                , vlb.CASE_CLASS_C
                , zc_cc.NAME
                , vlb.PRIMARY_PROCEDURE_NM_WID
                , pat.PAT_MRN_ID
                , pat.PAT_ID
                , pat.PAT_NAME
                , pat.BIRTH_DATE
                FROM OR_LOG_CASE_TIMES  olc
                    LEFT OUTER JOIN ZC_OR_PAT_EVENTS zo ON zo.TRACKING_EVENT_C = olc.TRACKING_EVENT_C
                    LEFT OUTER JOIN ORDRIN ordrin ON ordrin.LOG_ID = olc.LOG_ID 
--                        AND ordrin.SEQ_NUM_in = 1
                    LEFT OUTER JOIN ORDROUT ordrout ON ordrout.LOG_ID = olc.LOG_ID 
--                        AND ordrout.SEQ_NUM_out = 1
                    LEFT OUTER JOIN V_LOG_BASED vlb ON vlb.LOG_ID = olc.LOG_ID
                    LEFT OUTER JOIN PATIENT pat ON pat.PAT_ID = vlb.PAT_ID
                    LEFT OUTER JOIN ZC_OR_CASE_CLASS zc_cc ON vlb.CASE_CLASS_C = zc_cc.CASE_CLASS_C
                WHERE olc.TRACKING_EVENT_C IN ('60','360','70','80','90','100','110')
                    AND vlb.NUMBER_OF_PANELS = 1
                    AND vlb.PROC_DATE >= '01-Jan-2017'
                    AND vlb.PROC_DATE <= '31-Dec-2017'
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

--, SURGEON_PRESENT
--AS
--(
SELECT *
FROM
(SELECT
    orl1.LOG_ID
--    , orl1.PAT_MRN_ID
--    , orl1.PAT_NAME
--    , orl1.SEQ_NUM_in
--    , orl1.SEQ_NUM_out
--    , orl1.START_TIME
--    , orl1.PROCSTART1
--    , orl1.END_TIME
    , CASE
        WHEN orl1.PROCSTART1 >= orl1.START_TIME AND orl1.PROCSTART1 <= orl1.END_TIME
        THEN 'YES'
        ELSE 'NO'
    END AS Present
FROM ORLOG1 orl1
WHERE
    orl1.SEQ_NUM_in = orl1.SEQ_NUM_out
ORDER BY
    orl1.LOG_ID
    , orl1.PROCSTART1)
WHERE
    Present = 'YES'
    
--)