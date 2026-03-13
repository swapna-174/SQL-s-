select ord.order_proc_id
       , eap.PROC_ID
       , eap.proc_code
       , eap.PROC_CAT_ID
       , enc.DEPARTMENT_ID
       , dep_enc.DEPARTMENT_NAME as encounter_dept 
       , ord.ORDER_INST
       , eap.proc_name
       , ord.PAT_ENC_CSN_ID
       , ord.ORDER_STATUS_C
       , ord.LAB_STATUS_C
       , pat.PAT_NAME
	, enc.HSP_ACCOUNT_ID
    , pat.PAT_MRN_ID
    , ord2.PAT_LOC_ID
	, ser_auth.PROV_NAME as authorizing_provider
from order_proc ord
       left outer join order_proc_2 ord2 on ord.ORDER_PROC_ID = ord2.ORDER_PROC_ID
       left outer join clarity_eap eap on ord.PROC_ID = eap.proc_id
       left outer join patient pat on ord.pat_id = pat.pat_id
       left outer join pat_enc enc on ord.PAT_ENC_CSN_ID = enc.PAT_ENC_CSN_ID
       left outer join ZC_ORDER_STATUS zc_stat on ord.ORDER_STATUS_C = zc_stat.order_status_c
       left outer join clarity_ser ser on enc.VISIT_PROV_ID = ser.prov_id
       left outer join clarity_ser ser_auth on ord.AUTHRZING_PROV_ID = ser_auth.PROV_ID
       left outer join clarity_dep dep_login on ord2.LOGIN_DEP_ID = dep_login.DEPARTMENT_ID
       left outer join clarity_dep dep_enc on ord2.PAT_LOC_ID = dep_enc.DEPARTMENT_ID
where pat.PAT_ID = 'Z1185355'
--where eap.proc_code IN('J7306', '60006968')
--where eap.PROC_CODE IN ('OB136', 'OB236')

