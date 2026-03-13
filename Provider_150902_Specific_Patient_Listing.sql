select pat.pat_mrn_id
    , pat.pat_name
    , pat.pat_first_name
    , pat.pat_last_name
    , pat.add_line_1
    , pat.add_line_2
    , pat.city
    , zc_state.name as "STATE"
    , pat.zip
    , pat.EMAIL_ADDRESS
    , pat.death_date
    , f_appt.DEPARTMENT_ID
    , dep.DEPARTMENT_NAME
     , f_appt.PRC_ID
     , prc.PRC_NAME
    , f_appt.pat_enc_csn_id
    , f_appt.appt_status_c
    , zc_appt.name as "APPT_STATUS"
    , f_appt.appt_dttm
    , ser.prov_id
    , ser.prov_name
	, edg.CURRENT_ICD10_LIST
	, dx.LINE
from f_sched_appt f_appt
    inner join patient pat on f_appt.pat_id = pat.pat_id
    inner join pat_enc enc on f_appt.pat_enc_csn_id = enc.pat_enc_csn_id
	left outer join pat_enc_dx dx on enc.PAT_ENC_CSN_ID = dx.PAT_ENC_CSN_ID
	left outer join clarity_edg edg on dx.DX_ID = edg.DX_ID
    inner join clarity_ser ser on f_appt.prov_id = ser.prov_id
    left outer join patient_dismissal pat_dis on f_appt.pat_id = pat_dis.pat_id
    inner join zc_appt_status zc_appt on f_appt.appt_status_c = zc_appt.appt_status_c
    inner join zc_state zc_state on pat.state_c = zc_state.state_c
    inner join clarity_dep dep on f_appt.DEPARTMENT_ID = dep.DEPARTMENT_ID
    inner join clarity_prc prc on f_appt.PRC_ID = prc.prc_id
WHERE f_appt.APPT_DTTM >= '1-JAN-18' and  f_appt.APPT_DTTM < '24-FEB-20'
--where Trunc(f_appt.APPT_DTTM) >= EPIC_UTIL.EFN_DIN ('{?From Date}')  
--                  AND Trunc(f_appt.APPT_DTTM) <= EPIC_UTIL.EFN_DIN ('{?To Date}')
--    and f_appt.prov_id = '142514'
    and f_appt.prov_id = '150902'
	and edg.CURRENT_ICD10_LIST IN ('S06.0X9A','G44.309','S06.9X9A')
--    and f_appt.PRC_ID = '920'
--    and f_appt.prov_id = '26300'
--    and f_appt.prov_id = '21637'
--    and f_appt.prov_id = ('{?Provider}')


    and f_appt.appt_status_c = '2'
    and pat.death_date is NULL
order by pat.pat_last_name asc, f_appt.appt_dttm asc


--select *
--from clarity_ser ser
--where ser.prov_name like 'CARROLL%'