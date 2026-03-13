WITH PEDSUR
AS
(
    SELECT -- *
    pat.PAT_MRN_ID
    ,pat.BIRTH_DATE
    ,orl.SURGERY_DATE
    ,orl_proc.PROC_DISPLAY_NAME
    ,orl.LOG_ID
    ,orl.PAT_ID
    ,orl.INPATIENT_DATA_ID
    ,orl_time.TRACKING_STAT_INST
    FROM OR_LOG orl
    INNER JOIN or_log_all_proc orl_proc ON orl.LOG_ID = orl_proc.LOG_ID  AND orl_proc.LINE = 1
    INNER JOIN or_log_case_times orl_time ON orl.LOG_ID = orl_time.LOG_ID AND orl_time.TRACKING_EVENT_C = '110'
    INNER JOIN patient pat ON orl.PAT_ID = pat.PAT_ID
    --INNER JOIN IP_FLWSHT_REC rec ON orl.INPATIENT_DATA_ID = rec.INPATIENT_DATA_ID
    --INNER JOIN IP_FSD_TOTALS fsd ON rec.FSD_ID = fsd.ID AND fsd.FLO_ID_FOR_ROW = '2533-3451'
    WHERE
--    orl.INPATIENT_DATA_ID = '45189744'
    orl.SURGERY_DATE >=' 1-jun-2020'
    AND orl.SURGERY_DATE <= '31-jul-2020'
     AND TRUNC((orl.SURGERY_DATE  - pat.BIRTH_DATE) / 365.25) < 18
)

,PEDBLOOD
AS
(
                SELECT -- *
                rec.INPATIENT_DATA_ID
                ,meas.OCCURANCE
                ,flo.FLOWSHT_ROW_NAME
                ,max(rec.RECORD_DATE) "TRANS_DATE"
                ,MAX(meas.RECORDED_TIME) "RECORDED"
                ,SUM(meas.MEAS_VALUE) "BLOOD_ADMIN"
            
                FROM PEDSUR peds
                LEFT OUTER JOIN IP_FLWSHT_REC rec ON peds.INPATIENT_DATA_ID = rec.INPATIENT_DATA_ID 
                LEFT OUTER JOIN IP_FLWSHT_MEAS meas on meas.FSD_ID=rec.FSD_ID
                LEFT OUTER JOIN ip_flowsheet_rows flo ON rec.INPATIENT_DATA_ID = flo.INPATIENT_DATA_ID AND meas.OCCURANCE = flo.LINE 
                where 
--                pat.PAT_ID = 'Z2135895'
--                rec.INPATIENT_DATA_ID =  '45189744'
                 meas.FLO_MEAS_ID = '2533'
--                AND meas.RECORDED_TIME >= '13-feb-2020'
                AND rec.RECORD_DATE >= peds.SURGERY_DATE
                GROUP BY rec.INPATIENT_DATA_ID,flo.FLOWSHT_ROW_NAME,meas.OCCURANCE
                ORDER BY meas.OCCURANCE
)

SELECT 
    peds.PAT_MRN_ID
    ,peds.BIRTH_DATE
    ,peds.SURGERY_DATE
    ,peds.PROC_DISPLAY_NAME
    ,pbld.FLOWSHT_ROW_NAME
    ,pbld.TRANS_DATE
    ,pbld.BLOOD_ADMIN
    ,peds.SURGERY_DATE
    ,peds.LOG_ID
    ,peds.INPATIENT_DATA_ID
    ,to_char(trunc(sysdate) + (pbld.RECORDED-peds.SURGERY_DATE), 'HH24') "LOS_HOURS"

FROM PEDSUR peds
LEFT OUTER JOIN PEDBLOOD pbld ON peds.INPATIENT_DATA_ID=pbld.INPATIENT_DATA_ID
WHERE
to_char(trunc(sysdate) + (pbld.RECORDED-peds.SURGERY_DATE), 'HH24') <= 72