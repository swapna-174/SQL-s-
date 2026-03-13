select ucl.ACCOUNT_ID
    , ucl.HOSPITAL_ACCOUNT_ID
    , ucl.SERVICE_DATE_DT
    , ucl.EPT_CSN
    , ucl.PATIENT_ID
    , pat.PAT_NAME
	, ucl.order_id
    , ucl.UCL_ID
    , ucl.PROCEDURE_ID
    , eap.PROC_CODE
    , ucl.HCPCS_CODE
    , ucl.PROC_DESCRIPTION 
    , ucl.COST
    , ucl.IMPLIED_QTY
    , ucl.SYSTEM_FLAG_C
    , zc_sys.name as system_flag
--    , ucl2.EXPECTED_PRICE
    , ucl.COST_CNTR_DEPT_ID
    , dep_cc.DEPARTMENT_NAME
    , ucl.DEPARTMENT_ID
    , dep.DEPARTMENT_NAME
    --from arpb_transactions arpb
from clarity_ucl ucl
--    left outer join clarity_ucl_2 ucl2 on ucl.UCL_ID = ucl2.ucl_id
    left outer join clarity_eap eap on ucl.PROCEDURE_ID = eap.proc_id
    left join patient pat on ucl.PATIENT_ID = pat.pat_id
--    left outer join hsp_transactions hsp on ucl.hospital_account_id = hsp.hsp_account_id
    left outer join CLARITY_DEP dep ON ucl.DEPARTMENT_ID = dep.DEPARTMENT_ID
    left outer join CLARITY_DEP dep_cc ON ucl.COST_CNTR_DEPT_ID = dep_cc.DEPARTMENT_ID
    left outer join ZC_SYSTEM_FLAG zc_sys on ucl.SYSTEM_FLAG_C = zc_sys.system_flag_c    
where ucl.SERVICE_DATE_dt >= '01-SEP-2019' and ucl.SERVICE_DATE_dt <= '31-DEC-2019'
--        and dep.DEPARTMENT_NAME like '%NEURO%'
--        and ucl.hcpcs_code  in ('J0585', 'J0586', 'J0587')
		and ucl.hcpcs_code in ('J7298', 'J7297', 'J7301', 'J7296', 'J7307')
		and eap.PROC_CODE in ('J7298', 'J7297', 'J7301', 'J7296', 'J7307')
--        and ucl.SYSTEM_FLAG_C not in ('2', '4', '5')

--where ucl.HOSPITAL_ACCOUNT_ID = '424144851'
--where ucl.PATIENT_ID = 'Z1947816'
--where ucl.UCL_ID = '111136058'
--where ucl.UCL_ID = '112560170'
--where ucl.ucl_id = '96694364'
--where ucl.HOSPITAL_ACCOUNT_ID = '420549783'
--where ucl.HOSPITAL_ACCOUNT_ID = '425237597'

     

order by pat.PAT_NAME asc, ucl.SERVICE_DATE_DT