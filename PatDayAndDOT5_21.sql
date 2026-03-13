WITH FILLDAT
AS
(
   SELECT  -- *
   dd.CALENDAR_DT
   ,dd.DAY_OF_WEEK
   ,dd.WEEK_NUMBER
   ,dd.DAY_OF_MONTH
   ,dd.MONTH_NAME
    ,dd.MONTH_NUMBER
   ,dd."YEAR"
   ,dd.YEAR_MONTH
   ,dd.weekend_yn
   ,dd.HOLIDAY_YN
   ,dd.MONTHNAME_YEAR
   ,dd.YEAR_END_DT
   FROM DATE_DIMENSION dd
   WHERE
   
       dd.CALENDAR_DT >= TRUNC (ADD_MONTHS (CURRENT_DATE , -1), 'MM') 
  --        AND mared.SCHEDULED_TIME < sysdate
        and dd.CALENDAR_DT < TRUNC (ADD_MONTHS (CURRENT_DATE,0 ), 'MM') 
--        and dd.CALENDAR_DT < TRUNC (ADD_MONTHS (CURRENT_DATE , -1), 'MM') 

   
)
  
,ANTIB
as
(

SELECT 
cm.MEDICATION_ID
,cm.NAME
,coalesce(rx2.SHORT_NAME, zcsg.NAME) "SHORT_NAME"
,zct.NAME   "THERA_CLASS"
,zcpp.NAME  "PHARM_CLASS"
,cm.FORM
,zcar.NAME  "ADMIN_ROUTE"
,zcps.NAME "PHARM_SUBCLASS"
,gcr.GROUPER_ID
,cm.ROUTE  
,CASE WHEN gi.PROV_DISPLAY_NAME IS NULL THEN 'Vancomycin' ELSE  gi.PROV_DISPLAY_NAME END "MED_GROUP"

FROM GROUPER_COMPILED_RECORDS gcr
LEFT OUTER JOIN GROUPER_ITEMS gi ON gcr.GROUPER_ID = gi.GROUPER_ID
LEFT OUTER JOIN clarity_medication cm ON gcr.COMPILED_REC_LIST = cm.MEDICATION_ID
LEFT OUTER JOIN ZC_SIMPLE_GENERIC zcsg ON cm.SIMPLE_GENERIC_C = zcsg.SIMPLE_GENERIC_C
LEFT OUTER JOIN RX_MED_TWO rx2 ON cm.MEDICATION_ID = rx2.MEDICATION_ID
LEFT OUTER JOIN ZC_THERA_CLASS zct ON cm.THERA_CLASS_C = zct.THERA_CLASS_C
LEFT OUTER JOIN ZC_PHARM_CLASS zcpp ON cm.PHARM_CLASS_C = zcpp.PHARM_CLASS_C
LEFT OUTER JOIN ZC_ADMIN_ROUTE zcar ON rx2.ADMIN_ROUTE_C = zcar.MED_ROUTE_C
LEFT OUTER JOIN ZC_PHARM_SUBCLASS zcps ON cm.PHARM_SUBCLASS_C = zcps.PHARM_SUBCLASS_C
WHERE 
gcr.GROUPER_ID IN (115893,115895,408117,115899,115899,115901,115905)

)
,NHSN
as
(
SELECT --*
    nhsn_fac.FACILITY_ID
    ,nhsn_fac.MAPPED_FACILITY_NHSN_DEF_ID
    ,dep3.PARENT_HOSP_ID
    ,dep3.DEPARTMENT_ID
    ,dep.DEPARTMENT_NAME
    ,nhsn_loc.MAPPED_LOCATION_NHSN_DEF_ID
    ,nhsn_loc.MAPPED_NHSN_LOC_START_DATE
    ,nhsn_loc.MAPPED_NHSN_LOC_END_DATE
    ,nhsn_def.NHSN_DEF_NAME
    ,nhsn_def.NHSN_LOCATION_CODE
    ,nhsn_def.NHSN_SVC_LOC_INTERNAL_ID   
    ,SERV.INTERNAL_ID
    ,SERV.CONTACT_DATE_REAL
    ,SERV.LINE
    ,SERV.CONTACT_DATE
    ,SERV.NHSN_AU_YN
    ,SERV.NHSN_LOC_TYPE
    ,SERV.NHSN_LOC_SERVICE
    ,SERV.NHSN_DEP_TYPE
      ,loc.LOC_NAME 
      ,loc.LOCATION_ABBR
    ,parloc.LOC_NAME "PARENT_LOCATION"
    FROM NHSN_FACILITY_MAPPING nhsn_fac
    LEFT OUTER JOIN clarity_loc loc ON nhsn_fac.FACILITY_ID = loc.LOC_ID
    LEFT OUTER JOIN clarity_dep_3 dep3 ON nhsn_fac.FACILITY_ID = dep3.PARENT_HOSP_ID
    LEFT OUTER JOIN clarity_dep dep ON dep3.DEPARTMENT_ID = dep.DEPARTMENT_ID
    LEFT OUTER JOIN nhsn_location_mapping nhsn_loc ON dep3.DEPARTMENT_ID = nhsn_loc.DEPARTMENT_ID AND nhsn_fac.LINE = nhsn_loc.LINE
    LEFT OUTER JOIN nhsn_definition nhsn_def ON nhsn_loc.MAPPED_LOCATION_NHSN_DEF_ID = nhsn_def.NHSN_DEF_ID
    LEFT OUTER JOIN clarity_loc p_loc ON dep.REV_LOC_ID = p_loc.LOC_ID
    LEFT OUTER JOIN clarity_loc parloc ON p_loc.HOSP_PARENT_LOC_ID = parloc.LOC_ID
    LEFT OUTER JOIN
    ( 
            SELECT *
            FROM
            (
                SELECT   -- * 
                nhsn_svc.INTERNAL_ID
                ,nhsn_svc.CONTACT_DATE_REAL
                ,nhsn_svc.CONTACT_DATE
                ,nhsn_svc.LINE
                ,zclt.NAME "NHSN_LOC_TYPE"
                ,zcdat.NAME  "NHSN_DEP_TYPE"
                ,nhsn_svc.NHSN_AU_YN
                ,cc.NAME "NHSN_LOC_SERVICE"
                ,row_number() OVER (PARTITION BY nhsn_svc.INTERNAL_ID ORDER BY nhsn_svc.CONTACT_DATE desc ) "SEQ_NUM"
                FROM NHSN_SERVICE_LOCATION nhsn_svc
                LEFT OUTER JOIN clarity_concept cc ON nhsn_svc.INTERNAL_ID = cc.INTERNAL_ID
                LEFT OUTER JOIN zc_nhsn_loc_type zclt ON nhsn_svc.NHSN_LOC_TYPE_C = zclt.NHSN_LOC_TYPE_C
                LEFT OUTER JOIN zc_nhsn_loc_subtype zcsub ON nhsn_svc.NHSN_LOC_SUBTYPE_C = zcsub.NHSN_LOC_SUBTYPE_C
                LEFT OUTER JOIN zc_nhsn_summary_data zcdat ON nhsn_svc.NHSN_SUMMARY_DATA_C = zcdat.NHSN_SUMMARY_DATA_C
            )
            WHERE 
            SEQ_NUM = 1   
     )SERV ON nhsn_def.NHSN_SVC_LOC_INTERNAL_ID = SERV.INTERNAL_ID 
    
    WHERE
      dep3.PARENT_HOSP_ID IS NOT NULL 
     AND SERV.NHSN_AU_YN= 'Y'
--     and dep3.DEPARTMENT_ID = 1000108008

)

SELECT DISTINCT

sfi.DEPT_TARGET_ID  "DEPARTMENT_ID"
,dat.CALENDAR_DT
,dd.DAY_DT    "SOURCE_DT"
,dd.VALUE_DAY  "PATDAYS_NUM"
,0 AS "DAY_OF_THERAPY_IV"
,0 AS "DAY_OF_THERAPY_IM"
,0 AS "DAY_OF_THERAPY_DIGESTIVE"
,0 AS "DAY_OF_THERAPY_RESPIRATORY"
,0 AS "MEDICATION_ID"
,0 AS "ORDER_ID"
,'A' AS "MYGROUP"
    ,nhsn.FACILITY_ID
    ,nhsn.MAPPED_FACILITY_NHSN_DEF_ID
    ,nhsn.PARENT_HOSP_ID
    ,nhsn.DEPARTMENT_NAME
    ,nhsn.MAPPED_LOCATION_NHSN_DEF_ID
    ,nhsn.NHSN_DEF_NAME
    ,nhsn.NHSN_LOCATION_CODE
    ,nhsn.NHSN_LOC_TYPE
    ,nhsn.NHSN_LOC_SERVICE
    ,nhsn.NHSN_DEP_TYPE
    ,nhsn.LOC_NAME "PARENT_LOCATION"

FROM METRIC_INFO mi
INNER JOIN SUM_FACTS_INFO sfi ON mi.DEFINITION_ID = sfi.DEFINITION_ID
INNER JOIN daily_Data dd ON sfi.SUM_FACTS_ID = dd.SUM_FACTS_ID
inner join NHSN nhsn on sfi.DEPT_TARGET_ID = nhsn.DEPARTMENT_ID
LEFT OUTER JOIN FILLDAT dat ON dd.DAY_DT = dat.CALENDAR_DT

WHERE
dd.DAY_DT >= dat.CALENDAR_DT 
and dd.DAY_DT <= dat.CALENDAR_DT 
AND mi.DEFINITION_ID =11073
AND sfi.DEPT_TARGET_ID IS NOT NULL

UNION ALL

SELECT 
fdot.DEPARTMENT_ID  "DEPARTMENT_ID"
,dat.CALENDAR_DT
,fdot.TAKEN_DATE     "SOURCE_DT"
,0 as  "PATDAYS_NUM"
,fdot.DAY_OF_THERAPY_IV
,fdot.DAY_OF_THERAPY_IM
,fdot.DAY_OF_THERAPY_DIGESTIVE
,fdot.DAY_OF_THERAPY_RESPIRATORY
,fdot.MEDICATION_ID
,fdot.ORDER_ID
,'B' AS "MYGROUP"
    ,nhsn.FACILITY_ID
    ,nhsn.MAPPED_FACILITY_NHSN_DEF_ID
    ,nhsn.PARENT_HOSP_ID
    ,nhsn.DEPARTMENT_NAME
    ,nhsn.MAPPED_LOCATION_NHSN_DEF_ID
    ,nhsn.NHSN_DEF_NAME
    ,nhsn.NHSN_LOCATION_CODE
    ,nhsn.NHSN_LOC_TYPE
    ,nhsn.NHSN_LOC_SERVICE
    ,nhsn.NHSN_DEP_TYPE
    ,nhsn.LOC_NAME "PARENT_LOCATION"


FROM CLARITY_ADT adt
INNER JOIN order_med om ON adt.PAT_ENC_CSN_ID = om.PAT_ENC_CSN_ID
INNER JOIN F_DOT_CONTRIB_ORDS_DEPT fdot ON om.ORDER_MED_ID = fdot.ORDER_ID
left outer join  ANTIB anti on fdot.medication_id = anti.MEDICATION_ID
LEFT OUTER JOIN FILLDAT dat ON fdot.TAKEN_DATE = dat.CALENDAR_DT
LEFT OUTER JOIN clarity_dep dep ON fdot.DEPARTMENT_ID = dep.DEPARTMENT_ID
INNER JOIN patient pat ON fdot.PAT_ID = pat.PAT_ID
INNER JOIN patient_3 pat3 ON pat.PAT_ID = pat3.PAT_ID
inner join NHSN nhsn on fdot.DEPARTMENT_ID = nhsn.DEPARTMENT_ID

WHERE
adt.EVENT_SUBTYPE_C <> 2  ---- deleted
AND adt.EVENT_TYPE_C IN (1,3)
--AND TRUNC( fdot.TAKEN_DATE) >= '1-jan-2021' 
--AND TRUNC( fdot.TAKEN_DATE) <= '31-jan-2021' 
AND fdot.TAKEN_DATE >= dat.CALENDAR_DT 
AND fdot.TAKEN_DATE <= dat.CALENDAR_DT
AND pat3.IS_TEST_PAT_YN <> 'Y'


