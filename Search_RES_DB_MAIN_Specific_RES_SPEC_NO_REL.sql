
select pat.PAT_NAME
	, pat.PAT_ID
    , pat.PAT_MRN_ID
--    , pat_race.PATIENT_RACE_C
    , zc_ethnic.name as ethnic_group
    , zc_race.name as race
--	, pat.pat_id
    , spec_db.SPEC_DTM_COLLECTED
	, spec_db.SPEC_DTM_RECEIVED
	, res_db.RES_INST_VALIDTD_TM
    , res_db.RES_SPEC_NO_REL
    , res_comp.component_result
	, res_db.RES_ABNORMAL_C
--	, spec_tst.RESULT_TO_PRINT_ID
	, res_comp.component_id
    , comp.NAME
    , res_comp.component_result
	, ord2.pat_loc_id
	, dep_enc.department_name
	, ord.PAT_ENC_CSN_ID
	, spec_tst.TEST_STATUS_DTTM
	, spec_tst.LAST_RECV_DTTM
	, test_db.test_name
--    , comp.ABBREVIATION
    , comp.NAME
	, res_comp.COMPONENT_ID
    , res_comp.component_value
--	, res_comp.COMPONENT_RANGE as component_normal_range
	, ord.order_proc_id
	, eap.PROC_ID
	, eap.proc_code
	, eap.proc_name
	, ord.ORDER_INST
	, eap.PROC_CODE
--	, ord.ORDER_STATUS_C
--    , mthd.METHOD_NAME
    , res_db.RES_SPEC_NO_REL
	, spec_tst.CURRENT_RESULT_ID
	, spec_tst.RESULT_TO_PRINT_ID
--	, res_db.RES_TEST_ID
--    , comp.component_id
--    , res_db.resulting_lab_id
--    , pat.BIRTH_DATE
--    , floor(months_between (to_date(spec_db.SPEC_DTM_COLLECTED), PAT.BIRTH_DATE)  /  12) as "Age"
 --   , ord.DISPLAY_NAME
 --   , comp.COMPONENT_ID
--    , res_comp.COMPONENT_MTHD_ID
--	, spec_tst.*
from res_db_main res_db
    inner join spec_db_main spec_db on res_db.RES_SPECIMEN_ID = spec_db.SPECIMEN_ID
    inner join spec_test_rel spec_tst on res_db.RES_SPECIMEN_ID = spec_tst.SPECIMEN_ID
		   and spec_tst.RESULT_TO_PRINT_ID = res_db.RESULT_ID
--           and res_db.test_line = spec_tst.LINE
    left outer join zc_res_val_status zc_stat on res_db.RES_VAL_STATUS_C = zc_stat.RES_VAL_STATUS_C 
	left outer join test_mstr_db_main test_db on res_db.RES_TEST_ID = test_db.test_id
    left outer join LAB_SECTION lab_sec on spec_tst.SPEC_TST_SEC_ID = lab_sec.SECTION_ID
    left outer  join res_components res_comp on res_db.RESULT_ID = res_comp.RESULT_ID
    left outer  join order_proc ord on res_db.RES_ORDER_ID = ord.ORDER_PROC_ID
	left outer join order_proc_2 ord2 on ord.order_proc_id = ord2.order_proc_id
	left outer join clarity_dep dep_enc on ord2.PAT_LOC_ID = dep_enc.DEPARTMENT_ID
	left outer join clarity_eap eap on ord.proc_id = eap.proc_id
    left outer  join CLARITY_COMPONENT comp on res_comp.COMPONENT_ID = comp.COMPONENT_ID
    left outer  join zc_lab_data_type zc_data on comp.lab_data_type_c = zc_data.lab_data_type_c
--    left outer join METHOD_DB_MAIN mthd on res_comp.COMPONENT_MTHD_ID = mthd.METHOD_ID
    left outer join patient pat on ord.PAT_ID = pat.PAT_ID
    left outer join clarity_emp emp on res_db.RES_TECH_ID = emp.USER_ID
     left outer join patient_race pat_race on pat.pat_id = pat_race.pat_id
--            and pat_race.line = '1'
    left outer join ZC_ETHNIC_GROUP zc_ethnic on pat.ETHNIC_GROUP_C = zc_ethnic.ethnic_group_c
    left outer join zc_patient_race zc_race on pat_race.PATIENT_RACE_C = zc_race.patient_race_c


--where Trunc(res_db.RES_INST_VALIDTD_TM) >= EPIC_UTIL.EFN_DIN ('{?From Date}')  
--       AND Trunc(res_db.RES_INST_VALIDTD_TM) <= EPIC_UTIL.EFN_DIN ('{?To Date}')

--where res_db.res_spec_no_rel IN ('20X-077LC0106', '20X-077LC0099', '20X-077LC0100', '20X-077LC0080', '20X-077LC0083', '20X-077LC0151', '20X-079LC0048', '20X-078LC0074', '20X-078LC0083', '20X-078LC0087', '20N-084AT0004', '20N-085AT0005', '20N-085AT0008', 
--'20X-086LC0023', '20X-087LC0039', '20N-090AT0024', '20X-090LC0067', '20X-090LC0056')

--where ord.order_proc_id IN ('552226606', '553157668', '553159352', '526965803', '536475539', '540605117', '540631091', '549335009')

where ( trunc(res_db.RES_INST_VALIDTD_TM) >= '1-APR-2020'  
    			and  
				trunc(res_db.RES_INST_VALIDTD_TM) <= trunc(sysdate) -1			--'18-MAR-2020'
			)
--	and mthd.method_name IN ('WCCHR AU5812', 'WCCHR AU5822', 'WCCH RMCH')
--	and v_lab.proc_code IN ('LAB2751', 'LAB4801', 'LAB4826')
--	and ord.proc_id IN (100131, 141173, 141181)

--where trunc(res_db.RES_INST_VALIDTD_TM) = trunc(sysdate) -1
--where trunc(spec_db.SPEC_DTM_RECEIVED) = trunc(sysdate) - 1
--where trunc(spec_tst.TEST_STATUS_DTTM)	= trunc(sysdate) - 1
			
--	and ord.proc_id IN (141173, 141181, 141197, 141289, 141308, 141381) 
--	and res_comp.COMPONENT_ID IN (1230294703, 1230294700, 1230294866, 1230294909, 1230294916, 1230294922)--, 1230294867)

	and ord.proc_id IN (142188)
	 
--	and res_comp.COMPONENT_ID IN (1230294922)--, 1230294867)

--	and ord.proc_id IN (141308)

--	and res_comp.COMPONENT_ID IN (1230294866)--, 1230294867, 1230294868)

--1230294866 COVID-19 ORF1
--1230294867 COVID-19 E-GENE
--1230294868 COVID-19 ATRIUM PERFORMING LAB

--1230294916	SARS-COV-2
--141308			COVID-19 IN-HOUSE TEST (COBAS)	LAB6088


--LAB6089
--141381	HPMC INPATIENT ONLY COVID-19 (LD, URGENT OR AND CATH LAB)
--1230294922	SARS-COV-2 HP CEPHEID
--1230294923	SARS-COV-2 COMMENT HP CEPHEID
--1230294924	SARS-COV-2 METHOD HP CEPHEID

--	and res_comp.component_result  = 'Detected'

--where res_db.RES_SPEC_NO_REL  = '20S-074ST0004'


order by  res_db.RES_INST_VALIDTD_TM asc, res_db.RES_SPEC_NO_REL asc, res_db.RES_TEST_ID asc


--      )
--group by method_name


--				3836682


--		20N-084AT0016
--		20N-085AT0004
GO
