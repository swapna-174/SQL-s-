
SELECT distinct
pat.PAT_NAME
,pat.PAT_MRN_ID
,pat.BIRTH_DATE AS DOB
,har.HSP_ACCOUNT_ID  AS hsp_account_id
, hsp.HOSP_ADMSN_TIME AS admit_date

,adm_type.NAME  as admission_type
,ADMSERV.cons_admit_service AS admit_service
,ser.PROV_NAME     AS admit_prov_name
,zc_ha.NAME as hsp_service
,zc_src.name as xfer_source_name
,ADMSERV.cons_admit_dx AS admit_dx
,pl_edg.DX_NAME AS primaryprob_dx
,cpt.CPT_CODE  AS cpt_code
,zrsn.REASON_VISIT_NAME AS visit_reason
,hsp.PAT_ENC_CSN_ID  AS csn
,pat.DEATH_DATE 
,zc_pat.NAME  AS patient_status

FROM ORDER_STATUS os 
LEFT OUTER JOIN ORDER_PROC op ON os.ORDER_ID = op.ORDER_PROC_ID
LEFT OUTER JOIN HNO_INFO hno ON os.PROCEDURE_NOTE_ID = hno.NOTE_ID
LEFT OUTER JOIN NOTE_ENC_INFO nenc ON hno.NOTE_ID = nenc.NOTE_ID
LEFT OUTER join PAT_ENC_HSP hsp  ON hsp.PAT_ENC_CSN_ID = op.PAT_ENC_CSN_ID
INNER JOIN PATIENT pat ON hsp.PAT_ID = pat.PAT_ID
left outer join zc_patient_status zc_pat on pat.PAT_STATUS_C = zc_pat.patient_status_c
left outer join hsp_account har on hsp.HSP_ACCOUNT_ID = har.hsp_account_id
LEFT OUTER JOIN hsp_account_3 har3 ON har.HSP_ACCOUNT_ID = har3.HSP_ACCOUNT_ID
LEFT OUTER JOIN HSP_ACCT_CPT_CODES cpt ON har.HSP_ACCOUNT_ID = cpt.HSP_ACCOUNT_ID AND cpt.LINE = 1
left outer join ZC_PRIM_SVC_HA zc_ha on har.PRIM_SVC_HA_C = zc_ha.prim_svc_ha_c
LEFT OUTER JOIN ZC_HOSP_ADMSN_TYPE adm_type ON har3.ADMIT_TYPE_EPT_C = adm_type.HOSP_ADMSN_TYPE_C
left outer join ZC_TRANSFER_SRC_HA zc_src on har.TRANSFER_SRC_HA_C = zc_src.transfer_src_ha_c
LEFT OUTER JOIN PAT_ENC_HOSP_PROB prob ON hsp.PAT_ENC_CSN_ID = prob.PAT_ENC_CSN_ID AND prob.PRINCIPAL_PROB_YN = 'Y'
LEFT outer JOIN problem_list pl ON prob.PROBLEM_LIST_ID = pl.PROBLEM_LIST_ID
LEFT OUTER JOIN clarity_edg pl_edg ON pl_edg.DX_ID = pl.DX_ID
LEFT OUTER JOIN PAT_ENC_RSN_VISIT rsn ON rsn.PAT_ENC_CSN_ID = hsp.PAT_ENC_CSN_ID AND rsn.LINE = 1
LEFT OUTER JOIN CLARITY_SER ser ON hsp.ADMISSION_PROV_ID = ser.PROV_ID
LEFT OUTER JOIN CL_RSN_FOR_VISIT zrsn ON zrsn.REASON_VISIT_ID = rsn.ENC_REASON_ID 
    OUTER apply  
     (
             SELECT  
         adt.PAT_ENC_CSN_ID
        ,zps.NAME AS cons_admit_service
        ,edg.DX_NAME  AS cons_admit_dx
        FROM CLARITY_ADT adt
        LEFT OUTER JOIN HSP_ACCT_ADMIT_DX adm_dx ON hsp.HSP_ACCOUNT_ID = adm_dx.HSP_ACCOUNT_ID AND line = 1
        LEFT OUTER JOIN CLARITY_EDG edg ON adm_dx.ADMIT_DX_ID = edg.DX_ID
        LEFT OUTER JOIN CLARITY_DEP dep ON adt.DEPARTMENT_ID = dep.DEPARTMENT_ID
        LEFT OUTER JOIN ZC_PAT_SERVICE zps ON zps.HOSP_SERV_C =  adt.PAT_SERVICE_C
        WHERE 
         adt.EVENT_TYPE_C = 1  ------admission Service
         AND hsp.PAT_ENC_CSN_ID = adt.PAT_ENC_CSN_ID
     
     
     )ADMSERV  
     
    WHERE 
   TRUNC(hsp.HOSP_ADMSN_TIME) >= EPIC_UTIL.EFN_DIN ('{?Start_Date}')
   AND TRUNC(hsp.HOSP_ADMSN_TIME) <= EPIC_UTIL.EFN_DIN ('{?End_Date}') --- Weekly run report need between dynamic date range
   --    trunc(hsp.HOSP_ADMSN_TIME) >= '1-oct-2020'
--    AND  trunc(hsp.HOSP_ADMSN_TIME) <= '10-oct-2020'
--   AND  nenc.AUTHOR_SERVICE_C = 162
   and (nenc.AUTHOR_SERVICE_C IN {?Service}  OR '0' IN {?Service})
