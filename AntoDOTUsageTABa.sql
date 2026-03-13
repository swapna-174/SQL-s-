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

SELECT 
fdot.TAKEN_DATE
,pat.PAT_MRN_ID
,CASE when TRUNC((TRUNC(fdot.TAKEN_DATE)  - pat.BIRTH_DATE) / 365.25) > 17 THEN 'ADULT' ELSE 'PEDS' END "AGEGROUP"

,om.PAT_ENC_CSN_ID
,adt.DEPARTMENT_ID
,zcps.NAME  "SERVICE"
,fdot.MEDICATION_ID
,zcar.NAME "ROUTE"
,fdot.DRUG_CODE
,fdot.PARENT_HOSPITAL_ID
--,cm.NAME
,serauth.PROV_NAME  "AUTHORIZED_PROVIDER"
,serord.PROV_NAME  "ORDER_PROVIDER"
,seratt.PROV_NAME  "ATTENDING_PROVIDER"
,fdot.DAY_OF_THERAPY_IV
,fdot.DAY_OF_THERAPY_IM
,fdot.DAY_OF_THERAPY_DIGESTIVE
,fdot.DAY_OF_THERAPY_RESPIRATORY
,dep.DEPARTMENT_NAME 
,parloc.LOC_NAME   
,fdot.ORDER_ID
,fdot.UPDATE_DATE
,pat3.IS_TEST_PAT_YN
,extract(month from fdot.TAKEN_DATE) "TAKEN_MONTH"
FROM CLARITY_ADT adt
--INNER JOIN NHSNLOC nhsn ON adt.DEPARTMENT_ID = nhsn.DEPARTMENT_ID  
INNER JOIN order_med om ON adt.PAT_ENC_CSN_ID = om.PAT_ENC_CSN_ID
INNER JOIN F_DOT_CONTRIB_ORDS_DEPT fdot ON om.ORDER_MED_ID = fdot.ORDER_ID
inner join ORDER_MEDINFO ominfo ON om.ORDER_MED_ID = ominfo.ORDER_MED_ID
LEFT OUTER join order_medmixinfo ommix ON om.ORDER_MED_ID = ommix.ORDER_MED_ID AND ommix.LINE = 1
LEFT OUTER JOIN CLARITY_MEDICATION cm ON COALESCE( ommix.MEDICATION_ID, ominfo.DISPENSABLE_MED_ID) = cm.MEDICATION_ID
LEFT OUTER JOIN IP_FREQUENCY freq ON om.HV_DISCR_FREQ_ID=freq.FREQ_ID
LEFT OUTER JOIN ZC_ADMIN_ROUTE zcar ON om.MED_ROUTE_C=zcar.MED_ROUTE_C
LEFT OUTER JOIN clarity_dep dep ON adt.DEPARTMENT_ID = dep.DEPARTMENT_ID
LEFT OUTER JOIN clarity_loc loc ON dep.REV_LOC_ID = loc.LOC_ID
LEFT OUTER JOIN clarity_loc parloc ON loc.HOSP_PARENT_LOC_ID = parloc.LOC_ID
LEFT OUTER JOIN zc_pat_service zcps ON fdot.PAT_HOSP_SERV_C = zcps.HOSP_SERV_C
LEFT OUTER JOIN clarity_ser serauth ON fdot.AUTHG_PROV_ID = serauth.PROV_ID
LEFT OUTER JOIN CLARITY_SER seratt ON fdot.ATTEND_PROV_ID = seratt.PROV_ID
LEFT OUTER JOIN clarity_ser serord ON fdot.ORDER_PROV_ID = serord.PROV_ID
INNER JOIN patient pat ON fdot.PAT_ID = pat.PAT_ID
INNER JOIN patient_3 pat3 ON pat.PAT_ID = pat3.PAT_ID

WHERE
adt.EVENT_SUBTYPE_C <> 2  ---- deleted
AND adt.EVENT_TYPE_C IN (1,3)
AND TRUNC(adt.EFFECTIVE_TIME) = '5-mar-2021' 
AND pat3.IS_TEST_PAT_YN <> 'Y'

