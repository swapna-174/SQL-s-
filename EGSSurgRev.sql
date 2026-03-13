SELECT distinct
pat.PAT_NAME
,pat.PAT_MRN_ID
,pat.BIRTH_DATE AS DOB
,har.hsp_account_id AS hsp_account_id
, adm_type.NAME AS admission_type
, cpt.CPT_CODE AS cpt_code
, loc_or.LOC_NAME as or_location
, ser_or.PROV_NAME as or_room
, orl.LOG_ID  AS log_id
, zc_orcl.NAME as case_class
, orl.SURGERY_DATE as surgery_date
, zc_or.name as surgical_service
, orp_pc.PROC_NAME as or_proc_name
, ser.PROV_ID AS prov_id
, ser.PROV_NAME as primary_provider
, zc_svc.NAME as allowed_service
, or_preop.PRE_OP_DX AS pre_op_dx
, edg.CURRENT_ICD10_LIST as pre_op_icd10
, edg.DX_NAME as pre_op_name
, edg_adm_dx.CURRENT_ICD10_LIST as admit_icd10
, edg_adm_dx.DX_NAME as admit_dx_name
, cl_icd.PROC_MASTER_NM as icd_procedure_code
, cl_icd.ICD_PX_NAME as icd_procedure_description
,zc_pat.NAME  AS patient_status
,pat.DEATH_DATE 

from pat_enc_hsp peh
INNER JOIN patient pat ON peh.PAT_ID = pat.PAT_ID
left outer join zc_patient_status zc_pat on pat.PAT_STATUS_C = zc_pat.patient_status_c
left join PAT_OR_ADM_LINK poal on peh.PAT_ENC_CSN_ID = poal.OR_LINK_CSN
left join HSP_ACCOUNT har ON peh.HSP_ACCOUNT_ID = har.HSP_ACCOUNT_ID
LEFT OUTER JOIN hsp_account_3 har3 ON har.HSP_ACCOUNT_ID = har3.HSP_ACCOUNT_ID
LEFT OUTER JOIN ZC_HOSP_ADMSN_TYPE adm_type ON har3.ADMIT_TYPE_EPT_C = adm_type.HOSP_ADMSN_TYPE_C
left join HSP_ACCT_PX_LIST px on har.hsp_account_id = px.hsp_account_id and px.LINE = 1
left join CL_ICD_PX cl_icd on px.FINAL_ICD_PX_ID = cl_icd.icd_px_id
left join or_case orc on poal.case_id = orc.OR_CASE_ID
left join OR_LOG orl on poal.LOG_ID = orl.LOG_ID
left join preference_cards pcard on orc.OR_CASE_ID = pcard.CASE_ID AND pcard.LINE = 1
left join or_proc orp_pc on pcard.PREF_CARD_ID = orp_pc.OR_PROC_ID
left join clarity_ser ser on orl.PRIMARY_PHYS_ID = ser.PROV_ID
left join or_case_dx_code or_dx on orc.OR_CASE_ID = or_dx.OR_CASE_ID and or_dx.LINE = '1'
left join clarity_edg edg on or_dx.DX_ID = edg.DX_ID
left outer join ZC_OR_SERVICE zc_or on orc.SERVICE_C = zc_or.service_c
left join or_case_preopdx or_preop on orc.OR_CASE_ID = or_preop.or_case_id and or_preop.LINE = '1'
left join clarity_ser ser_or on orc.OR_ID = ser_or.PROV_ID
left join or_loc loc on orl.loc_id = loc.loc_id
left join clarity_loc loc_or on loc.LOC_ID = loc_or.loc_id
left join zc_or_case_class zc_orcl on orc.CASE_CLASS_C = zc_orcl.CASE_CLASS_C
left outer join allowed_services alw_svc on ser.PROV_ID = alw_svc.PROV_ID and alw_svc.ALLOWED_SERVICE_C = '162'
left outer join ZC_PRIM_SVC_HA zc_svc on alw_svc.ALLOWED_SERVICE_C = zc_svc.PRIM_SVC_HA_C
left join HSP_ACCT_ADMIT_DX adm_dx on har.HSP_ACCOUNT_ID = adm_dx.hsp_account_id
left join clarity_edg edg_adm_dx on adm_dx.ADMIT_DX_ID = edg_adm_dx.dx_id
LEFT JOIN HSP_ACCT_CPT_CODES cpt ON har.HSP_ACCOUNT_ID = cpt.HSP_ACCOUNT_ID AND cpt.LINE = 1
left join or_case_all_proc orp_all on orc.or_case_id = orp_all.or_case_id
left join OR_PROC orpall on orp_all.OR_PROC_ID = orpall.or_proc_id
where 
 ( trunc(orl.SURGERY_DATE) >= EPIC_UTIL.EFN_DIN ('{?From Date}')  
    and trunc(orl.SURGERY_DATE) <= EPIC_UTIL.EFN_DIN ('{?To Date}'))
--trunc(orl.SURGERY_DATE) >= '1-oct-2020'
--AND trunc(orl.SURGERY_DATE) <= '10-oct-2020'
AND  orc.CANCEL_REASON_C is null
and ser.PROV_TYPE = 'Physician'
and orp_pc.PROC_NAME LIKE '%Emergency General Surgery%'
and edg.DX_ID NOT IN ('107561', '92061', '614469', '614469', '588105', '588105', '588105', '205383')
and (  edg.DX_GROUP_ID NOT IN ('21', '37') 
or edg.DX_GROUP_ID is null)

