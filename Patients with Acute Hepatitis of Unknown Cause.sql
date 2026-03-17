SELECT
    pat.PAT_ID "Pat ID"
    , pat.PAT_MRN_ID "MRN"
    , pat.PAT_FIRST_NAME "First Name"
    , pat.PAT_LAST_NAME "Last Name"
    , pat.BIRTH_DATE "DOB"
    , pat.HOME_PHONE "Phone Number"
    , pat.ADD_LINE_1 "Address Line 1"
    , pat.ADD_LINE_2 "Address Line 2"
    , pat.CITY "City"
    , zc_co.NAME "County"
    , zc_st.NAME "State"
    , pat.ZIP "Zip Code"
    , dep.EXTERNAL_NAME "Facility"
    , TO_CHAR(hsp.ADM_DATE_TIME,'MM/DD/YYYY') "Date of Presentation"
    , CASE
        WHEN zc_bc.NAME IN ('Emergency', 'Inpatient') THEN 'Yes' ELSE 'No'
    END AS "Currently Hospitalized?"
    , FLOOR((hsp.ADM_DATE_TIME - pat.BIRTH_DATE) / 365.25) "Age at Encounter"
    , hsp.ADM_DATE_TIME "Admission/Appt Start Time"
    , hsp.DISCH_DATE_TIME "Discharge/Appt End Time"
    , zc_bc.NAME "Base Class"
    , edg.DX_NAME "Diagnosis"
    , icd.CODE "ICD 10 Code"
    , dep.DEPARTMENT_NAME "Discharge Department"
    , loc.LOC_NAME "Parent Location"
    , lab."Component ID"
    , lab."Component Name"
    , lab."Collected DateTime"
    , lab."Highest Level"
FROM HSP_ACCT_DX_LIST dx
    INNER JOIN HSP_ACCOUNT hsp ON dx.HSP_ACCOUNT_ID = hsp.HSP_ACCOUNT_ID
    INNER JOIN PATIENT pat ON hsp.PAT_ID = pat.PAT_ID
    INNER JOIN ZC_COUNTY zc_co ON pat.COUNTY_C = zc_co.COUNTY_C
    INNER JOIN ZC_STATE zc_st ON pat.STATE_C = zc_st.STATE_C
    INNER JOIN ZC_ACCT_BASECLS_HA zc_bc ON hsp.ACCT_BASECLS_HA_C = zc_bc.ACCT_BASECLS_HA_C
    INNER JOIN CLARITY_EDG edg ON dx.DX_ID = edg.DX_ID
    INNER JOIN EDG_CURRENT_ICD10 icd ON edg.DX_ID = icd.DX_ID
    INNER JOIN CLARITY_DEP dep ON hsp.DISCH_DEPT_ID = dep.DEPARTMENT_ID
    INNER JOIN CLARITY_LOC loc ON hsp.LOC_ID = loc.LOC_ID
    OUTER APPLY
        (
        SELECT *
        FROM
            (
            SELECT DISTINCT
                op.PAT_ID
                , cc.COMPONENT_ID "Component ID"
                , cc.NAME "Component Name"
                , res.ORD_NUM_VALUE  "Highest Level"
                , res.RESULT_TIME   "Result DateTime"
                , op2.SPECIMN_TAKEN_TIME "Collected DateTime"
                , CASE
                    WHEN res.ORD_NUM_VALUE > 500 THEN 'Yes' ELSE 'No'
                END AS "Level Above 500?"
                , RANK() OVER (PARTITION BY op.PAT_ID, cc.COMPONENT_ID ORDER BY res.ORD_NUM_VALUE DESC) rank        
            FROM CLARITY_COMPONENT cc
                INNER JOIN ORDER_RESULTS res ON res.COMPONENT_ID = cc.COMPONENT_ID
                INNER JOIN ORDER_PROC op ON res.ORDER_PROC_ID = op.ORDER_PROC_ID
                INNER JOIN ORDER_PROC_2 op2 ON op.ORDER_PROC_ID = op2.ORDER_PROC_ID
            WHERE 
                res.COMPONENT_ID IN (2324, 2325, 1525870, 1526000, 1810009, 1230220069, 1230220071, 1230293490)
                AND TRUNC(op2.SPECIMN_TAKEN_TIME) >= '01-OCT-2021'
--                AND op.PAT_ID IN ('Z2172220', 'Z3919650', 'Z3207917', 'Z3304329')
                AND op.PAT_ID = pat.PAT_ID
                AND TRUNC(op2.SPECIMN_TAKEN_TIME) >= TRUNC(hsp.ADM_DATE_TIME)
                AND TRUNC(op2.SPECIMN_TAKEN_TIME) <= (TRUNC(hsp.DISCH_DATE_TIME) + 1)
                AND res.ORD_NUM_VALUE > 500
            ORDER BY res.RESULT_TIME 
            )
        WHERE rank = 1        
        ) lab

WHERE
--    icd.CODE = 'B17.9'
    icd.CODE IN ('B17.9', 'R74.0', 'R74.01', 'S36.119A', 'B18.8', 'B18.9', 'B17.8', 'K75.2')
    AND TRUNC(hsp.ADM_DATE_TIME) >= '01-OCT-2021'
    AND FLOOR((hsp.ADM_DATE_TIME - pat.BIRTH_DATE) / 365.25) < 18
ORDER BY
    pat.PAT_MRN_ID
    , hsp.ADM_DATE_TIME
    


--SELECT 
--    cc.COMPONENT_ID
--    ,cc.NAME
--    ,res.ORD_VALUE
--    ,res.ORD_NUM_VALUE  "NUMVALUE"
--    ,res.PAT_ID
--    ,res.PAT_ENC_CSN_ID  "RESULTSCSN"
--    ,res.RESULT_DATE   "RESULTDATE"
--    ,res.RESULT_TIME   "RESULTTIME"
--    ,row_number() OVER (PARTITION BY res.PAT_ID ORDER BY res.RESULT_DATE DESC) "SEQ_NUM"
--FROM CLARITY_COMPONENT cc
--    INNER JOIN ORDER_RESULTS res ON res.COMPONENT_ID = cc.COMPONENT_ID
--WHERE 
--    cc.COMPONENT_ID IN (1230220071,1230220069)
----    AND res.RESULT_DATE BETWEEN '01-Aug-2015' and '31-Aug-2015'
----    AND   to_number(REGEXP_SUBSTR(res.ORD_VALUE,'\d+$')) <=50 
--    AND res.PAT_ID IN ('Z2172220', 'Z3919650', 'Z3207917', 'Z3304329')
--    --AND res.ORD_NUM_VALUE <=50
--ORDER BY res.RESULT_TIME 