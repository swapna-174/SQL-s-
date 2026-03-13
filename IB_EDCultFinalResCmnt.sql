WITH IBMSG
AS
(
    SELECT DISTINCT
    ibca.MSG_ID
    ,ibc.COMMAND_ABBRV
    ,ibca.AUDIT_TIME
    ,ibca.AUD_BY_USER_ID
    ,emp.NAME
    ,op.PAT_ID
    ,ib2.CREATE_INSTANT_DTTM
    ,ibrsl.ORDER_PROC_ID
    ,op.DESCRIPTION
    ,op.PAT_ENC_CSN_ID
    ,pat.PAT_MRN_ID
    ,fed.EMERGENCY_ADMISSION_DTTM "EMERGENCY_DTTM"
    ,orsc.RESULTS_CMT
    ,ors.COMPONENT_COMMENT
    FROM IB_COMMAND_AUDIT ibca
    INNER JOIN ib_messages_2 ib2 ON ibca.MSG_ID = ib2.MSG_ID
    INNER JOIN ib_commands ibc ON ibca.CMD_AUDIT = ibc.COMMAND_ID
    INNER JOIN IB_RSLTS_MSSG_ORDS ibrsl ON ibca.MSG_ID = ibrsl.MSG_ID
    INNER JOIN order_proc op ON ibrsl.ORDER_PROC_ID = op.ORDER_PROC_ID
    INNER JOIN order_status os ON op.ORDER_PROC_ID = os.ORDER_ID
    INNER JOIN order_results ors ON op.ORDER_PROC_ID = ors.ORDER_PROC_ID
    INNER JOIN order_res_comment orsc ON ors.ORDER_PROC_ID = orsc.ORDER_ID
    INNER join f_ed_encounters fed ON op.PAT_ENC_CSN_ID = fed.PAT_ENC_CSN_ID
    INNER JOIN patient pat ON op.PAT_ID = pat.PAT_ID
    LEFT OUTER JOIN clarity_emp emp ON ibca.AUD_BY_USER_ID = emp.USER_ID

    WHERE
       ( ibca.AUD_REGISTRY IN (13411,10457) AND op.ORDER_TYPE_C = 3
     OR ( ibca.AUD_REGISTRY IN (13411,10457) and op.PROC_ID = 102238 AND ors.COMPONENT_ID IN (1230291518, 1230291512)) )

--    (ibca.AUD_REGISTRY = 13411 OR (op.PROC_ID = 102238 AND ors.COMPONENT_ID IN (1230291518, 1230291512)) ) 
    AND TRUNC(ib2.CREATE_INSTANT_DTTM) >= '1-sep-2019'
--        AND TRUNC(ib2.CREATE_INSTANT_DTTM) >= '1-dec-2020'
    AND TRUNC(ib2.CREATE_INSTANT_DTTM) <= '30-nov-2020'
--AND op.ORDER_PROC_ID = 601247766
--    AND ibca.MSG_ID = '302296311'         ---30126496585
--    AND pat.PAT_MRN_ID = '2153749'
    and ibca.CMD_AUDIT = '1009'
    AND os.CONTACT_TYPE_C <> 1
--    AND os.ABNORMAL_YN = 'Y'
    AND op.DESCRIPTION NOT LIKE '%BLOOD%'
    AND orsc.RESULTS_CMT LIKE '%invalid due to nonspecific%'
    AND TRUNC((TRUNC(ib2.CREATE_INSTANT_DTTM)  - pat.BIRTH_DATE) / 365.25) > 2
)
 
 ,CHLGC
 AS
 
  (
      SELECT distinct
      cc.NAME  "COMPONENT"
      ,res_main.RES_INST_VALIDTD_TM "RESULT_DTTM"
      ,resc.COMPONENT_RESULT "RESULT"
      ,zcvs.NAME  "RESULT_STATUS"
      ,resc.COMPONENT_ID
      ,ib_main.*
       ,DENSE_RANK() OVER (PARTITION BY ib_main.MSG_ID,resc.COMPONENT_ID  ORDER BY ib_main.AUDIT_TIME ) rank
        FROM IBMSG ib_main
        INNER JOIN res_db_main res_main ON ib_main.ORDER_PROC_ID = res_main.RES_ORDER_ID
        INNER JOIN order_proc op ON ib_main.ORDER_PROC_ID = op.ORDER_PROC_ID
        INNER JOIN order_results ors ON op.ORDER_PROC_ID = ors.ORDER_PROC_ID
        INNER JOIN res_components resc ON res_main.RESULT_ID = resc.RESULT_ID
--        LEFT OUTER JOIN order_res_comment orcom ON ors.ORDER_PROC_ID = orcom.ORDER_ID --AND ors.ORD_DATE_REAL = orcom.CONTACT_DATE_REAL
        LEFT OUTER JOIN clarity_component cc ON resc.COMPONENT_ID = cc.COMPONENT_ID
        LEFT OUTER JOIN ZC_STAT_ABNORMS zcab ON resc.COMPONENT_ABN_C = zcab.STAT_ABNORMS_C
        LEFT OUTER JOIN ZC_RES_VAL_STATUS zcvs ON res_main.RES_VAL_STATUS_C = zcvs.RES_VAL_STATUS_C

WHERE
       ( op.PROC_ID = 102238 AND resc.COMPONENT_ID IN (1230291518, 1230291512) )
--       AND orcom.RESULTS_CMT LIKE '%interference%'
--       AND orcom.LINE = 1
       
       ORDER BY ib_main.AUDIT_TIME
  )   

,RESMICRO
as
    (

        SELECT DISTINCT
        cc.NAME  "COMPONENT"
      ,res_main.RES_INST_VALIDTD_TM  "RESULT_DTTM"
      ,zcmq.NAME||' '|| zcmg.NAME || ' ' || zcms.NAME  "RESULT"
      ,zcvs.NAME  "RESULT_STATUS"
      ,resc.COMPONENT_ID

       ,ib_main.*
       ,DENSE_RANK() OVER (PARTITION BY ib_main.MSG_ID,resc.COMPONENT_ID  ORDER BY ib_main.AUDIT_TIME ) RANK

        FROM IBMSG ib_main
        INNER JOIN res_db_main res_main ON ib_main.ORDER_PROC_ID = res_main.RES_ORDER_ID
        INNER JOIN res_components resc ON res_main.RESULT_ID = resc.RESULT_ID
        INNER JOIN res_micro_culture res_micro ON resc.RESULT_ID = res_micro.RESULT_ID AND resc.LINE = res_micro.LINE
        LEFT OUTER JOIN clarity_component cc ON resc.COMPONENT_ID = cc.COMPONENT_ID
        LEFT OUTER JOIN ZC_MICRO_GENUS zcmg ON res_micro.culture_GENUS_C = zcmg.MICRO_GENUS_C
        LEFT OUTER JOIN zc_micro_species zcms ON res_micro.CULTURE_SPECIES_C = zcms.MICRO_SPECIES_C
        LEFT OUTER JOIN zc_micro_quantity zcmq ON res_micro.CULTURE_QUANTITY_C = zcmq.MICRO_QUANTITY_C
        LEFT OUTER JOIN ZC_RES_VAL_STATUS zcvs ON res_main.RES_VAL_STATUS_C = zcvs.RES_VAL_STATUS_C
               ORDER BY ib_main.AUDIT_TIME

)


,RESTAIN
as    
    (
      SELECT DISTINCT
      cc.NAME  "COMPONENT"
       ,res_main.RES_INST_VALIDTD_TM "RESULT_DTTM"
       ,zcsq.NAME   ||' '|| dscr. NAME  "RESULT"
        ,zcvs.NAME  "RESULT_STATUS"
        ,resc.COMPONENT_ID

       ,ib_main.*
       ,DENSE_RANK() OVER (PARTITION BY ib_main.MSG_ID,resc.COMPONENT_ID  ORDER BY ib_main.AUDIT_TIME ) rank
        FROM IBMSG ib_main
        INNER JOIN res_db_main res_main ON ib_main.ORDER_PROC_ID = res_main.RES_ORDER_ID
        INNER JOIN res_components resc ON res_main.RESULT_ID = resc.RESULT_ID
        INNER join res_micro_stain res_stain on resc.RESULT_ID = res_stain.RESULT_ID AND resc.LINE = res_stain.LINE
        LEFT OUTER JOIN clarity_component cc ON resc.COMPONENT_ID = cc.COMPONENT_ID
        LEFT OUTER JOIN zc_mic_stain_qty zcsq ON res_stain.MIC_STAIN_QTY_C = zcsq.MIC_STAIN_QTY_C
        LEFT OUTER JOIN zc_mic_stain_dscr dscr ON res_stain.MIC_STAIN_DSCR_C = dscr.MIC_STAIN_DSCR_C
        LEFT OUTER JOIN ZC_RES_VAL_STATUS zcvs ON res_main.RES_VAL_STATUS_C = zcvs.RES_VAL_STATUS_C

 )

,MSGRSLT
AS
(
    SELECT *
    FROM CHLGC
    UNION all
    SELECT *
    FROM RESMICRO
    UNION ALL
    SELECT *
    FROM RESTAIN
)

,IBMFIRSTDISP
AS
(
  SELECT *
  FROM
  (
    SELECT-- *
    ibc_disp.CMD_AUDIT
    ,ibc_disp.MSG_ID
    ,ibc_disp.LINE
    ,ibc_disp.AUDIT_TIME
    ,ibc_disp.AUD_BY_USER_ID
    ,empdisp.NAME
    ,ibc.COMMAND_ABBRV
    ,row_number() OVER (PARTITION BY ibc_disp.MSG_ID ORDER BY ibc_disp.AUDIT_TIME ) "SEQ_NUM"

    FROM IBMSG ibm_first
    INNER JOIN IB_COMMAND_AUDIT ibc_disp ON ibm_first.MSG_ID = ibc_disp.MSG_ID
    INNER JOIN ib_commands ibc ON ibc_disp.CMD_AUDIT = ibc.COMMAND_ID
    LEFT OUTER JOIN clarity_emp empdisp ON ibc_disp.AUD_BY_USER_ID = empdisp.USER_ID
    WHERE 
    ibc_disp.CMD_AUDIT = '104'
  )
  WHERE 
  SEQ_NUM= 1
  )
  
,IBCOMPLT
AS
(
     SELECT DISTINCT
     ord_res.ORDER_PROC_ID
    ,ord_res.RESULT_DATE
    ,ord_res.PAT_ENC_CSN_ID
    ,ord_res.ORD_VALUE
    ,ord_res.COMPONENT_ID
     FROM IBMSG ibm_comp
     LEFT OUTER JOIN ORDER_RESULTS ord_res ON ord_res.ORDER_PROC_ID = ibm_comp.ORDER_PROC_ID
     LEFT OUTER JOIN order_proc op ON ibm_comp.ORDER_PROC_ID = op.ORDER_PROC_ID

    WHERE
    ord_res.RESULT_STATUS_C = 3
    AND ( op.PROC_ID = 102238 AND ord_res.COMPONENT_ID IN (1230291518, 1230291512) OR op.PROC_ID <>102238 )

)

  
,EDREADM
AS
(
   SELECT  *
   FROM 
   (
   SELECT --*
   fed.PAT_ENC_CSN_ID
   ,fed.PAT_ID
   ,ib_readm.EMERGENCY_DTTM

   ,fed.EMERGENCY_ADMISSION_DTTM
   ,fed.PREV_HSP_ENC_ED_YN
   ,fed.PREV_HSP_ENC_HOURDIFF
   ,fed.FIRST_EMERGENCY_DEPARTMENT_ID
   ,trunc(24 * (fed.EMERGENCY_ADMISSION_DTTM - ib_readm.EMERGENCY_DTTM))  "LOS_DATEDIFF_HRS"
       ,row_number() OVER (PARTITION BY fed.PAT_ID ORDER BY fed.EMERGENCY_ADMISSION_DTTM ) "SEQ_NUM"

   FROM IBMSG  ib_readm
   INNER JOIN f_ed_encounters fed ON ib_readm.PAT_ID = fed.PAT_ID
   WHERE
   TRUNC(fed.EMERGENCY_ADMISSION_DTTM) > TRUNC(ib_readm.EMERGENCY_DTTM)
   )
  WHERE 
  SEQ_NUM = 1
)  
,TELENOTE
AS
(
 SELECT *
 FROM
 (
  
  SELECT-- *
  hno.PAT_ENC_CSN_ID
  ,hno.PAT_ID
  ,hno.CURRENT_AUTHOR_ID
  ,note.NOT_FILETM_LOC_DTTM "TELE_ENC_TIME"
  ,emp.NAME  "TELE_ENC_BY"
  ,row_number() OVER (PARTITION BY hno.PAT_ID ORDER BY note.NOT_FILETM_LOC_DTTM ) "SEQ_NUM"

        FROM IBMSG ibmnote
        LEFT OUTER JOIN HNO_INFO hno ON ibmnote.PAT_ID = hno.PAT_ID
        INNER JOIN note_enc_info note ON hno.NOTE_ID = note.NOTE_ID
--         RSN_FOR_VISIT_PREV rsn
        LEFT OUTER JOIN clarity_emp emp ON hno.CURRENT_AUTHOR_ID = emp.USER_ID
        WHERE
        hno.IP_NOTE_TYPE_C = 36
        AND emp.PROV_ID IN ('31723', '31842', '31059' , '453463', '453465', '455150')
        AND note.NOT_FILETM_LOC_DTTM >=  ibmnote.EMERGENCY_DTTM
)
where
SEQ_NUM = 1


)

SELECT
ib_main.MSG_ID
,ib_main.ORDER_PROC_ID
,ib_main.PAT_ENC_CSN_ID
,ib_main.PAT_MRN_ID
,ib_main.EMERGENCY_DTTM "EMERGENCY_ADMIT_DTTM"
,ib_main.COMMAND_ABBRV
,ib_main.AUDIT_TIME      "REVIEWED_DTTM"
,ib_main.NAME            "REVIEWED_BY"
,ib_first.COMMAND_ABBRV
,ib_first.AUDIT_TIME       "FIRST_DISPLAYED_DTTM"
,ib_first.NAME     "FIRST_DISPLAYED_BY"
,ib_main.DESCRIPTION
,ib_main.COMPONENT
,ib_main.RESULT_DTTM
,ib_main.RESULT
,ib_main.RESULT_STATUS
,cmplt.RESULT_DATE   "FINAL_RESULT_DTTM"
,cmplt.ORD_VALUE     "FINAL_RESULT"
,DISCHMEDS.ANTIBIOTICS
,tel.TELE_ENC_BY
,tel.TELE_ENC_TIME
,edre.EMERGENCY_ADMISSION_DTTM
,CASE WHEN edre.LOS_DATEDIFF_HRS < 73 THEN 'Y' ELSE 'N' END "ED_ENCOUNTER_72HR"

FROM MSGRSLT ib_main
INNER JOIN IBMFIRSTDISP ib_first ON ib_main.MSG_ID = ib_first.MSG_ID
INNER JOIN patient pat ON ib_main.PAT_ID = pat.pat_id
LEFT OUTER JOIN EDREADM edre ON ib_main.PAT_ID = edre.PAT_ID
LEFT OUTER JOIN TELENOTE tel ON ib_main.PAT_ID = tel.PAT_ID
LEFT OUTER JOIN IBCOMPLT cmplt ON ib_main.ORDER_PROC_ID = cmplt.ORDER_PROC_ID AND cmplt.COMPONENT_ID = ib_main.COMPONENT_ID

 OUTER apply 
   (
    SELECT 
    om.PAT_ENC_CSN_ID
    ,LISTAGG(cm.NAME||' ') WITHIN GROUP(ORDER BY cm.NAME) ANTIBIOTICS   

    FROM ORDER_MED om
    INNER JOIN order_medinfo omi ON om.ORDER_MED_ID = omi.ORDER_MED_ID
    LEFT OUTER JOIN clarity_medication cm ON omi.DISPENSABLE_MED_ID = cm.MEDICATION_ID
    
    WHERE
    om.ORDERING_MODE_C = 1 
    AND cm.THERA_CLASS_C = 41
    AND ib_main.PAT_ENC_CSN_ID = om.PAT_ENC_CSN_ID

   group by om.PAT_ENC_CSN_ID

)DISCHMEDS   
