
/* 2020 Peds Hospital Survey
K12.b	
*/
SELECT COUNT (DISTINCT   mrn ) unique_pats   FROM   (      -- USE THIS LINE TO GET SUMMARY - COMMENT OUT FOR DETAILS

SELECT DISTINCT
      ha.hsp_account_id, ha.hsp_account_name, ha.adm_date_time, ha.disch_date_time 
     , pat.pat_mrn_id "MRN" 
     , TO_CHAR(pat.birth_date, 'MM/DD/YYYY') "Patient DOB"
     , TRUNC(MONTHS_BETWEEN(TRUNC(COALESCE( pe.hosp_admsn_time, peh.hosp_admsn_time, ha.adm_date_time )),TRUNC(pat.birth_date))/12) "Admit Age"
     , ser.prov_id, ser.prov_name "Performing Prov", z.name 
     , ser2.prov_id, ser2.prov_name  AS "Billing Prov", z2.name
     , '*TDL*'
    --, tdl.proc_id
     , tdl.cpt_code 
     , eap.proc_name

  FROM clarity.hsp_account ha
  JOIN clarity.hsp_acct_sbo sbo ON sbo.hsp_account_id = ha.hsp_account_id
     AND sbo.sbo_har_type_c = 2 --> Prof Billing
  JOIN clarity.patient pat ON pat.pat_id = ha.pat_id
  LEFT JOIN clarity.pat_enc pe ON pe.pat_enc_csn_id = ha.prim_enc_csn_id
  LEFT JOIN clarity.pat_enc_hsp peh ON peh.pat_enc_csn_id = ha.prim_enc_csn_id     
     
  JOIN clarity.clarity_tdl_tran tdl ON tdl.hsp_account_id = ha.hsp_account_id  
     AND tdl.tran_type = '1' --> Charge 
     AND tdl.type = 1 and tdl.detail_type = 1
  JOIN clarity_eap eap ON eap.proc_id = tdl.proc_id
-- Performing Provider
  JOIN clarity.clarity_ser ser ON ser.prov_id = tdl.performing_prov_id
  JOIN clarity.clarity_ser_spec spec ON spec.prov_id = ser.prov_id        AND spec.SPECIALTY_C = 43
  JOIN clarity.zc_specialty z ON z.specialty_c = spec.specialty_c
-- Billing Provider
  JOIN clarity.clarity_ser ser2 ON ser2.prov_id =  tdl.billing_provider_id
  JOIN clarity.clarity_ser_spec spec2 ON spec2.prov_id = ser2.prov_id
  JOIN clarity.zc_specialty z2 ON z2.specialty_c = spec2.specialty_c

 WHERE   ha.loc_id = 100000
   AND ha.acct_billsts_ha_c NOT IN (99, 40) -- Exclude combined and voided accounts  
 -- Peds age must be less than 18 at time of admission
   AND TRUNC(MONTHS_BETWEEN(TRUNC(COALESCE( pe.hosp_admsn_time, peh.hosp_admsn_time, ha.adm_date_time )),TRUNC(pat.birth_date))/12) < 18  
 -- Get encounters 
   AND coalesce( pe.hosp_dischrg_time, peh.hosp_disch_time, ha.disch_date_time, peh.hosp_admsn_time, pe.hosp_admsn_time, ha.adm_date_time)
                    BETWEEN '01-JAN-2020' AND '01-JAN-2023'
-- and (tdl.performing_prov_id = '10522' or  tdl.billing_provider_id = '10522' )
  AND tdl.cpt_code IN ('50220',
'50225',
'50230',
'50234',
'50236',
'50240',
'50543',
'50546',
'50548',
'50220'
)
--
  ORDER BY HSP_ACCOUNT_NAME, ADM_DATE_TIME   
 ) 

