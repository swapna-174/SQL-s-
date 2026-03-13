 SELECT DISTINCT
                *
                FROM
                (

select distinct--pat.PAT_NAME--    , peh.PAT_ID    --, 
pat.pat_mrn_id
    , peh.HSP_ACCOUNT_ID
    --, peh.PAT_ENC_CSN_ID--    , ser.PROV_NAME--    , zc_serv.NAME as "SERVICE"--    , peh.HOSP_ADMSN_TIME--    , peh.hosp_disch_time--    , ord.ORDER_PROC_ID--    , ser_atnd.PROV_NAME as current_attending
    , ser_hv.PROV_NAME as telemetry_ordering_prov
    --, ser_auth.prov_name as attending_at_order
    , ser_create.PROV_NAME as order_entered_by
--    , ord.INSTANTIATED_TIME--    , ord.ORDER_STATUS_C--    , ord.FUTURE_OR_STAND--    , ord.PROC_CODE
    , ord.PROC_START_TIME
    , ord.PROC_ENDING_TIME
--    , round(  (cast(ord.PROC_ENDING_TIME as date) - cast(ord.PROC_START_TIME as date)) * 24  ) as diff_hours
    , case when ord.PROC_ENDING_TIME is not null
        then round(round(((ord.PROC_ENDING_TIME - ord.PROC_START_TIME)*1440),0)/60,2) 
        else 48 end AS elapsed_time_hours
--    , ord.ORDERING_DATE--    , ord.ORDER_INST--    , zc_ord.name--    , ord_summ.LINE--    , ord_summ.ORD_SUMMARY--    , cl_q.QUEST_ID--   , cl_q.QUEST_NAME
    , cl_qov.QUESTION as "Question"
--    , ord_q.LINE
    , ord_q.ORD_QUEST_RESP as "Answer"
    , ord_c.ORDERING_COMMENT as additional_indication_info
--    , ord_audit.audit_trl_user_id    --, ser_canc.PROV_NAME as order_discontinued_by--    , ord_audit.audit_trl_time--    , ord_audit.audit_trl_action_c    --, pat.BIRTH_DATE
    , floor(months_between (to_date(ord.PROC_START_TIME), PAT.BIRTH_DATE)  /  12) as "AGE"
    , zc_sex.NAME as "SEX"
    , ord.ORDER_PROC_ID as "Order ID"

from order_proc ord
    left outer join clarity_ser ser_auth on ord.AUTHRZING_PROV_ID = ser_auth.PROV_ID
    left outer join clarity_ser ser_create on ord.ORD_CREATR_USER_ID = ser_create.USER_ID
    left outer join order_comment ord_c on ord.ORDER_PROC_ID = ord_c.order_id
    left outer join pat_enc_hsp peh on ord.pat_enc_csn_id = peh.PAT_ENC_CSN_ID
    left outer join patient pat on peh.pat_id = pat.PAT_ID
    left outer join zc_sex zc_sex on pat.sex_c = zc_sex.RCPT_MEM_SEX_C
    left outer join zc_order_status zc_ord on ord.order_status_c = zc_ord.order_status_c
    left outer join zc_pat_service zc_serv on peh.hosp_serv_c = zc_serv.HOSP_SERV_C
--    left outer join clarity_ser ser_atnd on peh.BILL_ATTEND_PROV_ID = ser_atnd.PROV_ID
    left outer join clarity_dep dep on peh.department_id = dep.department_id
--    left outer join order_summary ord_summ on ord.ORDER_PROC_ID = ord_summ.order_id
    left outer join hv_order_proc hv_ord on ord.ORDER_PROC_ID = hv_ord.ORDER_PROC_ID
    left outer join clarity_ser ser_hv on hv_ord.ORD_PROV_ID = ser_hv.PROV_ID
    left outer join ord_spec_quest ord_q on ord.order_proc_id = ord_q.order_id
    left outer join order_audit_trl ord_audit on ord.ORDER_PROC_ID = ord_audit.ORDER_ID
    left outer join clarity_ser ser_canc on ord_audit.AUDIT_TRL_USER_ID = ser_canc.USER_ID
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
where ord.PROC_ID = '100007'            ---     NUR1507   CONTINUOUS CARDIAC MONITORING WITH TELEMETRY
--    and pat.pat_mrn_id = '1426505'
    and ord.FUTURE_OR_STAND is not null

--    and ord.order_proc_id = '443123895'

    and trunc(ord.PROC_START_TIME) >= (sysdate - 4) --'11-SEP-2017' --and trunc(ord.PROC_START_TIME) <= '20-AUG-2017'
--    and trunc(ord_audit.audit_trl_time) >= '15-JUL-2017' and trunc(ord_audit.audit_trl_time) <= '17-JUL-2017'

--    and ord.order_status_c = '2'
--    and ( ord.order_status_c is null 
--                    or
--               ord.order_status_c = '2'
--            )
--    and ord.order_status_c  is null
--    and ord.FUTURE_OR_STAND = 'S'
--    and cl_q.quest_id IN ('100122') -- , '100123')
    and cl_q.quest_id IN ('100123', '101572', '152600', '152564','101579', '152565', '152587','152588', '152589', '152590', '152591', '152565') -- , '100123')
    and floor(months_between (to_date(ord.PROC_START_TIME), PAT.BIRTH_DATE)  /  12) >= 18
--    and round(  (cast(ord.PROC_ENDING_TIME as date) - cast(ord.PROC_START_TIME as date)) * 24  ) >= 49
    and (round(round(((ord.PROC_ENDING_TIME - ord.PROC_START_TIME)*1440),0)/60,2) >= 48
    or ord.PROC_ENDING_TIME is null
)
order by peh.HSP_ACCOUNT_ID asc

/*
Order is EAP NUR1507. FLT 3042000087 - some FLOs on that FLT are unique to the telemetry techs - some are shared, but they would use this FLT
MRN 719354 has an active order, and documentation on that flowsheet
*/

  
  )
  PIVOT 
  (
  LISTAGG(CASE  WHEN "Question" IN ('Low heart rate limit (bpm):','Initiate / Renew','Telemetry removal','Reason for telemetry:') 
                THEN "Answer" END,',') WITHIN GROUP (ORDER BY "Order ID") FOR  "Question" IN 
  (
   'Low heart rate limit (bpm):'	AS "HEART RATE LIMIT"
	,'Initiate / Renew'			    AS "INITIATE / RENEW"
	,'Telemetry removal'            AS "REMOVAL"
	,'Reason for telemetry:'		AS "REASON"
  	
  	)
)