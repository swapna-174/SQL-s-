select ord.PAT_ENC_CSN_ID
--    , ord.PAT_ID    
    , dep.department_name
    , dep.DEPT_ABBREVIATION
    , pat.PAT_NAME
    , pat.pat_mrn_id
--    , ser.PROV_NAME
    , zc_serv.NAME as "SERVICE"
    , peh.HOSP_ADMSN_TIME
    , peh.hosp_disch_time
    , ord.ORDER_PROC_ID
    , ord.INSTANTIATED_TIME
    , ord.ORDER_STATUS_C
    , ord.FUTURE_OR_STAND
    , ord.PROC_CODE
    , ord.PROC_START_TIME
    , ord_audit.audit_trl_user_id
    , ord_audit.audit_trl_time
    , ord_audit.audit_trl_action_c
--    , ord.ORDERING_DATE
--    , ord.ORDER_INST
--    , zc_ord.name
--    , ord_summ.LINE
--    , ord_summ.ORD_SUMMARY
    , cl_q.QUEST_ID
    , cl_q.QUEST_NAME
    , cl_qov.QUESTION
    , ord_q.LINE
    , ord_q.ORD_QUEST_RESP

--    , ord_r.*
from order_proc ord 
    left outer join pat_enc_hsp peh on ord.pat_enc_csn_id = peh.PAT_ENC_CSN_ID
    left outer join patient pat on peh.pat_id = pat.PAT_ID
    left outer join zc_order_status zc_ord on ord.order_status_c = zc_ord.order_status_c
    left outer join zc_pat_service zc_serv on peh.hosp_serv_c = zc_serv.HOSP_SERV_C
    left outer join clarity_ser ser on peh.BILL_ATTEND_PROV_ID = ser.PROV_ID
    left outer join clarity_dep dep on peh.department_id = dep.department_id
--    left outer join order_summary ord_summ on ord.ORDER_PROC_ID = ord_summ.order_id

    left outer join ord_spec_quest ord_q on ord.order_proc_id = ord_q.order_id
    left outer join order_audit_trl ord_audit on ord.ORDER_PROC_ID = ord_audit.ORDER_ID
    left outer join cl_qquest cl_q on ord_q.ord_quest_id = cl_q.QUEST_ID
    left join ( select cl_qov.QUEST_ID
                        , cl_qov.QUESTION
                      from cl_qquest_ovtm cl_qov
                        group by cl_qov.QUEST_ID, cl_qov.QUESTION
                   ) cl_qov on cl_q.QUEST_ID = cl_qov.QUEST_ID
--    left outer join order_results ord_r on ord.order_proc_id = ord_r.order_id
--where ord.proc_code = 'NUR1507'
--and trunc(ord.ordering_date) >= '1-APR-2017'
--and ord.pat_id  = 'Z645637'
--where ord.ORDER_PROC_ID = '434831662'
where ord.PROC_ID = '100007'
--    and ord.order_proc_id = '443123895'

--    and trunc(ord.PROC_START_TIME) >= '17-JUL-2017' and trunc(ord.PROC_START_TIME) <= '17-JUL-2017'
    and trunc(ord_audit.audit_trl_time) >= '15-JUL-2017' and trunc(ord_audit.audit_trl_time) <= '17-JUL-2017'

--    and ord.order_status_c = '2'
--    and ( ord.order_status_c is null 
--                    or
--               ord.order_status_c = '2'
--            )
--    and ord.order_status_c  is null
--    and ord.FUTURE_OR_STAND = 'S'
--    and cl_q.quest_id IN ('100122') -- , '100123')
    and cl_q.quest_id IN ('100123', '101572', '152600') -- , '100123')
order by pat.pat_name asc, ord.PAT_ENC_CSN_ID asc, ord.ORDER_PROC_ID asc, ord_q.LINE



/*
Order is EAP NUR1507. FLT 3042000087 - some FLOs on that FLT are unique to the telemetry techs - some are shared, but they would use this FLT
MRN 719354 has an active order, and documentation on that flowsheet
*/
