--                SELECT *
----                rec.INPATIENT_DATA_ID
----                ,meas.ENTRY_TIME
------                ,meas.MEAS_VALUE
------                ,meas.FLO_MEAS_ID
------                ,meas.RECORDED_TIME
------                  ,meas.ENTRY_TIME
----                ,SUM(meas.MEAS_VALUE) "BLOOD_ADMIN"
--            
--                FROM IP_FLWSHT_REC rec 
--                LEFT OUTER JOIN IP_FLWSHT_MEAS meas on meas.FSD_ID=rec.FSD_ID
----                INNER JOIN patient pat ON rec.PAT_ID = pat.PAT_ID
--                where 
----                pat.PAT_ID = 'Z2135895'
--                rec.INPATIENT_DATA_ID =  '45189744'
--                AND meas.FLO_MEAS_ID = '2533'
--                AND meas.RECORDED_TIME >= '13-feb-2020'
----                GROUP BY rec.INPATIENT_DATA_ID,meas.ENTRY_TIME
----                ORDER BY meas.ENTRY_TIME


--SELECT *
--FROM IP_FLWSHT_EDITED ipfe
--WHERE
--ipfe.EDITED_FLT_ID = 31030
--AND ipfe.FSD_ID = 26698997

SELECT distinct
ipf.INPATIENT_DATA_ID
,ipf.LINE
,ipf.FLO_MEAS_ID
,ipf.FLOWSHT_ROW_NAME
,ipfs.IX_FLOW_RW_ORD_ID
--,rec.RECORD_DATE
,rec.PAT_ID
,mar.TAKEN_TIME
,mar.MAR_ACTION_C
,mar.MAR_ENC_CSN
,mar.MAR_UNIT_NUM
,mar.USER_ID
,mar.INFUSION_RATE
,mar.MAR_INF_RATE_UNIT_C
,mar.MAR_ADMIN_DEPT_ID
,dep.DEPARTMENT_NAME
FROM IP_FLOWSHEET_ROWS ipf
INNER JOIN ip_fs_ord_ix_id ipfs ON ipf.INPATIENT_DATA_ID = ipfs.INPATIENT_DATA_ID AND ipf.LINE = ipfs.GROUP_LINE
INNER JOIN IP_FLWSHT_REC rec ON ipf.INPATIENT_DATA_ID = rec.INPATIENT_DATA_ID
INNER JOIN mar_admin_info mar ON ipfs.IX_FLOW_RW_ORD_ID = mar.ORDER_MED_ID
LEFT OUTER JOIN clarity_dep dep ON mar.MAR_ADMIN_DEPT_ID = dep.DEPARTMENT_ID
--LEFT OUTER JOIN IP_FLWSHT_MEAS meas on meas.FSD_ID=rec.FSD_ID
----INNER JOIN ip_fs_row_template ipfs ON ipf.INPATIENT_DATA_ID = ipf.INPATIENT_DATA_ID --AND ipf.FLO_MEAS_ID 
WHERE
ipf.FLO_MEAS_ID = 2531
AND ipf.INPATIENT_DATA_ID =  '45189744'
AND rec.PAT_ID = 'Z2135895'
AND mar.mar_action_c IN (6,9)
AND TRUNC(mar.TAKEN_TIME) >= '13-feb-2020'
--AND mar.MAR_INF_RATE_UNIT_C = 41
--AND rec.FSD_ID = '26673956'

--SELECT *
--FROM IP_FLO_OVRTM_SNGL ipflo
--WHERE
--ipflo.ID = 2533
--
               
                SELECT -- *
                rec.INPATIENT_DATA_ID
                ,meas.OCCURANCE
                ,flo.FLOWSHT_ROW_NAME
                ,max(rec.RECORD_DATE) "TRANS_DATE"
                ,MAX(meas.RECORDED_TIME) "RECORDED"
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
--                AND meas.RECORDED_TIME >= '13-feb-2020'
                
                GROUP BY rec.INPATIENT_DATA_ID,flo.FLOWSHT_ROW_NAME,meas.OCCURANCE
                ORDER BY meas.OCCURANCE