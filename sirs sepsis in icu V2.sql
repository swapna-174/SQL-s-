
with allPts as
( select 
  p.pat_id 
, p.pat_name as Patient 
, p.pat_mrn_id as MRN 
, cd.department_name as Department 
, peh.hosp_admsn_time as AdmitDate 
, ifr.inpatient_data_id
from ip_flwsht_rec ifr
inner join ip_flwsht_meas ifm on ifr.fsd_id = ifm.fsd_id
inner join patient p on ifr.pat_id = p.pat_id
inner join pat_enc_hsp peh on ifr.inpatient_data_id = peh.inpatient_data_id
inner join clarity_dep cd on peh.department_id = cd.department_id
where ifm.recorded_time >= (trunc(sysdate)-1) 
AND peh.DEPARTMENT_ID IN (1000103036,1000105005,1000105006,1000105007,1000105008,1000105009,1000105010,1000105024,1000106013,1090000018, 1000105011,1000105015,1000105003,1000106020)  --  t - 1 in crystal
and ifm.flo_meas_id in ('3049008657', '3042001103',   '3042001026', '3042001051', '3048001013')
),
snooze as
(select 
  ap.pat_id 
, to_char(ifm.recorded_time, 'MM-DD-YYYY HH24:MI') as SnoozeRecordedTime 
, ifm.meas_value as SnoozeValue
, ifm.recorded_time
from allPts ap
inner join ip_flwsht_rec ifr on ap.inpatient_data_id = ifr.inpatient_data_id
inner join ip_flwsht_meas ifm on ifr.fsd_id = ifm.fsd_id and ifm.flo_meas_id = '3042001026'
where ifm.recorded_time >= (trunc(sysdate)-1) 
),
criteria as
(select 
  ap.pat_id 
, to_char(ifm.recorded_time, 'MM-DD-YYYY HH24:MI') as CriteriaRecordedTime
, ifm.meas_value as CriteriaValue
, ifm.recorded_time
from allPts ap
inner join ip_flwsht_rec ifr on ap.inpatient_data_id = ifr.inpatient_data_id
inner join ip_flwsht_meas ifm on ifr.fsd_id = ifm.fsd_id and ifm.flo_meas_id = '3049008657'
where ifm.recorded_time >= (trunc(sysdate)-1) 
),
manEval as
( select 
ap.pat_id
, to_char(ifm.recorded_time, 'MM-DD-YYYY HH24:MI') as ManualEvalRecordedTime 
, ifm.meas_value as ManualEvalValue
, ifm.meas_comment as ManualEvalComment
, ifm.recorded_time
from allPts ap
inner join ip_flwsht_rec ifr on ap.inpatient_data_id = ifr.inpatient_data_id
inner join ip_flwsht_meas ifm on ifr.fsd_id = ifm.fsd_id and ifm.flo_meas_id =  '3042001103'
where ifm.recorded_time >= (trunc(sysdate)-1) 
)

select distinct 
  ap.pat_id
, ap.Patient
, ap.MRN
, ap.Department
, ap.AdmitDate  
, s.SnoozeRecordedTime
, s.SnoozeValue
, cr.CriteriaRecordedTime
, cr.CriteriaValue
, me.ManualEvalRecordedTime
, me.ManualEvalValue
, me.ManualEvalComment
from allPts ap
left outer join snooze s on ap.pat_id = s.pat_id
left outer join criteria cr on ap.pat_id = cr.pat_id
left outer join manEval me on ap.pat_id = me.pat_id
order by
  ap.Department
, ap.Patient
, s.SnoozeRecordedTime 
, cr.CriteriaRecordedTime
, me.ManualEvalRecordedTime 