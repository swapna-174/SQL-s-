select pat.PAT_MRN_ID
    , pat.PAT_NAME
    , peh.PAT_ENC_CSN_ID
    , peh.inpatient_data_id
    , ip_meas.ENTRY_TIME
    , ip_rec.FSD_ID
    , ip_meas.FLO_MEAS_ID
    , ip_data.FLO_MEAS_NAME
    , ip_data.FLO_DIS_NAME
    , ip_data.FLO_ROW_NAME
    , ip_meas.MEAS_VALUE
    , ip_meas.MEAS_COMMENT
    , ip_rec.FSD_ID
from ip_flwsht_meas ip_meas
    inner join ip_flo_gp_data ip_data on ip_meas.FLO_MEAS_ID = ip_data.flo_meas_id
    inner join IP_FLWSHT_REC ip_rec on ip_meas.FSD_ID = ip_rec.fsd_id
    inner join pat_enc_hsp peh on ip_rec.inpatient_data_id = peh.inpatient_data_id
    inner join patient pat on peh.PAT_ID = pat.PAT_ID
--where ip_meas.FLT_ID = '11000'
--    and pat.PAT_MRN_ID = '2228904'
--    and peh.INPATIENT_DATA_ID = '17552759'
where peh.INPATIENT_DATA_ID = '17552759'
/*1180101018
1180101019
1180101020
1180101021
1180101022
1180101023
1180101024
1180101025
1180101026
1180101027
1180101028
1180101029
1180101030
1180101031
*/
