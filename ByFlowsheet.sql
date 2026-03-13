    SELECT
    * 
    FROM 

(
                SELECT --*
                meas.MEAS_VALUE 
                ,meas.RECORDED_TIME 
                ,meas.OCCURANCE
                ,meas.LINE
                ,meas.FSD_ID
                ,fs_ord.GROUP_LINE
                ,fs_ord.IX_FLOW_RW_ORD_ID
--                ,flo.FLOWSHT_ROW_NAME
                ,rec.INPATIENT_DATA_ID
                ,meas.FLT_ID
                ,pat.PAT_MRN_ID
                ,pat.PAT_NAME
                ,hsp.PAT_ENC_CSN_ID
                ,hsp.HOSP_ADMSN_TIME
                ,hsp.HOSP_DISCH_TIME
                ,dep.DEPARTMENT_NAME
                
--                 ,row_number() OVER (PARTITION BY rec.INPATIENT_DATA_ID ORDER BY meas.RECORDED_TIME DESC) "SEQ_NUM"
            
                FROM IP_FLWSHT_REC rec 
                LEFT OUTER JOIN IP_FLWSHT_MEAS meas on meas.FSD_ID=rec.FSD_ID
                LEFT OUTER JOIN IP_FS_ORD_IX_ID fs_ord ON rec.INPATIENT_DATA_ID = fs_ord.INPATIENT_DATA_ID AND meas.LINE = fs_ord.GROUP_LINE
                LEFT OUTER JOIN PAT_ENC_HSP hsp ON rec.INPATIENT_DATA_ID = hsp.INPATIENT_DATA_ID
                LEFT OUTER JOIN clarity_dep dep ON hsp.DEPARTMENT_ID = dep.DEPARTMENT_ID
--                LEFT OUTER JOIN ip_flowsheet_rows flo ON rec.INPATIENT_DATA_ID = flo.INPATIENT_DATA_ID AND meas.OCCURANCE = flo.LINE 

                INNER JOIN patient pat ON rec.PAT_ID = pat.PAT_ID
                where 
                rec.INPATIENT_DATA_ID = 45189744
                AND meas.FLO_MEAS_ID IN ('3047000021','3047000020','3047000019')

--                pat.PAT_ID = 'Z2166800'
--                AND TRUNC(meas.RECORDED_TIME) = '13-feb-2020'

--                meas.FLO_MEAS_ID='210823174'
--                (
--                     decode( meas.FLO_MEAS_ID,'210823174',meas.MEAS_VALUE)>='No' OR 
--                          decode( meas.FLO_MEAS_ID,'210823174',meas.MEAS_VALUE)>='Yes'  
--                 )
--                                and meas.RECORDED_TIME > TRUNC (ADD_MONTHS (epic_util.efn_din('{?Start Date}')-1, -6), 'MM') 
--                          and meas.RECORDED_TIME > TRUNC (ADD_MONTHS ('1-jan-2019', -60), 'MM') 
--                           AND meas.RECORDED_TIME < '1-jan-2020'
--                            AND meas.RECORDED_TIME <= epic_util.efn_din('{?Start Date}')-1
                      
  


)
    
    where SEQ_NUM <= 1
    ORDER BY SEQ_NUM, PAT_ID


SELECT *
FROM PATIENT pat
WHERE
pat.PAT_MRN_ID = '3272405'


SELECT *
FROM F_IP_HSP_SUM_MED_ADMIN fip
WHERE
fip.PAT_ID='Z2166800'
AND fip.TAKEN_DATE = '5-jan-2021'
AND fip.PROC_ID = 58677


SELECT *
FROM ORDER_PROC ores
INNER JOIN ORD_FINDINGS res ON ores.ORDER_PROC_ID = res.ORDER_PROC_ID
WHERE
ores.ORDER_PROC_ID = '549710531'


SELECT * 
FROM IP_FSD_TOTALS fsd
INNER JOIN IP_FLWSHT_REC rec ON fsd.ID = rec.FSD_ID
                LEFT OUTER JOIN IP_FLWSHT_MEAS meas on meas.FSD_ID=rec.FSD_ID
WHERE

--fsd.ID=  26673956 and
-- fsd.FLO_ID_FOR_ROW = '2533-3451'
 rec.PAT_ID = 'Z2135895'