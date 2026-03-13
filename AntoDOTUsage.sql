WITH NHSNLOC
AS
(
    SELECT --*
    nhsn_fac.FACILITY_ID
    ,nhsn_fac.MAPPED_FACILITY_NHSN_DEF_ID
    ,dep3.PARENT_HOSP_ID
    ,dep3.DEPARTMENT_ID
    ,nhsn_loc.DEPARTMENT_ID
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
    LEFT OUTER JOIN clarity_dep_3 dep3 ON nhsn_fac.FACILITY_ID = dep3.PARENT_HOSP_ID
    LEFT OUTER JOIN nhsn_location_mapping nhsn_loc ON dep3.DEPARTMENT_ID = nhsn_loc.DEPARTMENT_ID
    LEFT OUTER JOIN clarity_lpp lpp ON nhsn_loc.MAPPED_NHSN_LOC_LPP_ID = lpp.LPP_ID
    LEFT OUTER JOIN nhsn_definition nhsn_def ON nhsn_loc.MAPPED_LOCATION_NHSN_DEF_ID = nhsn_def.NHSN_DEF_ID
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
--          WHERE 
    --       nhsn_serv.NHSN_AU_YN= 'Y'
    --       AND nhsn_serv.internal_id = 81342
       )
        WHERE SEQ_NUM = 1    
     )SERV ON nhsn_def.NHSN_SVC_LOC_INTERNAL_ID = SERV.INTERNAL_ID 
    --LEFT OUTER JOIN SUM_FACTS_INFO_2 sum_info2 ON nhsn_def.NHSN_DEF_ID = sum_info2.NHSN_LOCATION_TARGET_ID
    
    WHERE
    (nhsn_loc.MAPPED_NHSN_LOC_START_DATE IS NULL
    OR nhsn_loc.MAPPED_NHSN_LOC_START_DATE < CURRENT_DATE)
    AND
    (nhsn_loc.MAPPED_NHSN_LOC_END_DATE IS NULL
     OR nhsn_loc.MAPPED_NHSN_LOC_END_DATE > CURRENT_DATE)
     AND dep3.PARENT_HOSP_ID IS NOT NULL 
     AND SERV.NHSN_AU_YN= 'Y'
     AND nhsn_loc.DEPARTMENT_ID = 1000108023
)

SELECT *
FROM CLARITY_ADT adt
INNER JOIN NHSNLOC nhsn ON adt.DEPARTMENT_ID = nhsn.DEPARTMENT_ID  
INNER JOIN order_med om ON adt.PAT_ENC_CSN_ID = om.PAT_ENC_CSN_ID
inner join ORDER_MEDINFO ominfo ON om.ORDER_MED_ID = ominfo.ORDER_MED_ID

--LEFT OUTER join order_medmixinfo ommix ON om.ORDER_MED_ID = ommix.ORDER_MED_ID AND ommix.LINE = 1
--LEFT OUTER JOIN CLARITY_MEDICATION cm ON COALESCE( ommix.MEDICATION_ID, ominfo.DISPENSABLE_MED_ID) = cm.MEDICATION_ID
--LEFT OUTER JOIN GROUPER_COMPILED_RECORDS gcr ON gcr.COMPILED_REC_LIST = cm.MEDICATION_ID
-- GROUPER_COMPILED_RECORDS gcr
WHERE
adt.EVENT_SUBTYPE_C <> 2  ---- deleted
AND adt.EVENT_TYPE_C IN (1,3)
AND TRUNC(adt.EFFECTIVE_TIME) = '5-mar-2021' 
--AND adt.PAT_ENC_CSN_ID = 30136166101
AND adt.DEPARTMENT_ID = 1000108023
--AND gcr.GROUPER_ID IN (115893,115895,408117,115899,115899,115901,115905)
AND om.ORDER_MED_ID = 595508726


--SELECT *
--FROM CLARITY_LPP lpp
--WHERE
--lpp.LPP_ID IN (30486622302,30486622302)