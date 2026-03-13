select
    *
from (
select
    a.*,
    rank() over ( partition by pat_mrn_id order by "PROC_START_TIME" desc ) as pfs_rank
from 
(
SELECT DISTINCT
                *
                FROM
                (

select distinct
      pat.pat_mrn_id                                                                        
    , peh.HSP_ACCOUNT_ID                                                                    AS "HSP_ACCOUNT_ID"
    , ser_hv.PROV_NAME                                                                      AS "TELEMETRY_ORDERING_PROV"
    , ser_create.PROV_NAME                                                                  AS "ORDER_ENTERED_BY"
    , ord.PROC_START_TIME                                                                   as "PROC_START_TIME"
    , ord.PROC_ENDING_TIME                                                                  as "PROC_END_TIME"
    , case when ord.PROC_ENDING_TIME is not null
        then round(round(((ord.PROC_ENDING_TIME - ord.PROC_START_TIME)*1440),0)/60,2) 
        end                                                                                 AS "ELAPSED_TIME_HOURS"
    , cl_qov.QUESTION                                                                       as "Question"
    , ord_q.ORD_QUEST_RESP                                                                  as "Answer"
    , floor(months_between (to_date(ord.PROC_START_TIME), PAT.BIRTH_DATE)  /  12)           as "AGE"
    , zc_sex.NAME                                                                           as "SEX"
    , ord.ORDER_PROC_ID                                                                     as "Order ID"
    , ord_c.ORDERING_COMMENT                                                                as "INDICATION_COMMENT"
from order_proc ord
    left outer join clarity_ser ser_auth on ord.AUTHRZING_PROV_ID = ser_auth.PROV_ID
    left outer join clarity_ser ser_create on ord.ORD_CREATR_USER_ID = ser_create.USER_ID
    left outer join order_comment ord_c on ord.ORDER_PROC_ID = ord_c.order_id
    left outer join pat_enc_hsp peh on ord.pat_enc_csn_id = peh.PAT_ENC_CSN_ID
    left outer join patient pat on peh.pat_id = pat.PAT_ID
    left outer join zc_sex zc_sex on pat.sex_c = zc_sex.RCPT_MEM_SEX_C
    left outer join zc_order_status zc_ord on ord.order_status_c = zc_ord.order_status_c
    left outer join zc_pat_service zc_serv on peh.hosp_serv_c = zc_serv.HOSP_SERV_C
    left outer join clarity_dep dep on peh.department_id = dep.department_id
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

where ord.PROC_ID IN ('100007','197963','197967')            ---     NUR1507   CONTINUOUS CARDIAC MONITORING WITH TELEMETRY
    and ord.FUTURE_OR_STAND is not null
    and trunc(ord.PROC_START_TIME) >= (sysdate - 4) --'11-SEP-2017' --and trunc(ord.PROC_START_TIME) <= '20-AUG-2017'
    and cl_q.quest_id IN ('100123', '101572', '152600', '152564','101579', '152565', '152587','152588', '152589', '152590', '152591', '152565','100122') 
    --and floor(months_between (to_date(ord.PROC_START_TIME), PAT.BIRTH_DATE)  /  12) >= 18
    --and (round(round(((ord.PROC_ENDING_TIME - ord.PROC_START_TIME)*1440),0)/60,2) >= 48
    --or 
and 
(ord.PROC_ENDING_TIME is null or round(round(((ord.PROC_ENDING_TIME - ord.PROC_START_TIME)*1440),0)/60,2) >= 48)
--ord.PROC_ENDING_TIME is null
order by peh.HSP_ACCOUNT_ID asc

/*
Order is EAP NUR1507. FLT 3042000087 - some FLOs on that FLT are unique to the telemetry techs - some are shared, but they would use this FLT
MRN 719354 has an active order, and documentation on that flowsheet
*/
  
  )
  PIVOT 
  (
  LISTAGG(CASE  WHEN "Question" IN ('Reason for telemetry:','Indication','Additional indication information','Low heart rate limit (bpm):','Initiate / Renew','Telemetry removal','Renewal Reason') 
                THEN "Answer" END,',') WITHIN GROUP (ORDER BY "Order ID") FOR  "Question" IN 
  (
	 'Reason for telemetry:'                AS "INDICATION"   
    ,'Indication'                           AS "INDICATION_2"
    ,'Additional indication information'    AS "INDICATION_3"
    ,'Low heart rate limit (bpm):'          AS "HEART_RATE_LIMIT"
	,'Initiate / Renew'                     AS "INITIATE_RENEW"
	,'Telemetry removal'                    AS "REMOVAL"
    ,'Renewal Reason'                       AS "RENEWAL_ REASON"

  )
)

)
a
)
where pfs_rank = 1
ORDER BY 5