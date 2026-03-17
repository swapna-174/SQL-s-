--SELECT *
--FROM OR_CASE or_case
--    INNER JOIN OR_CASE_ALL_SURG or_surg ON or_case.OR_CASE_ID = or_surg.OR_CASE_ID
--WHERE or_case.OR_CASE_ID = 188788
--
--SELECT or_c.OR_CASE_ID, or_s.*
--FROM OR_CASE or_c
--    INNER JOIN OR_CASE_ALL_SURG or_s ON or_c.OR_CASE_ID = or_s.OR_CASE_ID
--WHERE or_c.NUM_OF_PANELS = 4
--
--select * from V_LOG_TIMING_EVENTS v
----where v.PATIENT_IN_ROOM_DTTM >= to_date('7/7/2015', 'MM-DD-YYYY')
--where v.LOG_ID = 188788
--
--select * from OR_LOG_TIMING_EVENTS ort
----where ort.TIMING_EVENT_DTTM >= to_date('10/01/2015', 'MM-DD-YYYY')
--   -- and ort.TIMING_EVENT_C = 1000
--where ort.LOG_ID = 188788
--
--select * from OR_LOG_DURATIONS ord
--where ord.LOG_ID = 188788
--
--select * from OR_LOG_ALL_SURG orc
--where orc.LOG_ID = 188788
--
--sele
--
--select * from or_log
--where or_log.LOG_ID = 188788

--SELECT *
----ocp.OR_CASE_ID, ocp.OR_PROC_ID, ocp.PANEL, olc.*, vlb.*
--FROM OR_LOG_CASE_TIMES olc
--    INNER JOIN V_LOG_BASED vlb ON vlb.LOG_ID = olc.LOG_ID
-- --   INNER JOIN OR_CASE_ALL_PROC ocp ON olc.LOG_ID = ocp.OR_CASE_ID
--WHERE olc.LOG_ID = 183123
--    AND olc.TRACKING_EVENT_C IN ('60','360','70','80','90','100','110')
--
-- ORDER BY vlb.PRIMARY_PHYSICIAN_ID, CASE WHEN olc.TRACKING_EVENT_C = '80' THEN olc.TRACKING_TIME_IN END
--
--SELECT *
--FROM OR_LOG_ALL_SURG srg
--WHERE srg.LOG_ID = 208096
--
SELECT
    surgin.LOG_ID
    , surgin.LINE
    , surgin.SURG_ID
    , surgin.ROLE_C
    , surgin.START_TIME
    , surgin.END_TIME
    , surgin.PANEL
    , ROW_NUMBER() OVER (PARTITION BY surgin.SURG_ID ORDER BY surgin.LOG_ID, surgin.LINE ) AS SEQ_NUM
FROM 
    OR_LOG_ALL_SURG surgin
WHERE 
--    surgin.SURG_ID = '10060' 
--    AND 
    surgin.ROLE_C = 1
    AND 
surgin.PANEL = 1
    AND surgin.LOG_ID IN ('169360','200391')
ORDER BY surgin.SURG_ID, surgin.LOG_ID, surgin.LINE

--SELECT
--    surgout.LOG_ID
--    , surgout.LINE
--    , surgout.SURG_ID
--    , surgout.ROLE_C
--    , surgout.START_TIME
--    , surgout.END_TIME
--    , surgout.PANEL
--    , ROW_NUMBER() OVER (PARTITION BY surgout.LOG_ID ORDER BY surgout.LINE DESC) AS SEQ_NUM
--FROM 
--    OR_LOG_ALL_SURG surgout
--WHERE 
----    surgout.SURG_ID = '10060' 
----    AND 
--surgout.ROLE_C = 1
--    AND surgout.PANEL = 1
--    AND surgout.LOG_ID = '208096'
----    AND rownum = 1
--ORDER BY surgout.SURG_ID, surgout.LOG_ID, surgout.LINE DESC
