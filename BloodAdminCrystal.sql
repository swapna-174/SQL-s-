WITH PEDSUR
AS
(
        SELECT
        pat.PAT_MRN_ID
        ,pat.BIRTH_DATE
        ,trunc(enc.WEIGHT * 0.0625)|| 'lb '|| round(MOD( ((enc.WEIGHT * 28.3495) / 453.59237  ),1) * 16,1)||'oz'  "WEIGHT"
        ,orl.SURGERY_DATE
        ,orl_proc.PROC_DISPLAY_NAME
        ,orl.LOG_ID
        ,orl.PAT_ID
        ,orl.INPATIENT_DATA_ID
        ,coalesce(orl_time.TRACKING_STAT_INST,orl.SURGERY_DATE)  "END_SURG"
        ,coalesce(orl_time_b.TRACKING_STAT_INST,orl.SURGERY_DATE)  "START_SURG"
        FROM OR_LOG orl
        inner join or_log_2 orl2 on orl.LOG_ID = orl2.log_id
        INNER JOIN pat_enc enc ON orl.INPATIENT_DATA_ID = enc.INPATIENT_DATA_ID AND enc.WEIGHT IS NOT null
        INNER JOIN or_log_all_proc orl_proc ON orl.LOG_ID = orl_proc.LOG_ID  AND orl_proc.LINE = 1
        INNER JOIN or_log_case_times orl_time ON orl.LOG_ID = orl_time.LOG_ID AND orl_time.TRACKING_EVENT_C = '110'
        INNER JOIN or_log_case_times orl_time_b ON orl.LOG_ID = orl_time_b.LOG_ID AND orl_time_b.TRACKING_EVENT_C = '60'
        INNER JOIN patient pat ON orl.PAT_ID = pat.PAT_ID
        WHERE
        orl.SURGERY_DATE >= EPIC_UTIL.EFN_DIN ('{?Start_Date}')    
        AND orl.SURGERY_DATE <= EPIC_UTIL.EFN_DIN ('{?End_Date}')
--                pat.PAT_MRN_ID = '4933845'
------
--        AND orl.INPATIENT_DATA_ID = '58813590' and
----        and orl.LOG_ID = 897729
--          orl.SURGERY_DATE >= '1-jan-2021'
--         AND orl.SURGERY_DATE <= '31-jan-2021'

         AND TRUNC((orl.SURGERY_DATE  - pat.BIRTH_DATE) / 365.25) < 18
         and orl.SURGERY_DATE is not null
)

,PEDBLOOD
AS
(
               
                SELECT distinct
                rec.INPATIENT_DATA_ID
                ,meas.OCCURANCE
                ,flo.FLOWSHT_ROW_NAME
                ,peds.LOG_ID
                ,peds.PROC_DISPLAY_NAME
                ,max(rec.RECORD_DATE) "BLOOD_ADMIN_DT"
                ,MAX(meas.RECORDED_TIME) "BLOOD_ADMIN_DTTM"
                ,SUM(meas.MEAS_VALUE) "BLOOD_ADMIN"
                ,count(peds.LOG_ID)  "KEEPME"

                FROM PEDSUR peds
                LEFT OUTER JOIN IP_FLWSHT_REC rec ON peds.INPATIENT_DATA_ID = rec.INPATIENT_DATA_ID 
                LEFT OUTER JOIN IP_FLWSHT_MEAS meas on meas.FSD_ID=rec.FSD_ID
                LEFT OUTER JOIN ip_flowsheet_rows flo ON rec.INPATIENT_DATA_ID = flo.INPATIENT_DATA_ID AND meas.OCCURANCE = flo.LINE 
                where 
                 meas.FLO_MEAS_ID = '2533'
                AND meas.RECORDED_TIME  >= peds.SURGERY_DATE
                and peds.START_SURG <> peds.END_SURG
                GROUP BY rec.INPATIENT_DATA_ID,peds.LOG_ID,peds.PROC_DISPLAY_NAME,flo.FLOWSHT_ROW_NAME,meas.OCCURANCE
                ORDER BY meas.OCCURANCE
)

,KEEPMESURG
as
(
   select 
   pb.INPATIENT_DATA_ID
   ,count(pb.INPATIENT_DATA_ID)   "FLAG"
   from PEDBLOOD pb
   GROUP BY pb.INPATIENT_DATA_ID

)

SELECT 
    peds.PAT_MRN_ID
    ,peds.BIRTH_DATE
    ,peds.WEIGHT
    ,peds.SURGERY_DATE
    ,peds.PROC_DISPLAY_NAME
    ,pbld.FLOWSHT_ROW_NAME
    ,peds.INPATIENT_DATA_ID
    ,peds.log_id
    ,peds.START_SURG
    ,peds.END_SURG
    ,pbld.BLOOD_ADMIN_DT 
    ,pbld.BLOOD_ADMIN_DTTM
    ,pbld.BLOOD_ADMIN
    ,ks.FLAG
    ,pbld.keepme
    ,trunc((pbld.BLOOD_ADMIN_DTTM - peds.END_SURG) * 24,1) "LOS_HOURS"

FROM PEDSUR peds
inner join KEEPMESURG ks on peds.INPATIENT_DATA_ID = ks.INPATIENT_DATA_ID ---AND ks.LOG_ID = peds.LOG_ID
left outer join PEDBLOOD pbld ON peds.INPATIENT_DATA_ID=pbld.INPATIENT_DATA_ID AND pbld.LOG_ID = peds.LOG_ID
WHERE
--
trunc((pbld.BLOOD_ADMIN_DTTM - peds.END_SURG) * 24,1)  <= 72 or (ks.flag>0 and pbld.keepme is null)



