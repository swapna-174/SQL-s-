WITH DELIV_CHG
AS
(   
   
    SELECT --*
     ucl.PATIENT_ID  "PAT_ID"
    ,ucl.SERVICE_DATE_DT  "SERVICE_DATE"
    ,ucl.EPT_CSN        "ENCOUNTER_CSN"
    ,ucl2.CREATED_DEPT_ID "DEPT"
    ,ucl.PROCEDURE_ID   "PROC_ID"
    ,ucl.HOSPITAL_ACCOUNT_ID  "HAR"
    ,ucl.PROC_DESCRIPTION  "DESCRIPTION"
    
    FROM CLARITY_UCL ucl 
    LEFT OUTER join clarity_ucl_2 ucl2 ON ucl.UCL_ID = ucl2.UCL_ID

    WHERE
      ucl2.CREATED_DEPT_ID IN (1000108027, 1000108031) 
      AND ucl.PROV_BILL_AREA_C in (370,108)
      AND ucl.COST_CENTER_ID = 297
--      AND ucl.SERVICE_DATE_DT >='1-mar-2021'
      AND ucl.SERVICE_DATE_DT >= EPIC_UTIL.EFN_DIN('{?Begin Date}') 
      AND ucl.SERVICE_DATE_DT <= EPIC_UTIL.EFN_DIN('{?End Date}') 
      
  UNION ALL
  
  SELECT --*
     hsp.pat_id   "PAT_ID"
    ,har.SERVICE_DATE  "SERVICE_DATE"
    ,har.PAT_ENC_CSN_ID  "ENCOUNTER_CSN"
    ,har.DEPARTMENT  "DEPT"
    ,har.PROC_ID     "PROC_ID"
    ,har.HSP_ACCOUNT_ID  "HAR"
    ,har.PROCEDURE_DESC "DESCRIPTION"

  FROM HSP_TRANSACTIONS har
  INNER JOIN pat_enc_hsp hsp ON har.HSP_ACCOUNT_ID = hsp.HSP_ACCOUNT_ID
  WHERE
   har.UB_REV_CODE_ID = 720
   AND har.DEPARTMENT IN (1000108027, 1000108031)
--   AND har.TX_POST_DATE >='1-mar-2021'
   AND har.TX_POST_DATE >= EPIC_UTIL.EFN_DIN('{?Begin Date}') 
   AND har.TX_POST_DATE <= EPIC_UTIL.EFN_DIN('{?End Date}') 

)


SELECT --*
a.PAT_NAME
,a.PAT_MRN
,a.HSP_ACCOUNT_ID
,a.PROVIDER
,a.DATE_OF_DELIVERY
,a.ANESTH_CONC
,a.INDUCT_CONC
,a.LACER_CONC
,a.EPISIO_CONC
,a.AUGMENT_CONC
,a.CERVRIPE_CONC
,SUM(VLEVEL) "VAG_LEVEL"
,SUM(LABOR)  "LABOR_HOURS"
FROM 
(

    SELECT distinct
    pat_mom.PAT_NAME     "PAT_NAME"
    ,pat_mom.PAT_MRN_ID   "PAT_MRN"
    ,dep.DEPARTMENT_NAME
    ,vob.PROV_NAME        "PROVIDER"
    ,vob.DEL_DTTM         "DATE_OF_DELIVERY"
    ,zcdt.NAME            "DELIVERY_TYPE" 
    ,vob.ANESTH_CONC
    ,vob.INDUCT_CONC
    ,vob.LACER_CONC
    ,vob.EPISIO_CONC
    ,vob.AUGMENT_CONC
    ,vob.CERVRIPE_CONC
--    ,vob.MOM_ID
    ,hsp.HSP_ACCOUNT_ID
--    ,delv.PROC_ID
--    ,delv.DESCRIPTION
    ,CASE WHEN delv.DESCRIPTION LIKE '%VAGINAL LEVEL%' THEN 1 ELSE 0 END "VLEVEL"
    ,CASE WHEN delv.DESCRIPTION LIKE '%LABOR PER HOUR%' THEN 1 ELSE 0 END "LABOR"
    
    FROM V_OB_DEL_RECORDS vob
    LEFT OUTER JOIN pat_enc_hsp hsp ON vob.MOM_CSN = hsp.PAT_ENC_CSN_ID
    LEFT OUTER JOIN DELIV_CHG delv ON hsp.HSP_ACCOUNT_ID = delv.HAR
    LEFT OUTER JOIN ZC_DELIVERY_TYPE zcdt ON vob.DELMETH_C = zcdt.DELIVERY_TYPE_C
    INNER JOIN patient pat_mom ON vob.MOM_ID = pat_mom.PAT_ID
    LEFT OUTER JOIN clarity_dep dep ON vob.DEPT_ID = dep.DEPARTMENT_ID
    WHERE
--    TRUNC(vob.DEL_DTTM) >= '1-mar-2021'
     TRUNC(vob.DEL_DTTM) >= EPIC_UTIL.EFN_DIN('{?Begin Date}') 
    AND TRUNC(vob.DEL_DTTM) <= EPIC_UTIL.EFN_DIN('{?End Date}')

    AND vob.DELMETH_C IN ('250','255','258', '254')
    AND vob.DEPT_ID IN (1000108027, 1000108031,439496405)
)a
GROUP BY  a.PAT_NAME,a.PAT_MRN,a.HSP_ACCOUNT_ID,a.PROVIDER,a.DATE_OF_DELIVERY,a.ANESTH_CONC
,a.INDUCT_CONC
,a.LACER_CONC
,a.EPISIO_CONC
,a.AUGMENT_CONC
,a.CERVRIPE_CONC

ORDER BY  a.PAT_NAME

--SELECT *
--FROM VAG_DELIV ppl
--where
--
-- NOT exists (            SELECT
--                                pdx.HAR
--                         FROM
--                                DELIV_CHG pdx
--                         WHERE
--                                ppl.HSP_ACCOUNT_ID = pdx.HAR
--
--           )


