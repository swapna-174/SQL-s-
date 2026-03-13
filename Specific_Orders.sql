select coalesce(ord_chng.PAT_ENC_CSN_ID, ord.PAT_ENC_CSN_ID) as PAT_ENC_CSN_ID
    , pat.PAT_NAME
    , peh.HOSP_ADMSN_TIME
    , peh.hosp_disch_time
    , ord_chng2.ORDER_PROC_ID
    , ord_chng2.ORDER_TIME
    , ord_chng2.PROC_START_TIME
    , ord_chng2.PROC_ENDING_TIME
    , ord_chng2.CHNG_ORDER_PROC_ID
    , zc_ord.NAME as "ORDER_STATUS2"
    , ord_chng.ORDER_PROC_ID
    , ord_chng.ORDER_TIME
    , ord_chng.PROC_START_TIME
    , ord_chng.PROC_ENDING_TIME
    , ord_chng.CHNG_ORDER_PROC_ID
--    , ord_chng.ORDER_STATUS_C
    , zc_ord.NAME as "ORDER_STATUS"
--    , ord.CHNG_ORDER_PROC_ID
    , ord.order_proc_id
    , zc_act.NAME as "ACTIVE_STATUS"
--    , ord.pat_enc_csn_id
    , ord.order_time
    , ord.SCHED_START_TM
    , ord.proc_start_time
    , ord.PROC_ENDING_TIME
--    , ord.STAND_INTERVAL
from order_proc ord
    left outer join pat_enc_hsp peh on ord.pat_enc_csn_id = peh.pat_enc_csn_id
    left outer join patient pat on peh.PAT_ID = pat.PAT_ID
    left outer join order_proc ord_chng on ord.CHNG_ORDER_PROC_ID = ord_chng.ORDER_PROC_ID
    left outer join order_proc ord_chng2 on ord_chng.CHNG_ORDER_PROC_ID = ord_chng2.ORDER_PROC_ID
    left outer join order_proc_2 ord2_chng on ord_chng.ORDER_PROC_ID = ord2_chng.ORDER_PROC_ID
    left outer join order_proc_2 ord2 on ord.order_proc_id = ord2.ORDER_PROC_ID
    left outer join zc_order_status zc_ord on ord_chng.order_status_c = zc_ord.ORDER_STATUS_C
    left outer join zc_order_status zc_ord2 on ord_chng2.order_status_c = zc_ord2.ORDER_STATUS_C
    left outer join zc_active_order zc_act on ord2.act_order_c = zc_act.ACTIVE_ORDER_C
--where ord.ORDER_PROC_ID IN ('435061612', '435009668')
where ord.order_proc_id in ('436302213')
--where ord.ORDER_PROC_ID IN ('435314141', '435135905', '435361291', '435372497', '435477973', '434423988', '435473085', '435287386', '435472324', '435372250', '435426436', 
--                                                              '432129160', '435312078', '435457373', '435227541', '435358291', '435467756', '435404291', '435447602', '435417518', '435270962', '435376997', 
--                                                              '435469219', '435396410', '435306330', '435366845', '435435197', '435467536', '435445527', '435478505', '435392157', '435261439', '435478287', 
--                                                              '435479668', '435352962', '435396867', '435148447', '435069211', '435474781', '435420371', '435460106', '435390920', '435378858', '435150727', 
--                                                              '435459414', '435456806', '434532165', '435383864', '435258706', '435304893', '435396208', '435259621', '435270538')
--where ord.order_proc_id IN ('435253742', '435263575', '435197370', '435239317', '433926183', '435330029', '435264267', '435265637', '435289291', '435297559', 
--                                                     '435336326', '435371669', '435213803', '435267072', '435251989', '435339058', '435245281', '435321506', '434403970', '435120937', 
--                                                     '435338726', '435122252', '435202429', '435146377', '435252641', '435141399', '435243872', '435245772', '435326510', '435113059', 
--                                                     '435121353', '435302376', '435286046', '435166261', '435212808', '435225700', '435229188', '435069179', '435246933', '435136056', 
--                                                     '435127180', '434835752', '435368070', '435254182', '435255536', '435353802', '435096190', '435354965', '435260589', '435061612')
order by pat.PAT_NAME asc