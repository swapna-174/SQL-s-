select ip_meas.FSD_ID
    , ip_rec.INPATIENT_DATA_ID
    , ip_meas.FLT_ID
    , ip_meas.FLO_MEAS_ID
    , ip_data.FLO_MEAS_NAME
    , ip_data.DISP_NAME
    , ip_meas.RECORDED_TIME
    , ip_meas.ENTRY_TIME
    , ip_meas.TAKEN_USER_ID
    , ip_meas.ENTRY_USER_ID
    , ip_meas.MEAS_VALUE
    , peh.PAT_ID
    , peh.PAT_ENC_CSN_ID
    , peh.HOSP_ADMSN_TIME
    , peh.HOSP_DISCH_TIME
    , pat.PAT_NAME
    , pat.PAT_MRN_ID
from ip_flwsht_meas ip_meas
    inner join ip_flwsht_rec ip_rec on ip_meas.fsd_id = ip_rec.FSD_ID
    inner join ip_flo_gp_data ip_data on ip_meas.flo_meas_id = ip_data.FLO_MEAS_ID
    inner join pat_enc_hsp peh on ip_rec.INPATIENT_DATA_ID = peh.INPATIENT_DATA_ID
    inner join patient pat on peh.pat_id = pat.PAT_ID
--where ip_meas.FLO_MEAS_ID = '1540100255'
--where ip_meas.FLO_MEAS_ID IN ('3042000089', '3042000090', '3042000091', '3042000092', '3042000093', '3042000094', '3042000095', '3042000096',
--                                                                '3042000097', '3042000098', '3042000099', '3042000100', '3042000101', '3042000102', '3042000103', '3042000104',
--                                                                '3042000105', '3042000106', '10', '301320')
--where peh.PAT_ENC_CSN_ID = '30067152358' 
where peh.pat_enc_csn_id = '30066268431'
--    and ip_meas.FLO_MEAS_ID IN ('3040100963', '302700', '302680', '302690')
--    and pat.pat_mrn_id = '719354'
--    and trunc(peh.HOSP_ADMSN_TIME) >= '1-MAR-2017'


--select *
--from ip_flt_data ip_flt
--where ip_flt.template_id = '3042000087'