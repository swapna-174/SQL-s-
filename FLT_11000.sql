select pat.PAT_MRN_ID
    , pat.PAT_NAME
    , peh.PAT_ENC_CSN_ID
    , ip_meas.*
    , ip_rec.*
    , ip_data.*
from ip_flwsht_meas ip_meas
    inner join ip_flo_gp_data ip_data on ip_meas.FLO_MEAS_ID = ip_data.flo_meas_id
    inner join IP_FLWSHT_REC ip_rec on ip_meas.FSD_ID = ip_rec.fsd_id
    inner join pat_enc_hsp peh on ip_rec.inpatient_data_id = peh.inpatient_data_id
    inner join patient pat on peh.PAT_ID = pat.PAT_ID
--where ip_meas.FLT_ID = '11000'
where ip_meas.FSD_ID = '4320007'
    and ip_meas.FLT_ID = '11000'
    and ip_meas.LINE IN (161, 162, 163, 164, 165, 166, 167, 168, 169, 170)