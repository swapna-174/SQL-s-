WITH PPLCPT
AS
(
    SELECT  distinct
    orl.SURGERY_DATE
    ,pat.PAT_MRN_ID
    ,orlp.PROC_DISPLAY_NAME
    ,primary_phys_id
    ,cpt.HSP_ACCOUNT_ID
    ,orl_diag.PREOP_DX_CODES_ID "PRE_OP_DX_CODE"
    ,edg.DX_NAME "PRE_OP_DX"
    ,pat_hsp.DEPARTMENT_ID
    ,orl.LOG_ID
    ,pat.PAT_ID
    ,cpt.CPT_CODE
--    ,cpt.CPT_CODE_DATE
    FROM HSP_ACCT_CPT_CODES cpt                        ------ removed '0184T',
    --INNER JOIN hsp_account hsp ON cpt.HSP_ACCOUNT_ID = hsp.HSP_ACCOUNT_ID
    INNER JOIN pat_enc_hsp pat_hsp ON cpt.HSP_ACCOUNT_ID = pat_hsp.HSP_ACCOUNT_ID
    INNER JOIN pat_or_adm_link pat_or ON pat_hsp.PAT_ENC_CSN_ID = pat_or.OR_LINK_CSN
    INNER JOIN or_log orl ON pat_or.LOG_ID = orl.LOG_ID
    LEFT OUTER JOIN or_log_preop_diags orl_diag ON orl.LOG_ID = orl_diag.LOG_ID AND orl_diag.line = 1
    LEFT OUTER JOIN clarity_edg edg ON orl_diag.PREOP_DX_CODES_ID = edg.DX_ID
    LEFT OUTER JOIN or_log_all_proc orlp ON orl.LOG_ID = orlp.LOG_ID AND orlp.line = 1
    INNER JOIN patient pat ON pat_hsp.PAT_ID = pat.PAT_ID
    
    WHERE
    cpt.CPT_CODE IN ('19101',
    '19100',
    '19304',
    '19300',
    '19307',
    '19301',
    '19303',
    '19302',
    '19305',
    '38500',
    '21012',
    '57500',
    '48148',
    '44800',
    '44820',
    '49250',
    '46320',
    '21930',
    '21931',
    '28039',
    '27043',
    '23075',
    '49205',
    '49203',
    '49204',
    '38531',
    
    '38525',
    '38530',
    '38900',
    '38740',
    '38745',
    '38510',
    '38564',
    '38780',
    '38747',
    '38765',
    '38760',
    '19285',
    '19125')
    AND TRUNC(orl.SURGERY_DATE) >= '1-jul-2019'
    --AND pat_hsp.HSP_ACCOUNT_ID = 438408015
   AND pat.PAT_MRN_ID = '3349438'
--    AND pat.PAT_ID = 'Z2079344'
)

--,PREOP
--AS
--(
   SELECT DISTINCT
   enc.PAT_ID
   ,enc.PAT_ENC_CSN_ID
   ,enc.CONTACT_DATE
   ,prc.PRC_NAME
   ,prc.PRC_ID
   ,enc.VISIT_PROV_ID
   ,enc.REFERRAL_SOURCE_ID
   FROM PPLCPT ppl
   INNER JOIN PAT_ENC enc ON ppl.PAT_ID = enc.PAT_ID
   LEFT OUTER JOIN clarity_prc prc ON enc.APPT_PRC_ID = prc.PRC_ID

   WHERE
enc.CONTACT_DATE < ppl.SURGERY_DATE
AND enc.CONTACT_DATE > ppl.SURGERY_DATE-30  ---- 30 days prior
AND enc.ENC_TYPE_C = 3
AND( enc.VISIT_PROV_ID =  ppl.primary_phys_id
        OR enc.REFERRAL_SOURCE_ID = ppl.primary_phys_id)

AND prc.PRC_NAME LIKE '%ASSESS%'
--AND    (enc.REFERRAL_SOURCE_ID = ppl.primary_phys_id AND enc.ENC_TYPE_C = 3)
)
--
SELECT *
FROM 
(
    SELECT distinct
--    enc.PAT_ID
     ppl.pat_mrn_id
    ,enc.PAT_ENC_CSN_ID
    ,enc.CONTACT_DATE
    ,ppl.SURGERY_DATE
    ,ppl.SURGERY_DATE-enc.CONTACT_DATE  "DAYS_ENCOUNTER_TO_SURGERY"
    --,enc.APPT_TIME
    --,enc.ENC_CLOSE_TIME
    --,COALESCE(enc.APPT_TIME,enc.ENC_CLOSE_TIME) "ENC_DTTM"
--    ,enc.ENC_TYPE_C
    ,zcdet.NAME  "ENC_TYPE"
    
    ,edg.DX_NAME  "ENC_DX"
    ,edg.DX_ID
    ,enc.VISIT_PROV_ID  
    ,enc.REFERRAL_SOURCE_ID
    ,op.PROC_PERF_PROV_ID
    ,ser.PROV_ID  "SURGEON_ID"
    ,ser.PROV_NAME "SURGEON_NM"
    ,enc.DEPARTMENT_ID
    ,dep.DEPARTMENT_NAME
    ,enc.HSP_ACCOUNT_ID
--    ,enc.EFFECTIVE_DEPT_ID
    ,prc.PRC_NAME
    ,op.DESCRIPTION
    ,ppl.CPT_CODE
    ,ppl.LOG_ID
    ,ppl.PRE_OP_DX
    ,ppl.PRE_OP_DX_CODE
--    ,enc.APPT_PRC_ID
        ,row_number() OVER (PARTITION BY enc.PAT_ID ORDER BY COALESCE(enc.APPT_TIME,enc.ENC_CLOSE_TIME) desc) "SEQ_NUM"
    FROM PPLCPT ppl 
    INNER JOIN PAT_ENC enc ON ppl.PAT_ID = enc.PAT_ID
    --LEFT outer JOIN PREOP prp ON enc.PAT_ID = prp.PAT_ID
    LEFT OUTER JOIN PAT_ENC_DX encdx ON enc.PAT_ENC_CSN_ID = encdx.PAT_ENC_CSN_ID AND encdx.LINE = 1
    LEFT OUTER JOIN clarity_edg edg ON encdx.DX_ID = edg.DX_ID
    LEFT OUTER JOIN clarity_prc prc ON enc.APPT_PRC_ID = prc.PRC_ID
    LEFT OUTER JOIN clarity_dep dep ON dep.DEPARTMENT_ID = enc.DEPARTMENT_ID
    LEFT OUTER JOIN clarity_ser ser ON ppl.primary_phys_id = ser.PROV_ID
    LEFT OUTER JOIN order_proc op ON enc.PAT_ENC_CSN_ID = op.PAT_ENC_CSN_ID AND op.ORDER_TYPE_C = 1070001 
    LEFT OUTER JOIN ZC_DISP_ENC_TYPE zcdet ON enc.ENC_TYPE_C = zcdet.DISP_ENC_TYPE_C
    
    WHERE
    enc.CONTACT_DATE < ppl.SURGERY_DATE
    AND enc.CONTACT_DATE > ppl.SURGERY_DATE-90  ---- 30 days prior
    AND 
        ((op.PROC_PERF_PROV_ID = ppl.primary_phys_id
        OR enc.VISIT_PROV_ID =  ppl.primary_phys_id
        OR enc.REFERRAL_SOURCE_ID = ppl.primary_phys_id)
        OR (enc.enc_type_c = 101 AND edg.DX_ID = 545717)
        )
    AND enc.CANCEL_REASON_C IS NULL
    AND enc.ENC_TYPE_C NOT IN (109,117,61,70,105,99,2507,3)   ---- History
    AND encdx.dx_id IS NOT NULL   
    
      AND (encdx.DX_ID = ppl.PRE_OP_DX_CODE OR ppl.PRE_OP_DX_CODE IS NULL)
    --ORDER BY enc.EFFECTIVE_DATE_dttm DESC, enc.PAT_ID
)
WHERE 
 SEQ_NUM = 1   

SELECT *
FROM PAT_ENC enc
WHERE
enc.PAT_ENC_CSN_ID = 30110485313