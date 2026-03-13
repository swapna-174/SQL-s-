 /*******************************************************************************************************************************************
10/1/2021
Created By: Michelle Tollison
Primary user: Vickie Bailey, Imaging QA and Compliance Coordinator  Work #: 704-512-4742
Desc: Additional fields for Radiology Extract for Procedures sent daily for yesterday - Service Area 10. 

FileName:  AH_Rad_Daily_2_mmddyy.csv

Mod Log:        BID               Date                 Modification
------------   -------------     ---------------      -------------------------
000             mtolli01          10/26/2022	       Implementation
001             mtolli01          12/16/2022	       Added Order Scheduled Notes
002             mtolli01          02/21/2023	       REQ1367604 - Added Times for In Room & Out Room; Updated Where clause; Updated Scheduled Notes Field
*********************************************************************************************************************************************/


--DECLARE @START DATETIME = '10/25/2022'
--DECLARE @END DATETIME   = '10/26/2022'

----/** Fix start and end date **/
--SET @start = CONVERT(DATE,@start); --Drop to midnight
--SET @end = DATEADD(ms,-1, (DATEADD(DAY, +1, CONVERT(VARCHAR, @end, 101)))); --Convert to 23:59:59:999


with 

MedRoute as 
(SELECT prm.ORDER_ID 
,ZC_DISPENSE_ROUTE.Name     DISPENSED_ROUTE
FROM PROC_RELATED_MEDS prm
LEFT OUTER JOIN order_Med on order_med.ORDER_MED_ID = prm.PROC_REL_MEDS_ID 
LEFT OUTER JOIN ZC_DISPENSE_ROUTE on ZC_DISPENSE_ROUTE.DISPENSE_ROUTE_C = order_med.MED_ROUTE_C
WHERE prm.LINE = 1
)
, --002 ADDED
  In_Room  as                          
(SELECT orl.LOG_ID
---,convert(varchar,olct.TRACKING_TIME_IN,101)  +' '+ convert(varchar(5),olct.TRACKING_TIME_IN,108)           [In Room]
,TO_CHAR (TRACKING_TIME_IN, 'MM/DD/YYYY HH24:MI') Inroom
, olct.line
FROM  or_log orl
join OR_LOG_CASE_TIMES olct on olct.LOG_ID = orl.LOG_ID 
left outer join ZC_OR_PAT_EVENTS zcpe on zcpe.TRACKING_EVENT_C = olct.TRACKING_EVENT_C 
WHERE  olct.TRACKING_EVENT_C = '60' --In Room
)  
, --002 ADDED
 Out_Room  as        
(SELECT orl.LOG_ID
---, convert(varchar,olct.TRACKING_TIME_IN,101)  +' '+  convert(varchar(5),olct.TRACKING_TIME_IN,108)         OutRoom
,TO_CHAR (TRACKING_TIME_IN, 'MM/DD/YYYY HH24:MI') OutRoom
, olct.line
FROM  or_log orl
join OR_LOG_CASE_TIMES olct on olct.LOG_ID = orl.LOG_ID 
left outer join ZC_OR_PAT_EVENTS zcpe on zcpe.TRACKING_EVENT_C = olct.TRACKING_EVENT_C 
WHERE  olct.TRACKING_EVENT_C = '110' --Out Room
)  
, --002 ADDED
 Proc_Finished  as                         
(SELECT orl.LOG_ID
----, convert(varchar,olct.TRACKING_TIME_IN,101) +' '+  convert(varchar(5),olct.TRACKING_TIME_IN,108)         [Time Finished]
,TO_CHAR (TRACKING_TIME_IN, 'MM/DD/YYYY HH24:MI') TimeFinished
, olct.line
FROM  or_log orl
join OR_LOG_CASE_TIMES olct on olct.LOG_ID = orl.LOG_ID 
left outer join ZC_OR_PAT_EVENTS zcpe on zcpe.TRACKING_EVENT_C = olct.TRACKING_EVENT_C 
WHERE  olct.TRACKING_EVENT_C = '390' --Out Room
)

SELECT
 
	nvl(vis.ACCESSION_NUM,'')																									        ACCESSION
	, vis.ORDER_ID																															ORDER_ID
    , refdep.DEPARTMENT_NAME                                                                                                                REFERRAL_DEPT          
    , vis.NUM_CPT_CODES                                                                                                                     NUM_CPT_CODES			
    , op2.READING_PRIORITY_C                                                                                                                READING_PRIORITY		
    , MedRoute.DISPENSED_ROUTE                                                                                                              MED_DISPENSED_ROUTE	
	,  nvl(STUFF((
         SELECT (', '|| ord_sched_notes.order_sched_notes  )       -- SQLINES DEMO ***  if this corrected error in SSIS pkg
		 -- SQLINES DEMO *** ched_notes.order_sched_notes  )      --002 REMOVED - getting a column length exceeded msg in SSIS pkg
             FROM ord_sched_notes 
			  WHERE ord_sched_notes.order_id = vis.ORDER_ID                     
		  FOR XML PATH('')
         ), 1, 1, ''),'') AS ORD_SCHED_NOTES                                                                                                                                                   --001
    , nvl(in_room."In Room",'')                                     "Time In"                                                                                                       -- SQLINES DEMO ***                                    
    , coalesce(Out_Room."Out Room" ,Proc_Finished."Time Finished",'' ) "Time Out"                                                                                           --002    
FROM (SELECT oraud.ORDER_PROC_ID
		, max(oraud.line) line	
		FROM ORDER_RAD_AUDIT oraud	
	WHERE  oraud.AUDIT_TM between v_START and v_END
	    AND oraud.AUDIT_ORDER_STAT_C in ('1','30', '70', '99')    -- SQLINES DEMO ***  Ended, 70-Preliminary, 99-Final
		GROUP BY oraud.ORDER_PROC_ID) as oraud                -- pulls order_proc_id's where an audit action occurred on the previous day

JOIN V_IMG_STUDY vis		on oraud.ORDER_PROC_ID = vis.ORDER_ID 				and vis.ACCESSION_NUM is not null
JOIN CLARITY_LOC loc on vis.PERFORMING_LOC_ID = loc.LOC_ID  and loc.SERV_AREA_ID = 10 
--JOIN  	ORDER_PROC op_parent on vis.ORDER_ID= op_parent.ORDER_PROC_ID
--LEFT JOIN PAT_ENC enc on op_parent.pat_enc_csn_id  = enc.pat_enc_csn_id                   
--JOIN PATIENT pat on vis.PAT_ID=pat.pat_id                                                                         
--JOIN IDENTITY_ID id	on id.PAT_ID = pat.PAT_ID and id.IDENTITY_TYPE_ID = '14' --AH
JOIN VALID_PATIENT vp ON vis.PAT_ID = vp.PAT_ID and vp.IS_VALID_PAT_YN = 'Y'
--JOIN CLARITY_SER ordering on vis.ORDERING_PROV_ID = ordering.PROV_ID                                                                          --Ordering

LEFT JOIN order_proc_2 op2 on vis.ORDER_ID = op2.ORDER_PROC_ID
--LEFT JOIN ORDER_SIGNED_PROC osp_parent	on osp_parent.ORDER_PROC_ID = op_parent.ORDER_PROC_ID and osp_parent.LINE = 1                         --Parent Order
LEFT OUTER JOIN REFERRAL on REFERRAL.REFERRAL_ID = vis.REFERRAL_ID                                                                            --Referring Department ID
LEFT OUTER JOIN CLARITY_DEP refdep on REFERRAL.REFD_BY_DEPT_ID = refdep.DEPARTMENT_ID													      --Referring Department Name
LEFT OUTER JOIN MedRoute on medroute.ORDER_ID = vis.ORDER_ID																			      --Medication Route
LEFT OUTER JOIN In_Room on In_Room.LOG_ID = vis.LOG_ID                                                                                                                       --002
LEFT OUTER JOIN Out_Room on Out_Room.LOG_ID = vis.LOG_ID 					                                                                                                 --002
LEFT OUTER JOIN Proc_Finished on Proc_Finished.LOG_ID = vis.LOG_ID 			                                                                                                 --002
WHERE  (vis.PROC_CODE like 'NUC%'  
          OR vis.PROC_CODE like 'IMG%')  --'NUC%' or 'IMG%'                                                                                                                  --002 
       AND vis.STUDY_STATUS_C not in ('4','5','7')  -- 4=No Show, 5=Scheduled, 7=Arrived 

 ORDER BY 
 vis.ACCESSION_NUM
,vis.ORDER_ID


