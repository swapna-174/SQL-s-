SELECT DISTINCT
pat.PAT_MRN_ID
,adt.EVENT_ID
,CASE when TRUNC((TRUNC(adt.EFFECTIVE_TIME)  - pat.BIRTH_DATE) / 365.25) > 17 THEN 'ADULT' ELSE 'PEDS' END "AGEGROUP"
,adt.PAT_ENC_CSN_ID
,adt.DEPARTMENT_ID
,dep.DEPARTMENT_NAME 
,zcps.NAME  "SERVICE"
,pat3.IS_TEST_PAT_YN
,adt.EFFECTIVE_TIME
,extract(month from adt.EFFECTIVE_TIME) "MONTH"
,adt.NEXT_OUT_EVENT_ID
,adt.EVENT_TYPE_C
,adt.OUT_EVENT_TYPE_C
FROM CLARITY_ADT adt
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
LEFT OUTER JOIN clarity_dep dep ON adt.DEPARTMENT_ID = dep.DEPARTMENT_ID
LEFT OUTER JOIN zc_pat_service zcps ON adt.PAT_SERVICE_C = zcps.HOSP_SERV_C
INNER JOIN patient pat ON adt.PAT_ID = pat.PAT_ID
INNER JOIN patient_3 pat3 ON pat.PAT_ID = pat3.PAT_ID

WHERE
TRUNC(adt.EFFECTIVE_TIME) = '5-mar-2021' 
AND adt.EVENT_SUBTYPE_C <> 2  ---- deleted
AND adt.EVENT_TYPE_C IN (1,2,3)
AND pat3.IS_TEST_PAT_YN <> 'Y'
AND adt.OUT_EVENT_TYPE_C = 2

