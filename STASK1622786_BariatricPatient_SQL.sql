select distinct 
pat.pat_mrn_id as "MRN"
, hsp.pat_enc_csn_id as "CSN"
, adt_pat_class_c
, pat.pat_name as "Patient Name"
, enc.weight/16 as "Weight"
, pat.birth_date as "Date of Birth"
, edg.dx_name as "Admitting Diagnosis"
, edg.current_icd9_list as "Diagnosis Code"
, hsp.hosp_admsn_time as "Admission Time"
, hsp.Hosp_disch_time as "Discharge Time"
, hsp.adt_serv_area_id as "Location"
, svca.name as "Admitting Service"
, depa.department_name as "Admitting Nursing Unit"
, svcd.name as "Discharging Service"
, depd.department_name as "Discharge Nursing Unit"

from patient pat
   inner join pat_enc_hsp hsp on pat.pat_id = hsp.pat_id
   inner join pat_enc enc on hsp.pat_enc_csn_id = enc.pat_enc_csn_id
   inner join zc_pat_service ser on hsp.hosp_serv_c = ser.hosp_serv_c
   inner join clarity_adt adm on hsp.adm_event_id = adm.event_id
   inner join zc_pat_service svca on adm.pat_service_c = svca.hosp_serv_c
   inner join clarity_adt dis on hsp.dis_event_id = dis.event_id
   inner join zc_pat_service svcd on dis.pat_service_c = svcd.hosp_serv_c
   inner join clarity_dep depa on adm.department_id = depa.department_id
   inner join clarity_dep depd on dis.department_id = depd.department_id
   inner join hsp_admit_diag dia on hsp.pat_enc_csn_id = dia.pat_enc_csn_id
   inner join clarity_edg edg on dia.dx_id = edg.dx_id
       
   where  hsp.hosp_admsn_time between to_date('2022-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss') and to_date('2023-05-14 23:59:59', 'yyyy-mm-dd hh24:mi:ss') and
          ---hsp.hosp_admsn_time between {?Start Date} and {?End Date} and
          enc.weight/16 > 500 and
       --   hsp.adt_patient_stat_c <> '6' /* Admission  */ and
        --  hsp.adt_pat_class_c = '101' /*inpatient*/ and
          hsp.adt_serv_area_id in ('10', '10001')
 order by pat_mrn_id