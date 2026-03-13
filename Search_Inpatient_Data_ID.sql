select ip_meas.FLO_MEAS_ID
    , ip_meas.FSD_ID
    , ip_meas.FLT_ID
    , ip_data.FLO_MEAS_NAME
    , ip_data.DISP_NAME
    , ip_meas.MEAS_VALUE
    , ip_meas.RECORDED_TIME
    , ip_meas.TAKEN_USER_ID
    , ip_meas.ENTRY_TIME
    , ip_meas.ENTRY_USER_ID
    , ip_rec.INPATIENT_DATA_ID
    , enc.pat_ID
    , pat.pat_mrn_id
    , pat.PAT_NAME
    , enc.PAT_ENC_CSN_ID
from ip_flwsht_meas ip_meas
    inner join ip_flwsht_rec ip_rec on ip_meas.fsd_id = ip_rec.fsd_id
    inner join ip_flo_gp_data ip_data on ip_meas.flo_meas_id = ip_data.flo_meas_id
    inner join pat_enc_hsp enc on ip_rec.INPATIENT_DATA_ID = enc.inpatient_data_id
    inner join patient pat on enc.PAT_ID = pat.PAT_ID

where ip_rec.inpatient_data_id = '30091734'

--where ip_rec.INPATIENT_DATA_ID IN ('29973490', '30091734', '29961897', '29970516', '30094120', '30090874', '29816345', '29971238', '29862889', '30048585', '30139527', '29904723', '29898126', 
--'29560079', '30028017', '29879162', '29632251', '29954194', '29654881', '29473875', '29806044', '30019937', '29712672', '29920172', '29962546', '29914463', 
--'30094209', '30125953', '29862388', '30094545', '29913539', '29926216', '30053224', '29746056', '29816950', '29893121', '30032890', '29822186', '29083645', 
--'30107474', '29744516', '30119354', '29816813', '29963543', '26673859', '30110672', '30109639', '29807080', '29951787', '30006254', '30135672', '29343577', 
--'29967393', '29719423', '29858681', '29720941', '29962908', '29500865', '29854321', '29980175', '30045056', '30100211', '29947180', '30021274', '30152466', 
--'29829948', '29945487', '29813741', '29891966', '30019624', '30150802', '29851416', '30111761', '29811481', '29876020', '30006232', '30137817', '30052940', 
--'30006025', '29542507', '30055580', '29876458', '29929021', '29344845', '30138439', '30038189', '29956155', '30069641', '30056345', '30128088', '29830204', 
--'29715455', '30092340', '29924666', '29643146', '30116958', '29975607')

--    and ip_meas.flo_meas_id in  ('5','6','7', '8', '9','10','3043001267', '3042000407','3042001128' ,'2533') 
--    and ip_meas.FLO_MEAS_ID IN ('3042000407','2533','3049002245','3042001128','3049002240', '3043001267') 

--where ip_meas.flo_meas_id IN ('2533')
--    and trunc( ip_meas.ENTRY_TIME ) >= '1-JUN-2018'

--where ip_meas.flo_meas_id IN ('543115388','543115389','543115390','543115391','543115392','543115393','543115394','543115395','543115396','543115397', 
--                                                            '543115398','543115399','543115400','543115401','543115402','543115960','543119584','543122633','543125421','543122629',
--                                                            '543122630')
                                                            
                                                            
-- select enc.PAT_ID
--    , enc.PAT_ENC_CSN_ID
--    , enc.HOSP_ADMSN_TIME
--    , enc.INPATIENT_DATA_ID
--    , pat.PAT_MRN_ID
--    , pat.PAT_NAME
-- from pat_enc enc
--    inner join patient pat on enc.pat_id = pat.pat_id
-- where pat.pat_mrn_id = '842169'