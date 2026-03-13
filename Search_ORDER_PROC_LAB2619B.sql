select ord.ORDER_PROC_ID
    , ord.ORDER_INST
    , peh.INPATIENT_DATA_ID
    , ord.PAT_ENC_CSN_ID
    , pat.pat_name
    , ord_r.COMPONENT_ID
    , ord_r.LINE
    , ord_r.PAT_ENC_CSN_ID
    , ord_r.ORD_VALUE
    , ord_r.RESULT_SUB_IDN
from order_proc ord
    inner join pat_enc_hsp peh on ord.PAT_ENC_CSN_ID = peh.PAT_ENC_CSN_ID
    inner join patient pat on peh.PAT_ID = pat.pat_id
    inner join order_results ord_r on ord.order_proc_id = ord_r.order_proc_id
--where ord.ORDER_PROC_ID = '474988837'
where ord.PROC_CODE = 'LAB2619B'
    and trunc(ord.ORDER_INST) = '21-JUN-2018'
    and (   ord_r.ord_value = 'transfused'
                    or
                ord_r.ORD_VALUE like 'W%'
            )
order by pat.pat_name asc, ord.ORDER_PROC_ID asc, ord_r.LINE

--select * from clarity_component where component_id in ('1230294081','1230294080')