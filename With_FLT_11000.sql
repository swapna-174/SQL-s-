WITH Xfer_Pat
AS
  (SELECT peh.inpatient_data_id
      , peh.pat_enc_csn_id
    FROM clarity_adt adt
      INNER JOIN pat_enc_hsp peh on adt.pat_enc_csn_id  = peh.pat_enc_csn_id
    where trunc(adt.EVENT_TIME) >= '16-SEP-2016' and trunc(adt.EVENT_TIME) <= '23-SEP-2016'
        and  adt.DEPARTMENT_ID IN ('1000105017', '1000104044')
        and adt.EVENT_TYPE_C = '3'
        and adt.EVENT_SUBTYPE_C = '1'
    )
select pat.PAT_ID
    , pat.PAT_MRN_ID
    , pat.PAT_NAME
    , peh.HSP_ACCOUNT_ID
    , peh.inpatient_data_id
    , ip_meas.FLT_ID
    , ip_meas.FLO_MEAS_ID
    , ip_meas.MEAS_VALUE
    , ip_data.FLO_MEAS_ID
    , ip_data.FLO_MEAS_NAME
    , ip_data.FLO_DIS_NAME
    , ip_rec.INPATIENT_DATA_ID
--    , adt.XFER_EVENT_ID
--    , adt_xfer.DEPARTMENT_ID
from ip_flwsht_rec ip_rec
    left outer join ip_flwsht_meas ip_meas on ip_rec.FSD_ID = ip_meas.FSD_ID
    left outer join ip_flo_gp_data ip_data on ip_meas.FLO_MEAS_ID = ip_data.FLO_MEAS_ID
    left outer join pat_enc_hsp peh on ip_rec.INPATIENT_DATA_ID = peh.INPATIENT_DATA_ID
    left outer join patient pat on peh.PAT_ID = pat.PAT_ID

    inner join xfer_pat xfer on ip_rec.inpatient_data_id = xfer.inpatient_data_id

--    left outer join clarity_adt adt_xfer on adt.XFER_EVENT_ID = adt_xfer.EVENT_ID
--where adt.pat_id = 'Z1064790'
--    and adt.EVENT_ID IN ('12615640', '12581003', '12579424', '12577514')
where ip_meas.FLT_ID = '11000'



/*
select pat.pat_id
    , pat.pat_mrn_id
    , pat.pat_name
from patient pat
where pat.PAT_MRN_ID = '2223434'

select *
from clarity_dep dep
where dep.DEPARTMENT_NAME IN ('MC JT 01 PEDIATRIC PERIOP', 'MC NT 01 MAIN PERIOP')
 */ 