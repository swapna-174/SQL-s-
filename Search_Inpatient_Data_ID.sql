select ip_rec.INPATIENT_DATA_ID 
	, pat.pat_mrn_id
	, enc.hosp_admsn_time
	, enc.HOSP_DISCH_TIME
    , ip_meas.TAKEN_USER_ID
    , ip_meas.RECORDED_TIME
    , ip_meas.ENTRY_USER_ID
    , ip_meas.ENTRY_TIME
    , ip_meas.FLO_MEAS_ID
    , ip_meas.FSD_ID
    , ip_meas.LINE
    , ip_data.FLO_MEAS_NAME
    , ip_data.DISP_NAME
    , ip_meas.MEAS_VALUE as after_meas_value
    , ip_meas.MEAS_COMMENT as after_comment
    , ip_meas.edited_line
    , ip_edit.RECORDED_TIME as recorded_edit
    , ip_edit.ENTRY_TIME as entry_edit
    , ip_edit.MEAS_VALUE as before_meas_value
    , ip_edit.EDIT_COMMENT as before_comment
    , ip_meas.ENTRY_USER_ID
    , ip_rec.INPATIENT_DATA_ID
    , enc.pat_ID
    , pat.pat_mrn_id
    , pat.pat_id
    , pat.PAT_NAME
    , enc.PAT_ENC_CSN_ID
    , ip_edit.*
from ip_flwsht_meas ip_meas
    inner join ip_flwsht_rec ip_rec on ip_meas.fsd_id = ip_rec.fsd_id
    inner join ip_flo_gp_data ip_data on ip_meas.flo_meas_id = ip_data.flo_meas_id
    left outer join ip_flwsht_edited ip_edit on ip_meas.fsd_id = ip_edit.fsd_id
            and ip_meas.flo_meas_id = ip_edit.flo_meas_id
    left outer join pat_enc_hsp enc on ip_rec.INPATIENT_DATA_ID = enc.inpatient_data_id
    inner join patient pat on enc.PAT_ID = pat.PAT_ID

--where ip_rec.inpatient_data_id = '60047871'

--where pat.pat_mrn_id = '1788938'
--	and ip_meas.flo_meas_id IN ('61', '304550')

where pat.pat_mrn_id IN('4656521', '5027378')
	and ip_meas.flo_meas_id IN ('61')

--where pat.pat_mrn_id = '4484225'

--where ip_rec.inpatient_data_id IN (56307418)--, 40152388, 41149371, 40406734, 40406734, 41152666, 41149371, 41152666)
--	and enc.pat_enc_csn_id = '30130432246'

--where ip_rec.INPATIENT_DATA_ID = '54225010'
--    and ip_meas.FLO_MEAS_ID = '11621'
--    and IP_MEAS.FLO_MEAS_ID IN ('11599','11601','11606','11607','11609','11610','11656','11657','11757','11658','11856','11668')
--    and ip_meas.EDITED_LINE is not null
--    and ip_meas.flo_meas_id IN ('3040103967')
--    and ip_meas.flo_meas_id in  ('5','6','7', '8', '9','10','3043001267', '3042000407','3042001128' ,'2533') 
--    and ip_meas.FLO_MEAS_ID IN ('3042000407','2533','3049002245','3042001128','3049002240', '3043001267') 

--where ip_meas.flo_meas_id IN ('6355', '7074337', '7074338', '7074341', '7074348', '7074349', '7075514', '7075515', '3040104001', '3048001054', '1570020030', '7083430', '7074329', 
--															'7074400', '315170', '3048000910', '3048000911', '3048000912', '7075507', '7074377', '7074369', '7074328', '7074356', '7075505', '7075508', '7075509', 		
--															'7075510', '7075511', '7075513', '7075516', '7075517', '7075521', '7074385', '7074392', '316910', '3040104000', '7074325', '7074326', '7074327', 
--															'7074330', '7074333', '7074334', '7074335', '7074336', '7074339', '7074340', '7074343', '7074344', '7074345', '7074351', '7074352', '7074353', 
--															'7074354', '7074355', '7074357', '7074358', '7074359', '7074363', '7074364', '7074366', '7074368', '7074372', '7074373', '7074374', '7074375', 
--															'7074376', '7074379', '7074380', '7074381', '7074383', '7074396', '7074397', '7074398', '7074399', '7074415', '7074499', '7075506', '7075519', 
--															'7075520', '7083410', '7083440')

--where ip_meas.FLO_MEAS_ID in (3042002621
--																, 3042002622
--																, 3042002623 	
--																, 3042002704
--																)
--																
--	and trunc(ip_meas.entry_time) >= '1-DEC-2020'

--where pat.pat_mrn_id = '1762934'


--7075506
--3040104001	--	R RT VENTILATOR DISCONTINUED
--315170			--	R WH RESP VENTILATOR PATIENT
--7075505
--7075506	 -- R RT NON-INVASIVE VENTILATOR ID
--7075507
--7075508
          
