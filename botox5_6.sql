WITH PATPOP
AS
(
  
    SELECT --*
    pat.PAT_MRN_ID
    ,ser.PROV_NAME
    ,mar.TAKEN_TIME  "SERVICE_DTTM"
    ,mar.MAR_ENC_CSN  "CSN"
    ,om.DISPLAY_NAME  "DESCRIPTION"
    
    ,dep.DEPARTMENT_NAME
    --,cm.NAME  "MEDICATION"
    --,op4.INDICATION_COMMENTS
    --,eap.PROC_NAME
    ,edg.DX_NAME
    ,om.ORDER_MED_ID "ID"
    ,om.PAT_ID
    ,rank() over ( partition by om.PAT_ID order by mar.TAKEN_TIME desc ,RowNum) rank1

    
    FROM MAR_ADMIN_INFO mar
    INNER JOIN order_med om ON mar.ORDER_MED_ID = om.ORDER_MED_ID
    INNER JOIN order_medinfo omi ON om.ORDER_MED_ID = omi.ORDER_MED_ID
    INNER JOIN order_dx_med orddx ON om.ORDER_MED_ID = orddx.ORDER_MED_ID
    LEFT OUTER JOIN clarity_medication cm ON omi.DISPENSABLE_MED_ID = cm.MEDICATION_ID
    LEFT OUTER JOIN clarity_edg edg ON orddx.DX_ID = edg.DX_ID
    LEFT OUTER JOIN patient pat ON om.PAT_ID = pat.PAT_ID
    LEFT OUTER JOIN clarity_ser ser ON om.AUTHRZING_PROV_ID = ser.PROV_ID
    LEFT OUTER JOIN clarity_dep dep ON mar.MAR_ADMIN_DEPT_ID = dep.DEPARTMENT_ID
    
    WHERE
    --mar.ORDER_MED_ID = 588507451 AND
    mar.MAR_ACTION_C IN ('1', '6', '102', '105', '113', '114', '115','1002')
    AND TRUNC(mar.TAKEN_TIME) >= '1-jul-2018'
    AND TRUNC(mar.TAKEN_TIME) < '1-jul-2020'
    AND UPPER(om.DISPLAY_NAME) LIKE '%BOTOX%'
    AND UPPER(edg.DX_NAME) LIKE '%MIGRAINE%'
    AND om.AUTHRZING_PROV_ID in ('39617','10443','131108','138510','10365','39708','36090','26982')
--    AND om.PAT_ID = 'Z3540569'

    UNION 
    
    SELECT --*
    pat.PAT_MRN_ID
    ,ser.PROV_NAME
    --,op.ORDERING_DATE
    ,op.ORDER_TIME    "SERVICE_DTTM"
    ,op.PAT_ENC_CSN_ID  "CSN"
    ,op.DESCRIPTION    "DESCRIPTION"
    ,dep.DEPARTMENT_NAME
    --,op4.INDICATION_COMMENTS
    --,eap.PROC_NAME
    ,edg.DX_NAME
    ,op.ORDER_PROC_ID "ID"
        ,op.PAT_ID
    ,rank() over ( partition by op.PAT_ID order by op.ORDER_TIME desc  ,RowNum) rank1

    --,op.FUTURE_OR_STAND
    --FROM PAT_ENC_hsp enc 
    FROM order_proc op -----ON enc.PAT_ENC_CSN_ID = op.PAT_ENC_CSN_ID
    INNER JOIN order_proc_2 op2 ON op.ORDER_PROC_ID = op2.ORDER_PROC_ID
    --INNER JOIN order_proc_4 op4 ON op.ORDER_PROC_ID = op4.ORDER_ID
    INNER JOIN order_dx_proc opdx ON op.ORDER_PROC_ID = opdx.ORDER_PROC_ID
    INNER JOIN patient pat ON op.PAT_ID = pat.PAT_ID
    LEFT OUTER JOIN clarity_eap eap ON op.PROC_ID = eap.PROC_ID
    LEFT OUTER JOIN clarity_edg edg ON opdx.DX_ID = edg.DX_ID
    LEFT OUTER JOIN clarity_ser ser ON op.AUTHRZING_PROV_ID = ser.PROV_ID
    LEFT OUTER JOIN clarity_dep dep ON op2.PAT_LOC_ID = dep.DEPARTMENT_ID
    WHERE
     op.ORDERING_DATE >= '1-jul-2018'
     AND op.ORDERING_DATE < '1-jul-2020'
     AND op.ORDER_STATUS_C <> 4
    -- AND op2.PAT_LOC_ID = 1000104006
    AND UPPER(eap.PROC_NAME) LIKE '%BOTOX%'
    AND op.AUTHRZING_PROV_ID in ('39617','10443','131108','138510','10365','39708','36090','26982')
    AND UPPER(edg.DX_NAME) LIKE '%MIGRAINE%'
--    AND op.PAT_ID = 'Z3540569'
)
,PPLONE
as
(
  SELECT *
--      patp.PAT_MRN_ID
--    ,patp.PROV_NAME
--    ,patp.SERVICE_DTTM
--    ,patp.CSN
--    ,patp.DESCRIPTION
--    ,patp.DEPARTMENT_NAME
--    ,patp.DX_NAME
--    ,patp.ID

  FROM PATPOP patp
  WHERE
  rank1 = 1


)

,PPLMO
AS
(
    SELECT --*
    pat.PAT_MRN_ID
    ,ser.PROV_NAME
    ,mar.TAKEN_TIME  "SERVICE_DTTM"
    ,mar.MAR_ENC_CSN  "CSN"
    ,om.DISPLAY_NAME  "DESCRIPTION"
    
    ,dep.DEPARTMENT_NAME
    --,cm.NAME  "MEDICATION"
    --,op4.INDICATION_COMMENTS
    --,eap.PROC_NAME
    ,edg.DX_NAME
    ,om.ORDER_MED_ID "ID"
            ,om.PAT_ID

    FROM MAR_ADMIN_INFO mar
    LEFT outer JOIN order_med om ON mar.ORDER_MED_ID = om.ORDER_MED_ID
    LEFT outer JOIN order_medinfo omi ON om.ORDER_MED_ID = omi.ORDER_MED_ID
    LEFT outer JOIN order_dx_med orddx ON om.ORDER_MED_ID = orddx.ORDER_MED_ID
    LEFT OUTER JOIN clarity_medication cm ON omi.DISPENSABLE_MED_ID = cm.MEDICATION_ID
    LEFT OUTER JOIN clarity_edg edg ON orddx.DX_ID = edg.DX_ID
    LEFT OUTER JOIN patient pat ON om.PAT_ID = pat.PAT_ID
    LEFT OUTER JOIN clarity_ser ser ON om.AUTHRZING_PROV_ID = ser.PROV_ID
    LEFT OUTER JOIN clarity_dep dep ON mar.MAR_ADMIN_DEPT_ID = dep.DEPARTMENT_ID
    
    WHERE
    --mar.ORDER_MED_ID = 588507451 AND
    mar.MAR_ACTION_C IN ('1', '6', '102', '105', '113', '114', '115','1002') and
     TRUNC(mar.TAKEN_TIME) >= '1-jul-2020'
--     om.ORDER_MED_ID = 580007416
    --AND TRUNC(mar.TAKEN_TIME) < '1-jul-2020'
    AND UPPER(om.DISPLAY_NAME) LIKE '%BOTOX%'
    AND (UPPER(edg.DX_NAME) LIKE '%MIGRAINE%' OR UPPER(edg.DX_NAME) IS NULL)
    AND om.AUTHRZING_PROV_ID in ('39617','10443','131108','138510','10365','39708','36090','26982')
--    AND om.PAT_ID = 'Z1293120'

    UNION 
    
    SELECT --*
    pat.PAT_MRN_ID
    ,ser.PROV_NAME
    --,op.ORDERING_DATE
    ,op.ORDER_TIME    "SERVICE_DTTM"
    ,op.PAT_ENC_CSN_ID  "CSN"
    ,op.DESCRIPTION    "DESCRIPTION"
    ,dep.DEPARTMENT_NAME
    --,op4.INDICATION_COMMENTS
    --,eap.PROC_NAME
    ,edg.DX_NAME
    ,op.ORDER_PROC_ID "ID"
            ,op.PAT_ID

    --,op.FUTURE_OR_STAND
    --FROM PAT_ENC_hsp enc 
    FROM order_proc op -----ON enc.PAT_ENC_CSN_ID = op.PAT_ENC_CSN_ID
    LEFT OUTER joiN order_proc_2 op2 ON op.ORDER_PROC_ID = op2.ORDER_PROC_ID
    --INNER JOIN order_proc_4 op4 ON op.ORDER_PROC_ID = op4.ORDER_ID
    LEFT OUTER joiN order_dx_proc opdx ON op.ORDER_PROC_ID = opdx.ORDER_PROC_ID
    INNER JOIN patient pat ON op.PAT_ID = pat.PAT_ID
    LEFT OUTER JOIN clarity_eap eap ON op.PROC_ID = eap.PROC_ID
    LEFT OUTER JOIN clarity_edg edg ON opdx.DX_ID = edg.DX_ID
    LEFT OUTER JOIN clarity_ser ser ON op.AUTHRZING_PROV_ID = ser.PROV_ID
    LEFT OUTER JOIN clarity_dep dep ON op2.PAT_LOC_ID = dep.DEPARTMENT_ID
    WHERE
     op.ORDERING_DATE >= '1-jul-2020'
    -- AND op.ORDERING_DATE < '1-jul-2020'
     AND op.ORDER_STATUS_C <> 4

    -- AND op2.PAT_LOC_ID = 1000104006
    AND UPPER(eap.PROC_NAME) LIKE '%BOTOX%'
    AND op.AUTHRZING_PROV_ID in ('39617','10443','131108','138510','10365','39708','36090','26982')
    AND UPPER(edg.DX_NAME) LIKE '%MIGRAINE%'
--   AND  op.PAT_ID = 'Z1293120'
)
SELECT *
FROM PPLONE ppl
where

 NOT exists (            SELECT
                                pdx.PAT_ID
                            FROM
                                PPLMO pdx
                            WHERE
                                ppl.PAT_ID = pdx.PAT_ID

)