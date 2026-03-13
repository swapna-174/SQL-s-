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
--        nhsn_def.NHSN_DEF_ID = 12 
--    (nhsn_loc.MAPPED_NHSN_LOC_START_DATE IS NULL
--     OR nhsn_loc.MAPPED_NHSN_LOC_START_DATE > CURRENT_DATE)
--    AND
--    (nhsn_loc.MAPPED_NHSN_LOC_END_DATE IS NULL
--      OR nhsn_loc.MAPPED_NHSN_LOC_END_DATE < CURRENT_DATE)
      dep3.PARENT_HOSP_ID IS NOT NULL 
     AND SERV.NHSN_AU_YN= 'Y'



--SELECT *
--FROM NHSN_DEFINITION_OVERTIME dep
--
--WHERE
--dep.NHSN_DEF_ID= 16