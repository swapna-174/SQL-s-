WITH NHSNLOC
AS
(
    SELECT --*
    nhsn_fac.FACILITY_ID
    ,nhsn_fac.MAPPED_FACILITY_NHSN_DEF_ID
    ,dep3.PARENT_HOSP_ID
    ,dep3.DEPARTMENT_ID
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
    ,lpp.LPP_ID
    ,lpp.LPP_NAME
    ,nhsn_loc.MAPPED_NHSN_LOC_LPP_ID
    FROM NHSN_FACILITY_MAPPING nhsn_fac
    LEFT OUTER JOIN clarity_loc loc ON nhsn_fac.FACILITY_ID = loc.LOC_ID
    LEFT OUTER JOIN clarity_dep_3 dep3 ON nhsn_fac.FACILITY_ID = dep3.PARENT_HOSP_ID
    LEFT OUTER JOIN clarity_dep dep ON dep3.DEPARTMENT_ID = dep.DEPARTMENT_ID
    LEFT OUTER JOIN nhsn_location_mapping nhsn_loc ON dep3.DEPARTMENT_ID = nhsn_loc.DEPARTMENT_ID AND nhsn_fac.LINE = nhsn_loc.LINE
    LEFT OUTER JOIN nhsn_definition nhsn_def ON nhsn_loc.MAPPED_LOCATION_NHSN_DEF_ID = nhsn_def.NHSN_DEF_ID
    LEFT OUTER JOIN clarity_lpp lpp ON nhsn_loc.MAPPED_NHSN_LOC_LPP_ID = lpp.LPP_ID
    LEFT OUTER JOIN
    ( 
      SELECT *
      FROM
      (
          SELECT 
          nhsn_serv.INTERNAL_ID
          ,nhsn_serv.CONTACT_DATE_REAL
          ,nhsn_serv.LINE
          ,nhsn_serv.CONTACT_DATE
          ,nhsn_serv.NHSN_AU_YN
          ,row_number() OVER (PARTITION BY nhsn_serv.INTERNAL_ID ORDER BY nhsn_serv.CONTACT_DATE desc ) "SEQ_NUM"
          from nhsn_service_location nhsn_serv
       )
        WHERE SEQ_NUM = 1    
     )SERV ON nhsn_def.NHSN_SVC_LOC_INTERNAL_ID = SERV.INTERNAL_ID 
    
    WHERE
    (nhsn_loc.MAPPED_NHSN_LOC_START_DATE IS NULL
    OR nhsn_loc.MAPPED_NHSN_LOC_START_DATE < CURRENT_DATE)
    AND
    (nhsn_loc.MAPPED_NHSN_LOC_END_DATE IS NULL
     OR nhsn_loc.MAPPED_NHSN_LOC_END_DATE > CURRENT_DATE)
     AND dep3.PARENT_HOSP_ID IS NOT NULL 
     AND SERV.NHSN_AU_YN= 'Y'
--     AND nhsn_loc.DEPARTMENT_ID = 1000108023

)

SELECT DISTINCT
pat.PAT_MRN_ID
,adt.EVENT_ID
,CASE when TRUNC((TRUNC(adt.EFFECTIVE_TIME)  - pat.BIRTH_DATE) / 365.25) > 17 THEN 'ADULT' ELSE 'PEDS' END "AGEGROUP"
,adt.PAT_ENC_CSN_ID
,nhsn.DEPARTMENT_ID
,zcps.NAME  "SERVICE"
,dep.DEPARTMENT_NAME 
,parloc.LOC_NAME   
,pat3.IS_TEST_PAT_YN
,adt.EFFECTIVE_TIME
,extract(month from adt.EFFECTIVE_TIME) "MONTH"
,adt.NEXT_OUT_EVENT_ID
,adt.EVENT_TYPE_C
,adt.OUT_EVENT_TYPE_C
--,ADTVAL.EVENT_ID
--,ADTVAL.EFFECTIVE_TIME
--,ADTVAL.EVENT_TYPE_C
--,ADTVAL.EVENT_SUBTYPE_C
FROM CLARITY_ADT adt
INNER JOIN NHSNLOC nhsn ON adt.DEPARTMENT_ID = nhsn.DEPARTMENT_ID  
CROSS apply 
       ( SELECT 
          adt2.EVENT_ID
          ,adt2.EFFECTIVE_TIME
          ,adt.PAT_ID
          ,adt.PAT_ENC_CSN_ID
          ,adt2.EVENT_TYPE_C
          ,adt2.EVENT_SUBTYPE_C
         FROM CLARITY_ADT adt2
         WHERE
         (( adt2.EVENT_ID = adt.NEXT_OUT_EVENT_ID
         AND TRUNC(adt2.EFFECTIVE_TIME) < TRUNC(adt.EFFECTIVE_TIME))
          OR adt.NEXT_OUT_EVENT_ID IS NULL)
          AND adt2.EVENT_SUBTYPE_C <> 2  ---- deleted
          AND adt2.EVENT_TYPE_C IN (1,2,3)

          AND adt2.PAT_ENC_CSN_ID = adt.PAT_ENC_CSN_ID      
       
       )ADTVAL
LEFT OUTER JOIN clarity_dep dep ON nhsn.DEPARTMENT_ID = dep.DEPARTMENT_ID
LEFT OUTER JOIN clarity_loc loc ON dep.REV_LOC_ID = loc.LOC_ID
LEFT OUTER JOIN clarity_loc parloc ON loc.HOSP_PARENT_LOC_ID = parloc.LOC_ID
LEFT OUTER JOIN zc_pat_service zcps ON adt.PAT_SERVICE_C = zcps.HOSP_SERV_C
INNER JOIN patient pat ON adt.PAT_ID = pat.PAT_ID
INNER JOIN patient_3 pat3 ON pat.PAT_ID = pat3.PAT_ID

WHERE
TRUNC(adt.EFFECTIVE_TIME) = '5-mar-2021' 
AND adt.EVENT_SUBTYPE_C <> 2  ---- deleted
AND adt.EVENT_TYPE_C IN (1,2,3)
AND pat3.IS_TEST_PAT_YN <> 'Y'
AND adt.OUT_EVENT_TYPE_C = 2
--AND adt.PAT_ENC_CSN_ID = '30136191384'    ---- 30135892685
--AND adt.EVENT_ID IN (33289908,33301836)