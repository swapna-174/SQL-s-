WITH PAT_POP
AS

--
-- Main Patient Population: Patients in the program are identified by having an initial visit with a CPT charge code of 99404 at one of the 9 
-- weight management departments.
--
(
SELECT
    pat.PAT_ID
    , pat.PAT_MRN_ID
    , pbt.CPT_CODE
    , pbt.SERVICE_DATE
    , pbt.DEPARTMENT_ID
    , dep.DEPARTMENT_NAME
    
FROM ARPB_TRANSACTIONS pbt
    INNER JOIN CLARITY_DEP dep ON pbt.DEPARTMENT_ID = dep.DEPARTMENT_ID
    INNER JOIN PATIENT pat ON pbt.PATIENT_ID = pat.PAT_ID
    
WHERE
    pbt.CPT_CODE = '99404'
    AND pbt.DEPARTMENT_ID IN (1009601017, 1009601019, 1009601021, 1029001008, 1029001005, 1029001006, 1015101010
        , 1015101007, 1015101008, 1009601016, 1015101009, 1029001007, 1031701008, 1031701005, 1031701006, 103170100
        , 1009601020)
)

--
-- Return only those patients in the program who have had weight management appointments in the previous month.
--
, APPOINTMENTS
AS
(
SELECT
    enc.PAT_ID
    , pat.PAT_MRN_ID "MRN"
    , zc_sx.NAME "Gender"
    , FLOOR((enc.APPT_TIME - pat.BIRTH_DATE) / 365.25) "Age at Encounter"
    , enc.HEIGHT "Height"
    , (enc.WEIGHT / 16) "Weight"
    , enc.BMI "BMI"        
    , hsp.HSP_ACCOUNT_ID "HAR"
    , enc.PAT_ENC_CSN_ID "CSN"
    , enc.APPT_TIME "Appointment DateTime"
    , enc.ENC_TYPE_C
    , enc.APPT_STATUS_C
    , dep.DEPARTMENT_ID
    , dep.DEPARTMENT_NAME "Department Name"
    , zc_et.NAME "Appointment Type"
    , ser.PROV_NAME "Appointment Provider"
    , ser.PROV_TYPE "Provider Type"
    , epm.PAYOR_NAME "Payor Name"
    , epp.BENEFIT_PLAN_NAME "Plan Name"
--        , RANK() OVER ( PARTITION BY enc.PAT_ID ORDER BY enc.PAT_ID, enc.APPT_TIME DESC, enc.PAT_ENC_CSN_ID DESC) rank
    
FROM PAT_POP pp
    INNER JOIN PAT_ENC enc ON pp.PAT_ID = enc.PAT_ID
    INNER JOIN PATIENT pat ON enc.PAT_ID = pat.PAT_ID
    INNER JOIN HSP_ACCOUNT hsp ON enc.HSP_ACCOUNT_ID = hsp.HSP_ACCOUNT_ID
    LEFT OUTER JOIN COVERAGE cov ON hsp.COVERAGE_ID = cov.COVERAGE_ID
    LEFT OUTER JOIN CLARITY_EPM epm ON cov.PAYOR_ID = epm.PAYOR_ID
    LEFT OUTER JOIN CLARITY_EPP epp ON cov.PLAN_ID = epp.BENEFIT_PLAN_ID
    INNER JOIN CLARITY_SER ser ON enc.VISIT_PROV_ID = ser.PROV_ID
    INNER JOIN CLARITY_DEP dep ON enc.DEPARTMENT_ID = dep.DEPARTMENT_ID
    LEFT OUTER JOIN ZC_SEX zc_sx ON pat.SEX_C = zc_sx.RCPT_MEM_SEX_C
    LEFT OUTER JOIN ZC_DISP_ENC_TYPE zc_et ON enc.ENC_TYPE_C = zc_et.DISP_ENC_TYPE_C

WHERE
    enc.APPT_STATUS_C IN (2,6)
-- The next 2 lines commented out are for testing purposes
--    AND TRUNC(enc.APPT_TIME) >= '01-AUG-2020'
--    AND TRUNC(enc.APPT_TIME) <= '31-AUG-2021'
    AND TRUNC(enc.APPT_TIME) >= EPIC_UTIL.EFN_DIN('mb-1')
    AND TRUNC(enc.APPT_TIME) <= EPIC_UTIL.EFN_DIN('me-1')
    AND dep.DEPARTMENT_ID IN (1009601017, 1009601019, 1009601021, 1029001008, 1029001005, 1029001006, 1015101010
        , 1015101007, 1015101008, 1009601016, 1015101009, 1029001007, 1031701008, 1031701005, 1031701006, 103170100
        , 1009601020)
--        AND cov.PAYOR_ID = 405 
--        AND cov.PLAN_ID = 40501
)

--
-- The patient's current medications
--
, CURRENT_MEDS
AS
(
SELECT DISTINCT
    pecm.PAT_ENC_CSN_ID
    , cm.NAME "Medication Name"
    , cm.GENERIC_NAME "Generic Name"
    , om.HV_DISCRETE_DOSE "Dosage"
    , zc_mu.NAME "Dose Unit"
    
FROM APPOINTMENTS app
    INNER JOIN PAT_ENC_CURR_MEDS pecm ON app."CSN" = pecm.PAT_ENC_CSN_ID
    INNER JOIN ORDER_MED om ON pecm.CURRENT_MED_ID = om.ORDER_MED_ID
    INNER JOIN CLARITY_MEDICATION cm ON om.MEDICATION_ID = cm.MEDICATION_ID
    INNER JOIN ZC_MED_UNIT zc_mu ON om.HV_DOSE_UNIT_C = zc_mu.DISP_QTYUNIT_C
    
ORDER BY cm.NAME
)

--
-- Most recent A1C test
--
, A1C_LAB
AS
(
SELECT *
FROM
    ( 
    SELECT
        op.PAT_ID 
        , cc.NAME "A1C Test Name"
        , res.RESULT_DATE "A1C Test Date"
        , res.ORD_VALUE "A1C Test Value"
        , RANK() OVER ( PARTITION BY op.PAT_ID ORDER BY op.PAT_ID,res.RESULT_TIME DESC,RowNum) rank
    FROM CLARITY_COMPONENT cc
        INNER JOIN ORDER_RESULTS res ON res.COMPONENT_ID = cc.COMPONENT_ID
        INNER JOIN ORDER_PROC op ON res.ORDER_PROC_ID = op.ORDER_PROC_ID
        INNER JOIN APPOINTMENTS app ON op.PAT_ID = app.PAT_ID
    WHERE
        UPPER(cc.NAME) LIKE '%A1C%'
    )
    WHERE rank = 1
)

--
-- Most recent HGB test
--
, HGB_LAB
AS
(
SELECT *
FROM
    ( 
    SELECT
        op.PAT_ID 
        , cc.NAME "HGB Test Name"
        , res.RESULT_DATE "HGB Test Date"
        , res.ORD_VALUE "HGB Test Value"
        , RANK() OVER ( PARTITION BY op.PAT_ID ORDER BY op.PAT_ID,res.RESULT_TIME DESC,RowNum) rank
    FROM CLARITY_COMPONENT cc
        INNER JOIN ORDER_RESULTS res ON res.COMPONENT_ID = cc.COMPONENT_ID
        INNER JOIN ORDER_PROC op ON res.ORDER_PROC_ID = op.ORDER_PROC_ID
        INNER JOIN APPOINTMENTS app ON op.PAT_ID = app.PAT_ID
    WHERE
        UPPER(cc.NAME) LIKE '%HGB%'
    )
    WHERE rank = 1
)

--
-- Most recent Triglycerides test
--
, TRIGLYCERIDES_LAB
AS
(
SELECT *
FROM
    ( 
    SELECT
        op.PAT_ID 
        , cc.NAME "Triglycerides Test Name"
        , res.RESULT_DATE "Triglycerides Test Date"
        , res.ORD_VALUE "Triglycerides Test Value"
        , RANK() OVER ( PARTITION BY op.PAT_ID ORDER BY op.PAT_ID,res.RESULT_TIME DESC,RowNum) rank
    FROM CLARITY_COMPONENT cc
        INNER JOIN ORDER_RESULTS res ON res.COMPONENT_ID = cc.COMPONENT_ID
        INNER JOIN ORDER_PROC op ON res.ORDER_PROC_ID = op.ORDER_PROC_ID
        INNER JOIN APPOINTMENTS app ON op.PAT_ID = app.PAT_ID
    WHERE
        UPPER(cc.NAME) LIKE '%TRIGLYCERIDES%'
    )
    WHERE rank = 1
)

--
-- Most recent Total Cholesterol test
--
, TOT_CHOL_LAB
AS
(
SELECT *
FROM
    ( 
    SELECT
        op.PAT_ID 
        , cc.NAME "Total Chol Test Name"
        , res.RESULT_DATE "Total Chol Test Date"
        , res.ORD_VALUE "Total Chol Test Value"
        , RANK() OVER ( PARTITION BY op.PAT_ID ORDER BY op.PAT_ID,res.RESULT_TIME DESC,RowNum) rank
    FROM CLARITY_COMPONENT cc
        INNER JOIN ORDER_RESULTS res ON res.COMPONENT_ID = cc.COMPONENT_ID
        INNER JOIN ORDER_PROC op ON res.ORDER_PROC_ID = op.ORDER_PROC_ID
        INNER JOIN APPOINTMENTS app ON op.PAT_ID = app.PAT_ID
    WHERE
        cc.COMPONENT_ID = 1230220027  --  Total Cholesterol
    )
    WHERE rank = 1
)

, HDL_LAB
AS
(
SELECT *
FROM
    ( 
    SELECT
        op.PAT_ID 
        , app."MRN"
        , cc.COMPONENT_ID
        , cc.NAME "HDL Test Name"
        , res.RESULT_DATE "HDL Test Date"
        , res.ORD_VALUE "HDL Test Value"
        , RANK() OVER ( PARTITION BY op.PAT_ID ORDER BY op.PAT_ID,res.RESULT_TIME DESC,RowNum) rank
    FROM CLARITY_COMPONENT cc
        INNER JOIN ORDER_RESULTS res ON res.COMPONENT_ID = cc.COMPONENT_ID
        INNER JOIN ORDER_PROC op ON res.ORDER_PROC_ID = op.ORDER_PROC_ID
        INNER JOIN APPOINTMENTS app ON op.PAT_ID = app.PAT_ID
    WHERE
        cc.COMPONENT_ID = 1230220028  -- HDL
    )
    WHERE rank = 1
)

, LDL_LAB
AS
(
SELECT *
FROM
    ( 
    SELECT
        op.PAT_ID 
        , app."MRN"
        , cc.COMPONENT_ID
        , cc.NAME "LDL Test Name"
        , res.RESULT_DATE "LDL Test Date"
        , res.ORD_VALUE "LDL Test Value"
        , RANK() OVER ( PARTITION BY op.PAT_ID ORDER BY op.PAT_ID,res.RESULT_TIME DESC,RowNum) rank
    FROM CLARITY_COMPONENT cc
        INNER JOIN ORDER_RESULTS res ON res.COMPONENT_ID = cc.COMPONENT_ID
        INNER JOIN ORDER_PROC op ON res.ORDER_PROC_ID = op.ORDER_PROC_ID
        INNER JOIN APPOINTMENTS app ON op.PAT_ID = app.PAT_ID
    WHERE
        cc.COMPONENT_ID IN (1230220029, 1230290055)  --  LDL
    )
    WHERE rank = 1
)
--
-- Most recent Glucose test
--
, GLUCOSE_LAB
AS
(
SELECT *
FROM
    ( 
    SELECT
        op.PAT_ID 
        , cc.COMPONENT_ID
        , cc.NAME "Glucose Test Name"
        , res.RESULT_DATE "Glucose Test Date"
        , res.ORD_VALUE "Glucose Test Value"
        , RANK() OVER ( PARTITION BY op.PAT_ID ORDER BY op.PAT_ID,res.RESULT_TIME DESC,RowNum) rank
        
    FROM CLARITY_COMPONENT cc
        INNER JOIN ORDER_RESULTS res ON res.COMPONENT_ID = cc.COMPONENT_ID
        INNER JOIN ORDER_PROC op ON res.ORDER_PROC_ID = op.ORDER_PROC_ID
        INNER JOIN APPOINTMENTS app ON op.PAT_ID = app.PAT_ID
        
    WHERE
        cc.COMPONENT_ID = 1230220067  --  Glucose
    )
    WHERE rank = 1
)

SELECT DISTINCT
    app."MRN"
    , app."Gender"
    , app."Age at Encounter"
    , app."Height"
    , app."Weight"
    , app."BMI"
    , app."HAR"
    , app."CSN"
    , app."Appointment DateTime"
    , app."Department Name"
    , app."Appointment Type"
    , app."Appointment Provider"
    , app."Provider Type"
    , app."Payor Name"
    , app."Plan Name"
    , a1c."A1C Test Name"
    , a1c."A1C Test Date"
    , a1c."A1C Test Value"
    , hgb."HGB Test Name"
    , hgb."HGB Test Date"
    , hgb."HGB Test Value"
    , glc."Glucose Test Name"
    , glc."Glucose Test Date"
    , glc."Glucose Test Value"
    , trg."Triglycerides Test Name"
    , trg."Triglycerides Test Date"
    , trg."Triglycerides Test Value"
    , chl."Total Chol Test Name"
    , chl."Total Chol Test Date"
    , chl."Total Chol Test Value"
    , hdl."HDL Test Name"
    , hdl."HDL Test Date"
    , hdl."HDL Test Value"
    , ldl."LDL Test Name"
    , ldl."LDL Test Date"
    , ldl."LDL Test Value"
    , crm."Medication Name"
    , crm."Generic Name"
    , crm."Dosage"
    , crm."Dose Unit"
    
FROM APPOINTMENTS app
    LEFT OUTER JOIN A1C_LAB a1c ON app.PAT_ID = a1c.PAT_ID
    LEFT OUTER JOIN HGB_LAB hgb ON app.PAT_ID = hgb.PAT_ID
    LEFT OUTER JOIN TRIGLYCERIDES_LAB trg ON app.PAT_ID = trg.PAT_ID
    LEFT OUTER JOIN TOT_CHOL_LAB chl ON app.PAT_ID = chl.PAT_ID
    LEFT OUTER JOIN HDL_LAB hdl ON app.PAT_ID = hdl.PAT_ID
    LEFT OUTER JOIN LDL_LAB ldl ON app.PAT_ID = ldl.PAT_ID
    LEFT OUTER JOIN GLUCOSE_LAB glc ON app.PAT_ID = glc.PAT_ID
    LEFT OUTER JOIN CURRENT_MEDS crm ON app."CSN" = crm.PAT_ENC_CSN_ID
    
ORDER BY
    app."MRN"
    , app."CSN"
    , crm."Medication Name"