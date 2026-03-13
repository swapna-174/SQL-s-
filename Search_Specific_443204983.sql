select ord.ORDER_PROC_ID
    , ord.PROC_ID
    , ord.PROC_CODE
    , ord.ORDER_INST
    , ord.PROC_ENDING_TIME
    , cl_q.QUEST_NAME
    , ord_q.*
    , ord_audit.*
from order_proc ord 
    left outer join order_audit_trl ord_audit on ord.ORDER_PROC_ID = ord_audit.order_id
    left outer join ord_spec_quest ord_q on ord.order_proc_id = ord_q.order_id
    left outer join cl_qquest cl_q on ord_q.ord_quest_id = cl_q.QUEST_ID
    left join ( select cl_qov.QUEST_ID
                        , cl_qov.QUESTION
                      from cl_qquest_ovtm cl_qov
                        group by cl_qov.QUEST_ID, cl_qov.QUESTION
                   ) cl_qov on cl_q.QUEST_ID = cl_qov.QUEST_ID
where ord.order_proc_id in ('443204983', '443147363', '443023493', '443023464', '442790740', '442711494', '442603879', '442433810', '442405344')
  and cl_q.quest_id IN ('100123', '101572', '152600')
