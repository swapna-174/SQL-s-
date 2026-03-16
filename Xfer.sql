SELECT peh.inpatient_data_id
      , peh.pat_enc_csn_id
    , pat.PAT_ID
    , pat.PAT_MRN_ID
    , pat.PAT_NAME
    , peh.HSP_ACCOUNT_ID
    , adt.PAT_ENC_CSN_ID
    , adt.PAT_CLASS_C
    , adt.PAT_SERVICE_C
    , ip_meas.*
    , ip_rec.*
    , ip_data.*
--    , adt.XFER_EVENT_ID
--    , adt_xfer.DEPARTMENT_ID
FROM clarity_adt adt
      INNER JOIN pat_enc_hsp peh on adt.pat_enc_csn_id  = peh.pat_enc_csn_id
      left outer join ip_flwsht_rec ip_rec on peh.INPATIENT_DATA_ID = ip_rec.INPATIENT_DATA_ID
      left outer join ip_flwsht_meas ip_meas on ip_rec.FSD_ID = ip_meas.FSD_ID
      left outer join ip_flo_gp_data ip_data on ip_meas.FLO_MEAS_ID = ip_data.FLO_MEAS_ID
      left outer join pat_enc_hsp peh on ip_rec.INPATIENT_DATA_ID = peh.INPATIENT_DATA_ID
      left outer join patient pat on peh.PAT_ID = pat.PAT_ID
where trunc(adt.EVENT_TIME) >= '16-SEP-2016' and trunc(adt.EVENT_TIME) <= '23-SEP-2016'
      and  adt.DEPARTMENT_ID IN ('1000105017', '1000104044')
      and adt.EVENT_TYPE_C = '3'
      and adt.EVENT_SUBTYPE_C = '1'


