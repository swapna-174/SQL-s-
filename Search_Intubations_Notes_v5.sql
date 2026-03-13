WITH smrt_usage  AS 
   (  select hno.note_id
   		, MAX(nei.contact_num) as contact_num
   		, hno.PAT_ENC_CSN_ID
--   		, max(nei.ENT_INST_LOCAL_DTTM) as local_dttm
      from hno_info hno
		    left outer join note_enc_info nei on hno.note_id = nei.note_id
	    	left outer join note_smarttext_ids nsi on nei.NOTE_ID = nsi.note_id
    		left outer join notes_proc_procs nproc on nsi.NOTE_ID = nproc.NOTE_ID
	    	left outer join pat_enc_hsp peh on hno.PAT_ENC_CSN_ID = peh.PAT_ENC_CSN_ID
	where nsi.smarttexts_id = '10587'
			and ( 	trunc(peh.HOSP_ADMSN_TIME) >= '1-SEP-2019'
								and 
							trunc(peh.HOSP_ADMSN_TIME) <= '12-MAY-2020'
							)
				and peh.DEPARTMENT_ID IN ('1000102031', '1000105030', '1000108028', '1000102030')
			and nproc.PROC_NOTE_PROCEDUR = '72364'
 	  group by hno.note_id, hno.PAT_ENC_CSN_ID

	)
select PAT_MRN_ID
,PAT_NAME
,PAT_LOC_ID
,ORDER_INST
,PAT_ENC_CSN_ID
,authorizing_provider
,encounter_dept
,SmartText_Usage
,NOTE_TEXT
,Indication_For_Intubation
,Sedation
,Paralytic
,Lidocaine
,Atropine
,Equipment
,Number_Of_Attempts
From (select
	 pat.PAT_MRN_ID
	, pat.PAT_NAME
	, ord2.PAT_LOC_ID
	, ord.ORDER_INST
	, ord.PAT_ENC_CSN_ID
	, ser_auth.PROV_NAME as authorizing_provider
	 ,dep_enc.DEPARTMENT_NAME as encounter_dept 
--	 , smrttxt.contact_serial_num
	, case when smrttxt.pat_enc_csn_id is null then 'No Smarttext'
		else 'Smarttext Usage'
	end SmartText_Usage
	,txt.NOTE_TEXT
	,txt.NOTE_ID
	,regexp_substr( REPLACE(txt.NOTE_TEXT,'.', ':' ),'[^:]+',1,2)  Indication_For_Intubation
	,regexp_substr( REPLACE(txt.NOTE_TEXT,'.', ':' ),'[^:]+',3,4)  as Sedation
		,regexp_substr( REPLACE(txt.NOTE_TEXT,'.', ':' ),'[^:]+',5,6)  as Paralytic
			,regexp_substr( REPLACE(txt.NOTE_TEXT,'.', ':' ),'[^:]+',7,8)  as Lidocaine
					,regexp_substr( REPLACE(txt.NOTE_TEXT,'.', ':' ),'[^:]+',9,10)  as Atropine
				,regexp_substr( REPLACE(txt.NOTE_TEXT,'.', ':' ),'[^:]+',11,12)  as Equipment
, SUBSTR(REPLACE(txt.NOTE_TEXT,'.', ':' ), INSTR(REPLACE(txt.NOTE_TEXT,'.', ':' ),'Number of attempts:')+19, 2)  as  Number_Of_Attempts

,ROW_NUMBER() OVER (PARTITION BY ord.ORDER_INST ORDER BY nei.CONTACT_NUM DESC) AS row_num
--	, ord_acc.*
from order_proc ord
	left outer join order_proc_2 ord2 on ord.ORDER_PROC_ID = ord2.ORDER_PROC_ID
	left outer join order_proc_3 ord3 on ord.ORDER_PROC_ID = ord3.order_id
	left outer join order_rad_acc_num ord_acc on ord.ORDER_PROC_ID = ord_acc.ORDER_PROC_ID
	left outer join clarity_eap eap on ord.PROC_ID = eap.proc_id
	left outer join patient pat on ord.pat_id = pat.pat_id
	left outer join pat_enc_hsp peh on ord.PAT_ENC_CSN_ID = peh.PAT_ENC_CSN_ID
	left outer join clarity_dep dep on peh.DEPARTMENT_ID = dep.DEPARTMENT_ID

	left outer join ZC_ORDER_STATUS zc_stat on ord.ORDER_STATUS_C = zc_stat.order_status_c

	left outer join clarity_ser ser_auth on ord.AUTHRZING_PROV_ID = ser_auth.PROV_ID
	left outer join clarity_dep dep_login on ord2.LOGIN_DEP_ID = dep_login.DEPARTMENT_ID
	left outer join clarity_dep dep_enc on ord2.PAT_LOC_ID = dep_enc.DEPARTMENT_ID
    left outer join smrt_usage smrttxt on ord.PAT_ENC_CSN_ID = smrttxt.pat_enc_csn_id
    left outer join note_enc_info nei on smrttxt.note_id = nei.note_id
    		and smrttxt.contact_num = nei.contact_num
    left outer join hno_note_text txt on nei.NOTE_ID = txt.note_id
			and nei.CONTACT_SERIAL_NUM = txt.NOTE_CSN_ID
where eap.proc_code IN ('PRO89')
	and ( 	trunc(peh.HOSP_ADMSN_TIME) >= '1-SEP-2019'
								and 
							trunc(peh.HOSP_ADMSN_TIME) <= '12-MAY-2020'
							)
				and peh.DEPARTMENT_ID IN ('1000102031', '1000105030', '1000108028', '1000102030')
         and ord.FUTURE_OR_STAND is null ) a  where Row_num =1 
