/*******************************************************************************************************************************************
10/1/2021
Created By: Michelle Tollison
Primary user: Vickie Bailey, Imaging QA and Compliance Coordinator  Work #: 704-512-4742
Desc: Additional fields for Radiology Extract for Procedures sent daily for yesterday - Service Area 10. 

FileName:  AH_Rad_Daily_2_mmddyy.csv

Mod Log:        BID               Date                 Modification
------------   -------------     ---------------      -------------------------
000             mtolli01          10/26/2022               Implementation
001             mtolli01          12/16/2022               Added Order Scheduled Notes
002             mtolli01          02/21/2023               REQ1367604 - Added Times for In Room & Out Room; Updated Where clause; Updated Scheduled Notes Field
*********************************************************************************************************************************************/


--DECLARE @START DATETIME = '10/25/2022'
--DECLARE @END DATETIME   = '10/26/2022'

----/** Fix start and end date **/
--SET @start = CONVERT(DATE,@start); --Drop to midnight
--SET @end = DATEADD(ms,-1, (DATEADD(DAY, +1, CONVERT(VARCHAR, @end, 101)))); --Convert to 23:59:59:999


with

Start_End_Date As (select EPIC_UTIL.EFN_DIN('t-1') as START_DATE, EPIC_UTIL.EFN_DIN('t-0') as END_DATE, 10 as SA from dual)
,

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
,TO_CHAR (PROC_BGN_TIME, 'MM/DD/YYYY HH24:MI') Inroom
, OR_LOG_CASE_TIMES.line
FROM   order_proc  order_proc
join clarity.PAT_OR_ADM_LINK  on order_proc.PAT_ENC_CSN_ID = PAT_OR_ADM_LINK.PAT_ENC_CSN_ID
 join clarity.OR_LOG_CASE_TIMES  on PAT_OR_ADM_LINK.LOG_ID = OR_LOG_CASE_TIMES.LOG_ID
join or_log orl on OR_LOG_CASE_TIMES.LOG_ID = orl.LOG_ID 
left outer join ZC_OR_PAT_EVENTS zcpe on zcpe.TRACKING_EVENT_C = OR_LOG_CASE_TIMES.TRACKING_EVENT_C 
--WHERE  OR_LOG_CASE_TIMES.TRACKING_EVENT_C = '60' --In Room
)  
, --002 ADDED
Out_Room  as        
(SELECT orl.LOG_ID
---, convert(varchar,olct.TRACKING_TIME_IN,101)  +' '+  convert(varchar(5),olct.TRACKING_TIME_IN,108)         OutRoom
,TO_CHAR (PROC_END_TIME, 'MM/DD/YYYY HH24:MI') OutRoom
, OR_LOG_CASE_TIMES.line
FROM   order_proc  order_proc
join clarity.PAT_OR_ADM_LINK  on order_proc.PAT_ENC_CSN_ID = PAT_OR_ADM_LINK.PAT_ENC_CSN_ID
 join clarity.OR_LOG_CASE_TIMES  on PAT_OR_ADM_LINK.LOG_ID = OR_LOG_CASE_TIMES.LOG_ID
join or_log orl on OR_LOG_CASE_TIMES.LOG_ID = orl.LOG_ID 
left outer join ZC_OR_PAT_EVENTS zcpe on zcpe.TRACKING_EVENT_C = OR_LOG_CASE_TIMES.TRACKING_EVENT_C 
WHERE  OR_LOG_CASE_TIMES.TRACKING_EVENT_C = '110' --Out Room
)  
, --002 ADDED
Proc_Finished  as                         
(SELECT orl.LOG_ID,order_proc.ORDER_PROC_ID
----, convert(varchar,olct.TRACKING_TIME_IN,101) +' '+  convert(varchar(5),olct.TRACKING_TIME_IN,108)         [Time Finished]
,TO_CHAR (PROC_END_TIME, 'MM/DD/YYYY HH24:MI') TimeFinished
, OR_LOG_CASE_TIMES.line
FROM   order_proc  order_proc
join clarity.PAT_OR_ADM_LINK  on order_proc.PAT_ENC_CSN_ID = PAT_OR_ADM_LINK.PAT_ENC_CSN_ID
 join clarity.OR_LOG_CASE_TIMES  on PAT_OR_ADM_LINK.LOG_ID = OR_LOG_CASE_TIMES.LOG_ID
join or_log orl on OR_LOG_CASE_TIMES.LOG_ID = orl.LOG_ID 
left outer join ZC_OR_PAT_EVENTS zcpe on zcpe.TRACKING_EVENT_C = OR_LOG_CASE_TIMES.TRACKING_EVENT_C 
---WHERE  OR_LOG_CASE_TIMES.TRACKING_EVENT_C = '390' --Out Room
)

SELECT

                nvl(vis.ACCESSION_NUM,'')                                                                                                                                                                                                                                                                                                                                                                                                                 ACCESSION
                , vis.ORDER_ID                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ORDER_ID
    , refdep.DEPARTMENT_NAME                                                                                                                REFERRAL_DEPT          
    , vis.NUM_CPT_CODES                                                                                                                     NUM_CPT_CODES                                       
    , op2.READING_PRIORITY_C                                                                                                                READING_PRIORITY                 
    , MedRoute.DISPENSED_ROUTE                                                                                                              MED_DISPENSED_ROUTE
    , (
        select distinct
            listagg(ord_sched_notes.order_sched_notes, ', ') over (partition by ord_sched_notes.order_id)
        FROM ord_sched_notes where ord_sched_notes.order_id = vis.ORDER_ID
    ) as ORD_SCHED_NOTES
    /*
                ,  nvl(STUFF((
         SELECT (', '|| ord_sched_notes.order_sched_notes  )       -- SQLINES DEMO ***  if this corrected error in SSIS pkg
                                -- SQLINES DEMO *** ched_notes.order_sched_notes  )      --002 REMOVED - getting a column length exceeded msg in SSIS pkg
             FROM ord_sched_notes 
                                                  WHERE ord_sched_notes.order_id = vis.ORDER_ID                     
                                  FOR XML PATH('')
         ), 1, 1, ''),'') AS ORD_SCHED_NOTES                                                                                                                                                   --001
         */
    , nvl(order_proc.PROC_BGN_TIME,'')                                     "Time In"                                                                                                       -- SQLINES DEMO ***                                    
    , nvl(order_proc.PROC_END_TIME,'' ) "Time Out"                                                                                           --002    
FROM (
    SELECT 
        oraud.ORDER_PROC_ID
                                , max(oraud.line) line     
                FROM ORDER_RAD_AUDIT oraud             
                WHERE  oraud.AUDIT_TM between '01-Jan-2022' and '31-DEC-2022'
                    AND oraud.AUDIT_ORDER_STAT_C in ('1','30', '70', '99')    -- SQLINES DEMO ***  Ended, 70-Preliminary, 99-Final
                GROUP BY oraud.ORDER_PROC_ID
) oraud                -- pulls order_proc_id's where an audit action occurred on the previous day

JOIN V_IMG_STUDY vis                 on oraud.ORDER_PROC_ID = vis.ORDER_ID                                                          and vis.ACCESSION_NUM is not null
JOIN 	order_proc order_proc	on 	vis.ORDER_ID =order_proc.ORDER_PROC_ID 
JOIN CLARITY_LOC loc on vis.PERFORMING_LOC_ID = loc.LOC_ID  and loc.SERV_AREA_ID = 10 

JOIN VALID_PATIENT vp ON vis.PAT_ID = vp.PAT_ID and vp.IS_VALID_PAT_YN = 'Y'
                                                                --Ordering
LEFT JOIN order_proc_2 op2 on vis.ORDER_ID = op2.ORDER_PROC_ID
                      --Parent Order
LEFT OUTER JOIN REFERRAL on REFERRAL.REFERRAL_ID = vis.REFERRAL_ID                                                                            --Referring Department ID
LEFT OUTER JOIN CLARITY_DEP refdep on REFERRAL.REFD_BY_DEPT_ID = refdep.DEPARTMENT_ID                                                                                                                                                                                                                  --Referring Department Name
LEFT OUTER JOIN MedRoute on medroute.ORDER_ID = vis.ORDER_ID                                                                                                                                                                                                                                                                                                            --Medication Route                                                                                                                               --002
WHERE  (vis.PROC_CODE like 'NUC%'  
          OR vis.PROC_CODE like 'IMG%')  --'NUC%' or 'IMG%'                                                                                                                  --002 
       AND vis.STUDY_STATUS_C not in ('4','5','7')  -- 4=No Show, 5=Scheduled, 7=Arrived 

ORDER BY 
 vis.ACCESSION_NUM
,vis.ORDER_ID


