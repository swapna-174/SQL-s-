select *
from order_proc ord
    left outer join order_instantiated ord_i on ord.order_proc_id = ord_i.ORDER_ID
where ord.PROC_ID = '100007'
    and ord.PAT_ENC_CSN_ID = '30067549341'
order by ord.ORDER_INST