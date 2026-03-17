/*
2023 Survey
.	Of the total vaccine eligible  asthma patients (see code list) being treated by your Pediatric Pulmonology and Lung Surgery program between October 1, and December 31, 2022, what percentage received seasonal influenza vaccine (at your facility or elsewhere) during that time period or earlier that season 
J15.	Of the total vaccine eligible  asthma patients (see code list; include any diagnosis of asthma principal or secondary) being treated by your Pediatric Pulmonology and Lung Surgery program between October 1, and December 31, 2022, what percentage received seasonal influenza vaccine (at your facility or elsewhere) during that time period or earlier that season?*/

SELECT 'J15' AS QUESTION, COUNT(DISTINCT PATIENT_MRN) MRNS, COUNT(IMMUNE_DATE) Vacinated
       , (ROUND(COUNT(IMMUNE_DATE) / COUNT(DISTINCT PATIENT_MRN),2)*100) || '%' "PERCENT"
  FROM (
SELECT DISTINCT
      ha.HSP_ACCOUNT_ID
     , pat.PAT_ID
     , pat.pat_mrn_id PATIENT_MRN
     , ha.hsp_account_name 
     , zpc.NAME "Pat Class"
     , ha.PRIM_ENC_CSN_ID
     , loc.LOC_NAME "Location"
     , zet.NAME "Enc Type"
--     , ser.PROV_NAME Provider
       --, peh.adt_pat_class_c , zpc.name "Patient Class" 
       -- , ha.acct_basecls_ha_c 
     , coalesce(peh.hosp_admsn_time, pe.hosp_admsn_time, ha.adm_date_time) Admit_DT
     , coalesce(peh.hosp_disch_time, pe.hosp_dischrg_time, ha.disch_date_time ) DC_Date 
     
     , to_char(pat.birth_date, 'MM/DD/YYYY') "Patient DOB"
     , TRUNC(MONTHS_BETWEEN(trunc(coalesce( pe.hosp_admsn_time, peh.hosp_admsn_time, ha.adm_date_time )),trunc(pat.birth_date))/12) "Admit Age Years"
     , TRUNC(MONTHS_BETWEEN(trunc(coalesce( pe.hosp_admsn_time, peh.hosp_admsn_time, ha.adm_date_time )),trunc(pat.birth_date))) "Admit Age Months"
     , zx.NAME Sex
    --, ser.prov_id
     , coalesce(ser.prov_name, ' ') "AttendingProv"
     , coalesce(z.name, ' ') "AttendingSpecialty" 
     , edg.ref_bill_code "Primary DX Code"
     , edg.DX_NAME "Final Primary DX"
     
     ,ContraIndicator.ContraIndicDx
     ,FluVacc.ImmID
     ,to_char(FluVacc.ImmDate,'MM/DD/YYYY') IMMUNE_DATE
   
  FROM hsp_account ha
  JOIN hsp_acct_sbo sbo ON sbo.hsp_account_id = ha.hsp_account_id
    AND sbo.sbo_har_type_c = 0 -- Mixed
    --  2 --> Prof Billing   
 
  JOIN patient pat ON pat.pat_id = ha.pat_id
  LEFT JOIN pat_enc pe ON pe.pat_enc_csn_id = ha.prim_enc_csn_id
  LEFT JOIN pat_enc_2 pe2 ON pe.PAT_ENC_CSN_ID = pe2.PAT_ENC_CSN_ID
  LEFT JOIN pat_enc_hsp peh ON peh.pat_enc_csn_id = ha.prim_enc_csn_id 
  
  LEFT JOIN zc_pat_class zpc ON zpc.adt_pat_class_c = pe2.adt_pat_class_c
  LEFT JOIN zc_acct_class_ha ac ON ac.acct_class_ha_c = ha.acct_class_ha_c   
  LEFT JOIN ZC_DISP_ENC_TYPE zet on pe.ENC_TYPE_C = zet.DISP_ENC_TYPE_C
  LEFT JOIN ZC_PRIM_SVC_HA zps ON ha.PRIM_SVC_HA_C = zps.PRIM_SVC_HA_C
  
  LEFT JOIN clarity_loc loc on ha.LOC_ID = loc.LOC_ID

-- Provider
   LEFT JOIN clarity_ser ser  ON ser.prov_id = ha.attending_prov_id           
   LEFT JOIN clarity_ser_spec spec ON spec.prov_id = ser.PROV_ID AND spec.line = 1 -- doesn't have to be the primary specialty
   LEFT JOIN zc_specialty z ON z.specialty_c = spec.specialty_c
    
   LEFT JOIN zc_sex zx on pat.SEX_C = zx.RCPT_MEM_SEX_C
   
 -- DX codes 
   JOIN hsp_acct_dx_list dx on dx.hsp_account_id = ha.hsp_account_id  AND dx.LINE = 1  --PRIMARY/PRINCIPLE dx - final from HAR
   JOIN clarity_edg edg on edg.dx_id = dx.dx_id

-----GET FLU VACCINE INFO DURING TIME PERIOD (IF EXISTS)  
   OUTER APPLY ( SELECT vac.IMMUNZATN_ID ImmID
                      , vac.IMMUNE_DATE ImmDate
                 FROM immune vac
                    left outer join CLARITY_IMMUNZATN imm on vac.IMMUNZATN_ID = imm.IMMUNZATN_ID
                 WHERE vac.immunzatn_id IN ('21','23','34','35','38',
                                            '39','66','83','84',
                                            '85','86','87','21021','21023',
                                            '21083','21121',
                                            '21221','21222',
                                            '21321','210212',
                                            '211212','213212')
                        AND vac.PAT_ID = pat.PAT_ID
                        AND TRUNC(IMMUNE_DATE) BETWEEN '1-sep-2022' and '31-DEc-2022'  --per David 
                        AND immnztn_status_c = 1   --given
                   ) FluVacc

-----GET DX (not necessarily primary Dx) OF ANY PATIENT WITH A COMPLICATION IN 1st TRIMESTER OF PREGNANCY IN THE TREATMENT PERIOD --THESE CANNOT GET FLU VACCINE  
----- AND history of Guill Barre, allergy to eggs/vaccine/or components, and  long term (current) use of aspirin.
   OUTER APPLY( SELECT distinct edg_contra.REF_BILL_CODE ContraIndicDx
                FROM  hsp_acct_dx_list dx_contra  
                      JOIN clarity_edg edg_contra on dx_contra.DX_ID = edg_contra.dx_id 
                WHERE dx_contra.hsp_account_id = ha.hsp_account_id 
                    AND edg_contra.ref_bill_code IN ('O09.01','O09.211','O09.31','O09.41','O09.511','O09.521','O09.611','O09.621','O09.891','O09.91','O09.A1','O10.011','O10.111','O10.411'
                            ,'O10.911','O11.1','O12.01','O12.11','O12.21','O13.1','O16.1','O22.01','O22.11','O22.21','O22.31','O22.41','O22.51','O22.8X1','O22.91','O23.01','O23.11','O23.21'
                            ,'O23.31','O23.41','O23.511','O23.521','O23.591','O23.91','O24.011','O24.111','O24.311','O24.811','O24.911','O25.11','O26.01','O26.11','O26.21','O26.31','O26.41'
                            ,'O26.51','O26.611','O26.711','O26.811','O26.821','O26.831','O26.841','O26.851','O26.891','O26.91','O29.091','O29.111','O29.121','O29.191','O29.211','O29.291'
                            ,'O29.3X1','O29.8X1','O29.91','O30.001','O30.011','O30.021','O30.031','O30.041','O30.101','O30.131','O30.201','O30.221','O30.231','O30.91','O31.01','O31.01X0'
                            ,'O31.01X1','O31.01X2','O31.01X3','O31.01X4','O31.01X5','O31.01X9','O31.8X1','O31.8X10','O31.8X11','O31.8X12','O31.8X13','O31.8X14','O31.8X15','O31.8X19'
                            ,'O34.31','O34.41','O34.521','O34.61','O36.011','O36.0110','O36.0119','O36.091','O36.0910','O36.0919','O36.111','O36.1119','O36.191','O36.1910','O36.1911'
                            ,'O36.1912','O36.1913','O36.1914','O36.1915','O36.1919','O36.21','O36.21X0','O36.21X1','O36.21X2','O36.21X3','O36.21X4','O36.21X5','O36.21X9','O36.61','O36.61X0'
                            ,'O36.61X9','O36.71','O36.821','O36.8210','O36.8211','O36.8212','O36.8213','O36.8214','O36.8215','O36.8219','O36.891','O36.8910','O36.8919','O36.91','O36.91X0'
                            ,'O36.91X9','O40.1','O40.1XX0','O40.1XX1','O40.1XX2','O40.1XX3','O40.1XX4','O40.1XX5','O40.1XX9','O41.01','O41.01X0','O41.01X1','O41.01X2','O41.01X3','O41.01X4'
                            ,'O41.01X5','O41.01X9','O41.101','O41.121','O41.1210','O41.1211','O41.1212','O41.1213','O41.1214','O41.1215','O41.1219','O41.141','O41.1410','O41.1411','O41.1412'
                            ,'O41.1413','O41.1414','O41.1415','O41.1419','O41.8X1','O43.011','O43.021','O43.101','O43.111','O43.121','O43.191','O43.211','O43.221','O43.231','O43.811'
                            ,'O43.891','O43.91','O44.11','O44.31','O44.41','O44.51','O45.011','O45.091','O45.8X1','O45.91','O46.001','O46.011','O46.021','O46.091','O46.8X1','O46.91','O88.011'
                            ,'O88.111','O88.211','O88.311','O88.811','O91.011','O91.111','O91.211','O92.011','O92.111','O98.011','O98.111','O98.211','O98.411','O98.511','O98.611','O98.711'
                            ,'O99.011','O99.211','O99.311','O99.321','O99.331','O99.341','O99.351','O99.411','O99.511','O99.611','O99.711','O99.841','O9A.111','O9A.311','O9A.411','O9A.511','Z34.01','Z34.81','Z34.91'
                                ,'Z86.69', 'Z91.012', 'Z28.04','Z79.82'  )  --these last ones are Guillian Berre, allergy to eggs, allergy to vacc or component, and long term (current) user of aspirin
            ) ContraIndicator
 
 WHERE  ha.loc_id = 100000 
  -- and ha.ACCT_BASECLS_HA_C = 1 -- INPATIENT ONLY
   and ha.acct_billsts_ha_c NOT IN (99, 40) -- Exclude combined and voided accounts

--  Peds age must be >= 6 months and less than 18 yrs at time of admission
   AND TRUNC(MONTHS_BETWEEN(trunc(coalesce( pe.hosp_admsn_time, peh.hosp_admsn_time, ha.adm_date_time )),trunc(pat.birth_date))/12) < 18  --years
   AND TRUNC(MONTHS_BETWEEN(trunc(coalesce( pe.hosp_admsn_time, peh.hosp_admsn_time, ha.adm_date_time )),trunc(pat.birth_date))) >= 6  --months
 
 -- Get encounter dates --flu season
   AND trunc(coalesce( pe.hosp_dischrg_time, peh.hosp_disch_time, ha.disch_date_time, peh.hosp_admsn_time, pe.hosp_admsn_time, ha.adm_date_time))
                    between '01-OCT-2022' and  '31-DEC-2022' 
                    
   AND edg.ref_bill_code IN ('J45.20','J45.21','J45.22','J45.30','J45.31','J45.32','J45.40','J45.41','J45.42','J45.50','J45.51','J45.52',  --Primary asthma DIAGNOSES???
                             'J45.901','J45.902','J45.909','J45.990','J45.991','J45.998')

   AND upper(z.NAME) LIKE '%PULMO%'   --TREATED BY PEDS PULMONOLOGY                           
   ---ORDER BY ha.HSP_ACCOUNT_NAME, MRN, Admit_DT
   ) 
      ORDER BY QUESTION
 