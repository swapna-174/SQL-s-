SELECT hsp.PAT_ENC_CSN_ID "CSN"
    , pat.PAT_MRN_ID "MRN"
    , hsp.CONTACT_DATE "Contact Date"
    , hsp.DISCH_DISP_C "Discharge Code"
    , pat.DEATH_DATE "Date of Death"
    , hsp.DEPARTMENT_ID "Department Number"
    , dep.DEPARTMENT_NAME "Department Name"
    , pat.PAT_NAME "Pt Name"
    , pat.ADD_LINE_1 "Pt Address1"
    , pat.ADD_LINE_2 "Pt Address2"
    , pat.CITY "Pt City"
    , zc_st.ABBR "Pt State"
    , pat.ZIP "Pt Zip"
    , zc_fc.NAME "Financial Class"
    , v_cvg.PAYOR_ID "Payor ID"
    , v_cvg.PAYOR_NAME "Payor Name"
    , v_cvg.BENEFIT_PLAN_ID "Benefit Plane ID"
    , v_cvg.BENEFIT_PLAN_NAME "Benefit Plan Name"
    , acc.ACCOUNT_NAME "Guarantor Name"
    , acc.BILLING_ADDRESS_1 "Guarantor Address1"
    , acc.BILLING_ADDRESS_2 "Guarantor  Address2"
    , acc.CITY "Guarantor City"
    , zc_st2.ABBR "Guarantor State"
    , acc.ZIP "Guarantor Zip"
    , acc.HOME_PHONE "Guarantor Home Phone"
    , acc.WORK_PHONE "Guarantor Work Phone"
FROM PAT_ENC_HSP hsp
    LEFT OUTER JOIN PATIENT pat ON hsp.PAT_ID = pat.PAT_ID
    LEFT OUTER JOIN ZC_STATE zc_st ON pat.STATE_C = zc_st.STATE_C
    LEFT OUTER JOIN COVERAGE_MEM_LIST cml ON hsp.PAT_ID = cml.PAT_ID AND cml.MEM_EFF_TO_DATE IS NULL
    LEFT OUTER JOIN V_COVERAGE_PAYOR_PLAN v_cvg ON cml.COVERAGE_ID = v_cvg.COVERAGE_ID
    LEFT OUTER JOIN ZC_FINANCIAL_CLASS zc_fc ON v_cvg.FIN_CLASS_C = zc_fc.FINANCIAL_CLASS
    LEFT OUTER JOIN PAT_ENC enc ON hsp.PAT_ENC_CSN_ID = enc.PAT_ENC_CSN_ID
    LEFT OUTER JOIN ACCOUNT acc ON enc.ACCOUNT_ID = acc.ACCOUNT_ID
    LEFT OUTER JOIN ZC_STATE zc_st2 ON acc.STATE_C = zc_st2.STATE_C
    LEFT oUTER JOIN CLARITY_DEP dep ON hsp.DEPARTMENT_ID = dep.DEPARTMENT_ID
WHERE hsp.ED_EPISODE_ID IS NOT NULL
    AND hsp.DISCH_DISP_C = '20'
    --AND hsp.CONTACT_DATE  >= to_date('2015-12-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss')
    AND hsp.CONTACT_DATE  >= sysdate - 27
    AND hsp.DEPARTMENT_ID = '1000100009'