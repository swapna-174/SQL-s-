
SELECT -- *
orl.LOG_ID
,orl.SURGERY_DATE
,orl.PAT_ID
,orl.INPATIENT_DATA_ID
,orl_proc.OR_PROC_ID
,orl_proc.ALL_PROCS_PANEL
,orl_proc.PROC_DISPLAY_NAME
--,fsd.TOTAL_0000_0100
--,fsd.TOTAL_0100_0200
--,fsd.ROW_TOTAL_DAILY

FROM OR_LOG orl
INNER JOIN or_log_all_proc orl_proc ON orl.LOG_ID = orl_proc.LOG_ID  AND orl_proc.LINE = 1
--INNER JOIN IP_FLWSHT_REC rec ON orl.INPATIENT_DATA_ID = rec.INPATIENT_DATA_ID
--INNER JOIN IP_FSD_TOTALS fsd ON rec.FSD_ID = fsd.ID AND fsd.FLO_ID_FOR_ROW = '2533-3451'
WHERE
--orl.PAT_ID = 'Z2166800'
orl.PAT_ID = 'Z2135895'
--AND orl.LOG_ID = 890391
'Z2135895'




SELECT --*
fsd.ID
,fsd.LINE
,fsd.FLO_ID_FOR_ROW
,fsd.ROW_TOTAL_DAILY
,rec.INPATIENT_DATA_ID
,rec.RECORD_DATE
FROM IP_FSD_TOTALS fsd
INNER JOIN IP_FLWSHT_REC rec ON fsd.ID = rec.FSD_ID
--LEFT OUTER JOIN IP_FLWSHT_MEAS meas on meas.FSD_ID=rec.FSD_ID

WHERE
rec.INPATIENT_DATA_ID = '45189744'
AND rec.RECORD_DATE = '13-feb-2020'
AND fsd.FLO_ID_FOR_ROW LIKE '2533-%'

SELECT *
FROM MAR_FSD_LINK fsc
WHERE
fsc.MAR_FLO_FSD_ID='26673956'
--fsd.ID=  26673956
--AND fsd.FLO_ID_FOR_ROW = '2533-3451'

SELECT *
FROM IP_FLOWSHEET_ROWS marfsd
--LEFT OUTER JOIN order_proc
WHERE
marfsd.INPATIENT_DATA_ID = '45189744'
AND marfsd.FLO_MEAS_ID = '2531'

SELECT *
FROM F_IP_HSP_SUM_MED_ADMIN fip
WHERE
fip.PAT_ID='Z2166800'
AND fip.TAKEN_DATE = '5-jan-2021'
AND fip.PROC_ID = 58677               
               
               
               
               
               
               
               
                SELECT -- *
                rec.INPATIENT_DATA_ID
                ,meas.OCCURANCE
                ,flo.FLOWSHT_ROW_NAME
                ,max(rec.RECORD_DATE) "TRANS_DATE"
--                ,MAX(ipfs.IX_FLOW_RW_ORD_ID) "TRANS_ORD"
--                ,meas.MEAS_VALUE
--                ,meas.FLO_MEAS_ID
--                ,meas.RECORDED_TIME
--                  ,meas.ENTRY_TIME
                ,SUM(meas.MEAS_VALUE) "BLOOD_ADMIN"
            
                FROM IP_FLWSHT_REC rec 
                LEFT OUTER JOIN IP_FLWSHT_MEAS meas on meas.FSD_ID=rec.FSD_ID
                LEFT OUTER JOIN ip_flowsheet_rows flo ON rec.INPATIENT_DATA_ID = flo.INPATIENT_DATA_ID AND meas.OCCURANCE = flo.LINE 
--                LEFT OUTER join ip_fs_ord_ix_id ipfs ON rec.INPATIENT_DATA_ID = ipfs.INPATIENT_DATA_ID AND meas.LINE = ipfs.GROUP_LINE

--                INNER JOIN patient pat ON rec.PAT_ID = pat.PAT_ID
                where 
--                pat.PAT_ID = 'Z2135895'
                rec.INPATIENT_DATA_ID =  '45189744'
                AND meas.FLO_MEAS_ID = '2533'
                AND meas.RECORDED_TIME >= '13-feb-2020'
                
                GROUP BY rec.INPATIENT_DATA_ID,flo.FLOWSHT_ROW_NAME,meas.OCCURANCE
                ORDER BY meas.OCCURANCE
                
                
                
                
  '3047000155'

SELECT *
FROM OR_LOG_VIRTUAL vorl
WHERE
vorl.LOG_ID = '890391'


SELECT --*
flog.LOG_ID
,flog.PROCEDURE_DATE
,flog.PATIENT_AGE
,flog.PRIMARY_PROCEDURE_ID
,flog.OUT_OR_DTTM

FROM F_LOG_BASED flog
INNER JOIN or_log orl ON flog.LOG_ID = orl.LOG_ID
--LEFT OUTER JOIN F_IP_HSP_SUM_MED_ADMIN f_sum ON orl.INPATIENT_DATA_ID = f_sum.inpatient
WHERE
flog.LOG_ID = '890391'

SELECT *
FROM PATIENT pat
WHERE
pat.PAT_MRN_ID = '3240789'


--ORDER1 549727928

SELECT *
FROM MAR_ADMIN_INFO mar
WHERE
mar.ORDER_MED_ID=549727928


SELECT --*
fip.ORDER_MED_ID
,fip.TAKEN_DATE
,fip.PAT_ENC_CSN_ID
,fip.ADMIN_PAT_DEPT_ID
,fip.OP_ENC_DATE
,fip.DISPLAY_NAME
,fip.PROC_ID
,fip.ENC_TYPE_C
,mar.INFUSION_RATE
,mar.MAR_INF_RATE_UNIT_C
,mar.MAR_ADMIN_DEPT_ID
FROM F_IP_HSP_SUM_MED_ADMIN fip
LEFT outer JOIN mar_admin_info mar ON fip.ORDER_MED_ID = mar.ORDER_MED_ID AND mar.mar_action_c IN (6,9)
WHERE
fip.PAT_ID='Z2135895'
--AND fip.TAKEN_DATE = '5-jan-2021'
AND fip.PROC_ID = 58677

SELECT *
FROM F_AN_RECORD_SUMMARY fan
INNER JOIN ed_iev_pat_info iev ON fan.AN_52_ENC_CSN_ID = iev.PAT_ENC_CSN_ID
INNER JOIN ed_iev_event_info info ON iev.EVENT_ID = info.EVENT_ID
WHERE
fan.LOG_ID = '702742'


SELECT *
FROM ORD_RES_BLOOD ords
WHERE
ords.BLOOD_PRODUCT_CODE='E0668V00'
AND ords.BLOOD_UNIT_NUMBER = 'W201220375681'

SELECT *
FROM ORD_BLOOD_ADMIN res
WHERE
res.BLOOD_UNIT_RES_ID=2585217