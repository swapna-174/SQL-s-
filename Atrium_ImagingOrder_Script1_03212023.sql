/*******************************************************************************************************************************************
10/1/2021
Created By: Michelle Tollison
Primary user: Vickie Bailey, Imaging QA and Compliance Coordinator  Work #: 704-512-4742
Desc: Radiology Extract for Nuclear Medicine Procedures sent daily for yesterday - Service Area 10

FileName:  AH_Rad_Daily_mmddyy.csv

Mod Log:        BID                 Date                 Modification
------------   -------------     ---------------      -------------------------
000             mtolli01          07/27/2022	       Implementation
001             mtolli01          08/31/2022           Added Physician Specialty 
002             mtolli01          09/23/2022           Added columns and additional Service Areas
*********************************************************************************************************************************************/

--DECLARE @START DATE = EPIC_UTIL.EFN_DIN('t-1')
--DECLARE @END DATE = EPIC_UTIL.EFN_DIN('t-0')  ;  
--DECLARE @sa NUMERIC = 10;	                                --002 Remarked out   Hardcoded in line 356

--DECLARE @START DATETIME = '12/01/2022'
--DECLARE @END DATETIME =  '03/31/2022'

----/** Fix start and end date **/
--SET @start = CONVERT(DATE,@start); --Drop to midnight
--SET @end = DATEADD(ms,-1, (DATEADD(DAY, +1, CONVERT(VARCHAR, @end, 101)))); --Convert to 23:59:59:999


with
Start_End_Date As (
    select EPIC_UTIL.EFN_DIN ('T-1')   START_DATE,  EPIC_UTIL.EFN_DIN ('T')  END_DATE from dual
)
,
Clin_Ind_Exam as (
    select 
        op.ORDER_PROC_ID 
        ,osq.ORD_QUEST_RESP CI_for_Exam
    from ORD_SPEC_QUEST osq
    join ORDER_PROC op on osq.ORDER_ID = op.ORDER_PROC_ID
    join CL_QQUEST_OVTM clo on osq.ORD_QUEST_ID = clo.QUEST_ID
    join CL_QQUEST clq on clq.QUEST_ID = clo.QUEST_ID
        and clo.QUEST_ID = '10552034'
    group by order_proc_id,osq.ORD_QUEST_RESP
)
,
PtPregnant as (
    select 
        op.ORDER_PROC_ID 
        ,osq.ORD_QUEST_RESP Pt_Pregnant
    from ORD_SPEC_QUEST osq
    join ORDER_PROC op on osq.ORDER_ID = op.ORDER_PROC_ID
    join CL_QQUEST_OVTM clo on osq.ORD_QUEST_ID = clo.QUEST_ID
     join CL_QQUEST clq on clq.QUEST_ID = clo.QUEST_ID and clo.QUEST_ID = '102064'
    group by order_proc_id,osq.ORD_QUEST_RESP
)
,

Fluoro as (
    select  
        ris.ORDER_PROC_ID,
        coalesce(cqa.QUEST_ANSWER,'')	FLUORO_TIME,
        max(cqa.LINE)  LINE
        FROM RIS_END_PROC_ANS ris
        join cl_qanswer_qa cqa on ris.end_proc_ans_id=cqa.answer_id
        join cl_qquest_ovtm cqo on cqa.quest_id=cqo.quest_id
            and cqa.quest_id = '1050207'
        group by 
            ris.ORDER_PROC_ID,
            cqa.QUEST_ANSWER
)
,


ordernotes as
(select risn.ORDER_PROC_ID
, hnot.NOTE_TEXT		NOTE_TEXT
from RIS_STUDY_NOTES risn
join HNO_INFO hnoi on risn.STUDY_NOTES_ID = hnoi.NOTE_ID  
join HNO_NOTE_TEXT hnot on hnot.NOTE_ID = hnoi.NOTE_ID
inner join
(select risn_b.ORDER_PROC_ID
, max(hnot_b.note_id) maxnoteid
from RIS_STUDY_NOTES risn_b
join HNO_INFO hnoi_b on risn_b.study_notes_id = hnoi_b.NOTE_ID
join HNO_NOTE_TEXT hnot_b on hnot_b.NOTE_ID = hnoi_b.NOTE_ID
group by risn_b.ORDER_PROC_ID) a
on a.ORDER_PROC_ID = risn.ORDER_PROC_ID and a.maxnoteid = hnoi.NOTE_ID
)
,
CDS as                       -- Clinical Decision Support
(select IMG_DECISION_SUP.ORDER_ID CDS_ORDER_ID
,IMG_DECISION_SUP.DS_SCORE_C 	  CDS_SCORE_CODE
, ZC_DS_SCORE.Name                CDS_SCORE_DESC
	----CLINICAL DECISION EXTRA FIELDS  09/22/2022--
 	, IMG_DECISION_SUP.DECISION_SUPPORT_ID  		                                                                                 SUPPORT_SESSION_ID                                 --002
	, zdsor.NAME                                                                                                                     SOURCE                                             --002
    , zvdr.NAME  		                                                                                                             VENDOR                                             --002
    , zind.NAME                                                                                                                      ADHERENCE_INDICATION                               --002
    --, to_char(cast(IMG_DECISION_SUP.DS_CONSULT_UTC_DTTM as timestamp) at time zone 'UTC', 'MM/DD/YYYY HH24:mi:ss')              DATE_TIME_CONSULTED                                --002
    , coalesce(to_char(IMG_DECISION_SUP.DS_CONSULT_UTC_DTTM,'MM/DD/YYYY HH24:mi:SS'),'')                   DATE_TIME_CONSULTED                                --002 local DATE_TIME_CONSULTED
    , zexc.NAME  	                                                                                                                 HARDSHIP_EMER_EXCEPTION                            --002
    , IMG_DECISION_SUP.DS_COMMENT                                                                                                  	 DECISION_SUPPORT_COMMENT                           --002
FROM  IMG_DECISION_SUP     --Link to Clinical Decision Support table
 JOIN ZC_DS_SCORE on ZC_DS_SCORE.DS_SCORE_C = IMG_DECISION_SUP.DS_SCORE_C    
 LEFT JOIN ZC_DS_SOURCE zdsor on IMG_DECISION_SUP.DS_SOURCE_C = zdsor.DS_SOURCE_C -- join to Decision Support Source								     	   --002 ADDED 09/22/2022
 LEFT JOIN ZC_DS_CDSM_VENDOR zvdr on  IMG_DECISION_SUP.DS_CDSM_VENDOR_C = zvdr.DS_CDSM_VENDOR_C -- join to Decision Support Vendor						       --002 ADDED 09/22/2022
 LEFT JOIN ZC_DS_ADHERENCE_IND zind on IMG_DECISION_SUP.DS_ADHERENCE_IND_C = zind.DS_ADHERENCE_IND_C  -- join to Decision Support Adherence Indication	       --002 ADDED 09/22/2022
 LEFT JOIN ZC_DS_EXCEPTION zexc on IMG_DECISION_SUP.DS_EXCEPTION_C = zexc.DS_EXCEPTION_C -- join to Decision Support Exception							       --002 ADDED 09/22/2022
  WHERE IMG_DECISION_SUP.line =1   --Clinical Decision Score Description
 )
,

LMP as                 -- OB/GYN data
	(SELECT
		vob.PAT_ENC_CSN_ID
	, lmp.name
	FROM 
	V_OB_ENC_OBGYN_STAT vob 
		JOIN zc_lmp_other lmp on lmp.LMP_OTHER_C = vob.OBGYN_STAT_C
)
, Order_Dx as                  --007 Order Diagnosis data
	(SELECT order_dx_proc.ORDER_PROC_ID
	,edg_adm.DX_NAME
	FROM  ORDER_DX_PROC 
	LEFT JOIN CLARITY_EDG EDG_ADM on EDG_ADM.DX_ID = order_dx_proc.DX_ID
	WHERE  order_dx_proc.LINE = 1
)
, PT_Class as                   -- Patient Class at time of order
( SELECT op5.ORDER_ID
, cls.NAME
, op5.RAD_EXAM_END_UTC_DTTM      
FROM  ORDER_PROC_5 op5 
 JOIN ZC_PAT_CLASS cls on op5.IMG_EXAM_PAT_CLASS_C = cls.ADT_PAT_CLASS_C	
 )
 ,

	ind as                   --Indications
	(Select oind.ORDER_ID
	,mci.MEDICAL_COND_NAME    		MEDICAL_COND_NAME
	from 
	  ORD_INDICATIONS oind  
	LEFT JOIN MEDICAL_COND_INFO mci on mci.MEDICAL_COND_ID = oind.INDICATIONS_ID 
	Where  oind.line = 1
)
,

Auth_MD as      --Authorizing MD
(select  AUTH.PROV_ID
, AUTH.PROV_NAME
, AUTH_MD.NPI
FROM CLARITY_SER AUTH 
LEFT JOIN CLARITY_SER_2 AUTH_MD	on AUTH_MD.PROV_ID =  AUTH.PROV_ID                                                     --Authorizing Provider NPI #
)
,
cpoe as      --CPOE data
(Select 
v_cpoe_info.ORDER_ID
,v_cpoe_info.PAT_ENC_CSN_ID
,v_cpoe_info.CPOE_YN
,v_cpoe_info.PER_PROTOCOL_MODE_YN
from v_cpoe_info 
)


,  RAStart as 
(SELECT
ROW_NUMBER()
OVER (
  PARTITION BY RASTART.ORDER_PROC_ID
   ORDER BY   RASTART.ORDER_PROC_ID, RASTART.AUDIT_TM   ) row_num_begin
,RASTART.ORDER_PROC_ID                                    "ORDER_ID" --ORD .1
,RASTART.AUDIT_TM                                         "CLICK_BEGIN" 
FROM ORDER_RAD_AUDIT RASTART
WHERE  RASTART.AUDIT_ACT_C = 2 --2 Exam Begin
)
,
RAEnd as 
(SELECT
ROW_NUMBER()
OVER (
  PARTITION BY RAEND.ORDER_PROC_ID
   ORDER BY  RAEND.ORDER_PROC_ID, RAEND.AUDIT_TM   )    row_num_end
,RAEND.ORDER_PROC_ID                                    "ORDER_ID" --ORD .1
,RAEND.AUDIT_TM                                            "CLICK_END" 
FROM ORDER_RAD_AUDIT RAEND 
WHERE  RAEND.AUDIT_ACT_C = 3 --3 Exam End
)

select
    coalesce( technologist.NAME,'')												        													TECHNOLOGIST
 	, loc.LOC_NAME																													    	FACILITY
	, performing.prov_name																													PERFORMING_RESOURCE_NAME
	, coalesce(vis.ACCESSION_NUM,'')																									    ACCESSION
	, case when vis.ORDER_PRIORITY_C = 2 then 'Yes' else 'No' END																			IS_STAT_EXAM	
	, zcop.NAME																																ORDER_PRIORITY_DESC
	, vis.ORDER_ID																															ORDER_ID
	, coalesce(cast(vis.HSP_ACCOUNT_ID AS VARCHAR(254)), '')																				HAR
	, coalesce(cast(HAR.PRIM_ENC_CSN_ID AS VARCHAR(254)),'')																			    CSN_ID
    , vis.PAT_MRN_ID																														VIS_MRN
	, vis.PAT_NAME																															PATIENT_NAME
	, SEX_BIRTH.NAME																														BIRTH_SEX_DESC		
	, SEX.NAME																																PAT_SEX_DESC
	, coalesce(to_char(pat.BIRTH_DATE,'MM/DD/YYYY HH24:mi:SS'),'')																			BIRTH_DATE
	, coalesce(pat.ZIP,'')																													ZIP	
	, vis.PROC_CODE																													        PROC_CODE
	, vis.PROC_NAME																														    PROC_DESC
	, coalesce(ZC_RADIOLOGY_STS.NAME,'')	        																						STUDY_STATUS_DESC		
	, coalesce(to_char(vis.ORDERING_DTTM,'MM/DD/YYYY HH24:mi:SS'),'')         		     					                                ORDERED_DT_TM
	, coalesce(to_char(vis.SCHED_ON_DTTM,'MM/DD/YYYY HH24:mi:SS'),'')		     					                                        SCHED_ON_DTTM
	, coalesce(to_char(vis.SCHED_EXAM_DTTM,'MM/DD/YYYY HH24:mi:SS'),'')                                                                     SCHED_EXAM_DT_TM
	, coalesce(to_char(vis.CHECKIN_DTTM,'MM/DD/YYYY HH24:mi:SS'),'')                                                                        CHECKIN_DT_TM
	, coalesce(to_char(vis.BEGIN_EXAM_DTTM,'MM/DD/YYYY HH24:mi:SS'),'')                                                                     BEGIN_EXAM_DTTM
    --, to_char(cast(pt_class.RAD_EXAM_END_UTC_DTTM as timestamp) at time zone 'UTC', 'MM/DD/YYYY HH24:mi:ss')   END_EXAM_DTTM
    , coalesce(to_char(pt_class.RAD_EXAM_END_UTC_DTTM,'MM/DD/YYYY HH24:mi:SS'),'')   END_EXAM_DTTM
    , coalesce(to_char(vis.PRELIM_DTTM,'MM/DD/YYYY HH24:mi:SS'),'')			                        PRELIM_DT_TM	
	, coalesce(prelim.NAME,'')                                                                                                                PRELIM_USER
	, coalesce(to_char(vis.FINALIZING_DTTM,'MM/DD/YYYY HH24:mi:SS'),'')		 				    FINAL_DT_TM
	, coalesce(to_char(ora.ADDENDED_TM,'MM/DD/YYYY HH24:mi:SS'),'')			 				    ADDENDUM_DT_TM
	, coalesce(pt_class.name,'')                                                                                                              PT_CLASS_TIME_OF_ORDER
	, ordering.PROV_NAME                                                                                                                    ORDERING_MD
	, ordering.PROV_ID                                                                                                                      ORDERING_PROV_ID
	, coalesce(clarity_ser_2.NPI,'')	                                                                                                        ORDERING_NPI
	, coalesce(FINALIZING.PROV_NAME,'')                                                                                                       INTERPRETING_MD
	, coalesce(Order_Dx.DX_NAME,'')                                                                                                           ASSOCIATED_DX	
	, coalesce(hdep.DEPARTMENT_NAME,'')                                                                                                       UNIT                    
	, rom.ROOM_NAME || '-' || bed.BED_LABEL                                                                                              ROOM_BED
	, coalesce(CAST(enc.LMP_DATE AS VARCHAR(254)),'')                                                                                           LMP_DATE
	, coalesce(lmp.name, '')                                                                                                                  OBGYN_STAT_DESC
	, coalesce(PtPregnant.Pt_Pregnant,'')																									    PT_PREGNANT_YN
	, coalesce(Clin_Ind_Exam.CI_for_Exam,'')																								    CLINICAL_INDICATION_FOR_EXAM
	, coalesce(CAST(har.PRIMARY_PAYOR_ID AS VARCHAR(254)),'')																				    HAR_PAYOR_ID
	, coalesce(epm.PAYOR_NAME,'')																											    PAYOR_NAME
    , coalesce(vom_p.NAME,'')                                                                                                                  COMMUNICATION_TYPE
	, coalesce(ZC_ORDER_CLASS.NAME,'')                                                                                                        ORDER_CLASS_DESC       --ORD 60		
	--, coalesce(Fluoro_Guide.FLUORO_GUIDANCE_REQD,'')                                                                                          FLUORO_GUIDANCE
	, coalesce(Fluoro.FLUORO_TIME,'')                                                                                                         FLUORO_TIME
	--, coalesce(Fluoro_Images.Nbr_Images,'')                                                                                                   FL_NBR_IMAGES
	--, coalesce(AirKerma.AIR_KERMA,'')                                                                                                         AIR_KERMA
	--, coalesce(AirKerma_UOM.AIR_KERMA_UOM,'')                                                                                                 AIR_KERMA_UOM
	--, coalesce(KermaAreaProduct.kap,'')																								        KAP
	---, coalesce(KermaAreaProduct_UOM.KAP_UOM,'')                                                                                               KAP_UOM
    , coalesce(ind.MEDICAL_COND_NAME,'')																									    MEDICAL_COND_E_REASON_FOR_EXAM
    , coalesce(clr.REASON_VISIT_NAME,'')		     		                                                                                    REASON_FOR_VISIT
    , coalesce(to_char(rsn.CONTACT_DATE,'MM/DD/YYYY'),'')                                                                                      REASON_VISIT_CONTACT_DATE   
    , coalesce(op4.INDICATION_COMMENTS,'')																								    INDICATION_COMMENTS
    , coalesce(ordernotes.NOTE_TEXT,'')																									    ORDER_NOTE_TEXT
    , coalesce(cast(PAT_LIFEDOSE_HX.SIMP_DOSE_AMT AS VARCHAR(254)),'')                                                                           FLUORO_SIMP_DOSE_AMT        
    , coalesce(ZC_MED_UNIT.NAME, '')                                                                                                          FLUORO_TIME_UNIT            
    , coalesce(to_char(op_parent.PROC_END_TIME,'MM/DD/YYYY HH24:mi:SS'),'') 		            PROC_END_EXAM_DTTM       
    , auth_md.PROV_NAME                                                                                                                     AUTHORIZING_PROV_ID
    , coalesce(auth_md.npi,'')																	  										    AUTHORIZING_PROV_NPI
    , coalesce(CDS_SCORE_CODE,'')                                                                                          CDS_SCORE
    , coalesce(cds.CDS_SCORE_DESC,'')                                                                                                         CDS_SCORE_DESC

    , coalesce(zcr.NAME,'')                                                                                                                   CHANGE_REASON_DESC
    , coalesce(op2.CHANGE_CMT,'')                                                                                                             CHANGE_COMMENT
    , coalesce(CPOE.CPOE_YN,'')                                                                                                               CPOE_YN                     
    , coalesce(CPOE.PER_PROTOCOL_MODE_YN,'')                                                                                                  CPOE_PER_PROTOCOL_MODE_YN   
    , coalesce(CASE WHEN INSTR(ordering.PROV_NAME, ',') > 1 THEN  SUBSTR(ordering.PROV_NAME, 1, INSTR(ordering.PROV_NAME, ',') - 1) else ordering.PROV_NAME end, '')                ORDERED_BY_LAST_NAME 
    , coalesce(CASE WHEN INSTR(emp_parent.NAME, ',') > 1 THEN  SUBSTR(emp_parent.NAME, 1, INSTR(emp_parent.NAME, ',') - 1) else emp_parent.NAME end, '')                PARENT_ORDER_ENTERED_BY_LAST_NAME  
    , EDP_PROC_CAT_INFO.PROC_CAT_NAME                                                                                                       MODALITY          -- EDP .2 
    , coalesce(to_char(RASTART.CLICK_BEGIN,'MM/DD/YYYY HH24:mi:SS'),'')                         CLICK_BEGIN     
    , coalesce(to_char(RAEND.CLICK_END,'MM/DD/YYYY HH24:mi:SS'),'')                                 CLICK_END       
    --, COALESCE(referral.referral_id,enc.REFERRAL_ID)                                                                                        ENC_REFERRAL_ID                               --001 ADDED 08/29/2022
    , coalesce(spec.NAME,'')                                                                                                                  PRIMARY_SPECIALTY                                           --001 ADDED 08/29/2022
    , coalesce(vloc.LOCATION_NAME,'')                                                                                                         PRACTICE_NAME                                               --002 ADDED
    , case when addr.ADDR_LINE_1 is not null then addr.ADDR_LINE_1 || ', ' else null end || 
        case when addr.ADDR_LINE_2 is not null then addr.ADDR_LINE_2 || ', ' else null end || 
        case when addr.city is not null then addr.city || ', ' else null end || 
        case when zc_state.ABBR is not null then zc_state.ABBR || '  ' else null end || addr.ZIP as     PRACTICE_ADDRESS               --002
    , coalesce(ordering.REFERRAL_SOURCE_TYPE,'')                                                                                              "INT/EXT"                                                     --002


----CLINICAL DECISION EXTRA FIELDS  09/22/2022--
    , coalesce(cds.SUPPORT_SESSION_ID,'')                                                                                                   SUPPORT_SESSION_ID                                          --002
    , coalesce(cds.SOURCE,'')                                                                                                               SOURCE                                                      --002
    , coalesce(cds.VENDOR,'')                                                                                                               VENDOR                                                      --002
    , coalesce(cds.ADHERENCE_INDICATION,'')                                                                                                 ADHERENCE_INDICATION                                        --002
    , coalesce(cds.DATE_TIME_CONSULTED,'')                                                                                                  DATE_TIME_CONSULTED                                         --002
    , coalesce(cds.HARDSHIP_EMER_EXCEPTION,'')                                                                                              HARDSHIP_EMER_EXCEPTION                                     --002
    , coalesce(cds.DECISION_SUPPORT_COMMENT,'')                                                                                             DECISION_SUPPORT_COMMENT                                    --002

FROM (
    select oraud.ORDER_PROC_ID
		, max(oraud.line) line	
		from ORDER_RAD_AUDIT oraud	
	where    oraud.AUDIT_TM >= (SELECT START_DATE  FROM  START_END_DATE) and oraud.AUDIT_TM < (SELECT END_DATE  FROM  START_END_DATE) --between @start and @end
	and oraud.AUDIT_ORDER_STAT_C in ('1','30', '70', '99')    --1-Ordered, 30-Exam Ended, 70-Preliminary, 99-Final
		group by oraud.ORDER_PROC_ID
) oraud                -- pulls order_proc_id's where an audit action occurred on the previous day

JOIN V_IMG_STUDY vis	on oraud.ORDER_PROC_ID = vis.ORDER_ID 		and vis.ACCESSION_NUM is not null
JOIN CLARITY_LOC loc on vis.PERFORMING_LOC_ID = loc.LOC_ID  ---and loc.SERV_AREA_ID = '10'                                                                                                                    --002 10-AH
JOIN  	ORDER_PROC op_parent on vis.ORDER_ID= op_parent.ORDER_PROC_ID
join clarity_eap eap on vis.proc_id = eap.proc_id 
join edp_proc_cat_info edp on eap.proc_cat_id = edp.proc_cat_id
JOIN CLARITY_EMP emp_parent on emp_parent.USER_ID = op_parent.ord_creatr_user_id   
LEFT JOIN PAT_ENC enc on op_parent.pat_enc_csn_id  = enc.pat_enc_csn_id                   
JOIN PATIENT pat on vis.PAT_ID=pat.pat_id                                                                         
JOIN IDENTITY_ID id	on id.PAT_ID = pat.PAT_ID and id.IDENTITY_TYPE_ID = '14' --AH
JOIN VALID_PATIENT vp ON vis.PAT_ID = vp.PAT_ID and vp.IS_VALID_PAT_YN = 'Y'
JOIN CLARITY_SER ordering on vis.ORDERING_PROV_ID = ordering.PROV_ID                                                                             --Ordering
 JOIN EDP_PROC_CAT_INFO on vis.PROC_CAT_ID = EDP_PROC_CAT_INFO.PROC_CAT_ID                                                                       --Modality
LEFT JOIN PAT_ENC_RSN_VISIT rsn ON vis.ORDERING_CSN_ID = rsn.PAT_ENC_CSN_ID AND rsn.LINE = '1' --Join to get ordering visit reason for visit to get injury
LEFT JOIN CL_RSN_FOR_VISIT clr ON rsn.ENC_REASON_ID = clr.REASON_VISIT_ID --Join for reason info

LEFT JOIN order_proc_4 op4 on vis.ORDER_ID = op4.ORDER_ID
LEFT JOIN order_proc_3 op3 on vis.ORDER_ID = op3.ORDER_ID

LEFT JOIN order_proc_2 op2 on vis.ORDER_ID = op2.ORDER_PROC_ID
LEFT JOIN ZC_CHANGE_REASON zcr on op2.CHANGE_REASON_C = zcr.CHANGE_REASON_C               

--Parent Order--
LEFT JOIN ORDER_SIGNED_PROC osp_parent	on osp_parent.ORDER_PROC_ID = op_parent.ORDER_PROC_ID and osp_parent.LINE = 1    
LEFT JOIN ZC_VERB_ORD_MODE vom_p on osp_parent.VERBAL_MODE_C = vom_p.VERBAL_MODE_C                                                       


LEFT JOIN ORDER_RAD_ADDEND ora  ON vis.ORDER_ID = ora.ORDER_ID AND ora.line = 1 and  ora.ADDENDUM_STATUS_C = 2    --Join to get to adendum signed note associated with the order
----LEFT JOIN ORDER_RAD_ACC_NUM oran on vis.ORDER_PROC_ID=oran.ORDER_PROC_ID   
LEFT JOIN HSP_ACCOUNT har ON vis.HSP_ACCOUNT_ID = har.HSP_ACCOUNT_ID                                                                                                       --Join for har account information
LEFT JOIN PAT_ENC_HSP peh ON har.PRIM_ENC_CSN_ID = peh.PAT_ENC_CSN_ID                                                                                                       --Join primary encounter on account

LEFT JOIN ED_ROOM_INFO rom ON peh.ROOM_ID = rom.ROOM_ID                                                                                                                    --Join for room info
LEFT JOIN (SELECT DISTINCT BED_ID, BED_LABEL FROM CLARITY_BED WHERE RECORD_STATE IS NULL) bed ON peh.BED_ID = bed.BED_ID --Join for bed info
LEFT JOIN CLARITY_DEP denc ON enc.DEPARTMENT_ID = denc.DEPARTMENT_ID                                                                           --Join for ordering department info
LEFT JOIN CLARITY_DEP hdep ON peh.DEPARTMENT_ID = hdep.DEPARTMENT_ID                                                                          --Join for hospital encounter department

LEFT JOIN zc_sex sex on sex.RCPT_MEM_SEX_C = pat.SEX_C                                                   --Gender
LEFT JOIN PATIENT_4	pat4 on pat4.pat_id = vis.PAT_ID
LEFT JOIN ZC_SEX_ASGN_AT_BIRTH sex_birth on pat4.SEX_ASGN_AT_BIRTH_C = SEX_BIRTH.SEX_ASGN_AT_BIRTH_C    --Sex Assigned at Birth Description
                         
LEFT JOIN ZC_RADIOLOGY_STS on ZC_RADIOLOGY_STS.RADIOLOGY_STATUS_C = vis.STUDY_STATUS_C                  --Study Status Description
LEFT JOIN PAT_LIFEDOSE_HX on vis.ORDER_ID = PAT_LIFEDOSE_HX.ORDER_MED_ID 
--AND PAT_LIFEDOSE_HX.CHEMICAL_C = '118001' 
and  PAT_LIFEDOSE_HX.LINE = '1'      --Join to return Fluoro Time
LEFT JOIN ZC_MED_UNIT on PAT_LIFEDOSE_HX.SIMP_DOSE_UNIT_C = ZC_MED_UNIT.DISP_QTYUNIT_C                                                                  --Join to return Fluoro Time Unit


 --CTE's--                                            
LEFT JOIN Clin_Ind_Exam on Clin_Ind_Exam.ORDER_PROC_ID =vis.ORDER_ID  
LEFT JOIN PtPregnant ON PtPregnant.ORDER_PROC_ID =vis.ORDER_ID  
---LEFT JOIN Fluoro_Guide on Fluoro_Guide.ORDER_PROC_ID = vis.ORDER_ID  
LEFT JOIN Fluoro on Fluoro.ORDER_PROC_ID = vis.ORDER_ID  
--LEFT JOIN Fluoro_Images on Fluoro_Images.ORDER_PROC_ID =vis.ORDER_ID 
--LEFT JOIN AirKerma on AirKerma.ORDER_PROC_ID = vis.ORDER_ID 
--LEFT JOIN AirKerma_UOM on AirKerma_UOM.ORDER_PROC_ID = vis.ORDER_ID 
--LEFT JOIN KermaAreaProduct on KermaAreaProduct.ORDER_PROC_ID = vis.ORDER_ID 
---LEFT JOIN KermaAreaProduct_UOM on KermaAreaProduct_UOM.ORDER_PROC_ID =vis.ORDER_ID 
LEFT JOIN ordernotes on ordernotes.ORDER_PROC_ID = vis.ORDER_ID  
LEFT JOIN CDS ON CDS.CDS_ORDER_ID = vis.ORDER_ID                                           
LEFT JOIN LMP on LMP.PAT_ENC_CSN_ID = enc.PAT_ENC_CSN_ID                                   
LEFT JOIN order_dx on vis.order_id = order_dx.ORDER_PROC_ID                                
LEFT JOIN pt_class on vis.order_id =pt_class.ORDER_ID                                      
LEFT JOIN ind on vis.order_id = ind.ORDER_ID                                               
JOIN auth_md on vis.AUTHORIZING_PROV_ID = auth_md.prov_id                                  
LEFT JOIN cpoe on vis.ORDER_ID = cpoe.ORDER_ID                                             

 LEFT JOIN RASTART on vis.ORDER_ID = rastart.ORDER_ID  and RASTART.row_num_begin = 1 
 LEFT JOIN RAEND on vis.ORDER_ID = raend.ORDER_ID and RAEND.row_num_end = 1 
 
--Staff--
LEFT JOIN CLARITY_EMP technologist on technologist.USER_ID = VIS.TECH_USER_ID
LEFT JOIN CLARITY_EMP prelim on prelim.USER_ID = VIS.PRELIM_USER_ID
LEFT JOIN CLARITY_SER performing on vis.PERFORMING_PROV_ID = performing.PROV_ID               --Performing Provider Name  
LEFT JOIN CLARITY_SER_2 on clarity_ser_2.PROV_ID =  ordering.PROV_ID                          --Ordering Provider NPI #
LEFT JOIN CLARITY_SER finalizing on vis.FINALIZING_PROV_ID = finalizing.PROV_ID               --Finalizing Provider Name

LEFT OUTER JOIN CLARITY_SER_SPEC css on css.PROV_ID = ordering.PROV_ID  and css.LINE = 1                                                        --ADDED 08/29/2022
LEFT OUTER JOIN ZC_SPECIALTY spec on spec.SPECIALTY_C = css.SPECIALTY_C   

LEFT OUTER JOIN clarity_ser_addr addr on addr.PROV_ID = ordering.PROV_ID and addr.LINE = 1                                                      --002 ADDED 09/15/2022
LEFT OUTER JOIN v_cube_d_location vloc on addr.ADDR_LINK_LOC_ID = vloc.LOCATION_ID                                                              --002 ADDED 09/15/2022


--ZC Tables--
LEFT JOIN ZC_ORDER_PRIORITY zcop on zcop.ORDER_PRIORITY_C = vis.ORDER_PRIORITY_C              --Order Priority Description     
LEFT JOIN clarity_epm epm on epm.PAYOR_ID = har.PRIMARY_PAYOR_ID                              --Primary Payor ID
LEFT JOIN ZC_ORDER_CLASS on op_parent.ORDER_CLASS_C = ZC_ORDER_CLASS.ORDER_CLASS_C
LEFT JOIN ZC_STATE on addr.STATE_C = ZC_STATE.STATE_C

WHERE 1=1

and vis.STUDY_STATUS_C not in ('4','5','7')  -- 4=No Show, 5=Scheduled, 7=Arrived
 
 ORDER BY 
 vis.ACCESSION_NUM
,vis.ORDER_ID



