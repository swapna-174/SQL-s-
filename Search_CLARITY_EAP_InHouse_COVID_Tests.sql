select eap.PROC_ID
	, eap.PROC_NAME
	, eap.ORDER_DISPLAY_NAME
	, eap.proc_code
--	, eap.test_id
	, test_db.test_id
	, test_db.test_name
	, test_db.test_abbr
	, test_comp.line
	, comp.component_id
	, comp.name
	, eap.test_id
	, test_ques.*
from  clarity_eap eap
	left outer join test_mstr_db_main test_db on eap.TEST_ID = test_db.test_id
	left outer join test_components test_comp on test_db.test_id = test_comp.test_id
	left outer join clarity_component comp on test_comp.component_id = comp.component_id
	left outer join test_collect_ques test_ques on eap.TEST_ID = test_ques.TEST_ID

--where eap.proc_code IN ('LAB5912', 'LAB5905')

-- where eap.proc_code IN ('LAB6082', 'LAB6088', 'LAB6089', 'LAB6024', 'LAB6026', 'LAB6025', 'LAB6081')
 
 where ( eap.proc_id in (141289, 141308, 141381, 142250, 142423, 102286, 141173) 
	                and test_comp.COMPONENT_ID in (1230294909, 1230294916, 1230294922, 1230294948, 1230294986, 1230294951, 1230101570)
				or 
				eap.PROC_ID IN (141173, 141381, 142250, 142423)
				)
--where eap.PROC_ID IN (141173, 141181, 141197)
--where eap.proc_name like 'COVID%'
--
--select *
--from clarity_component comp
----
----
--select *
--from test_components test_comp			--		this needs to refreshed by Jeff Tolley if any new lab tests are implemented in PRD after the weekly refresh


--					51010-Components