SELECT *
FROM
(SELECT *
FROM
(SELECT *
FROM
   (SELECT
        pat.PAT_MRN_ID "MRN"
--        , pat.PAT_ID
        , zc_sex.NAME  "Gender"
        , pat.ZIP "Zip Code"
        , hsp.PAT_ENC_CSN_ID "CSN"
--        , adt.DEPARTMENT_ID "Department ID"
        , hsp.CONTACT_DATE "Contact Date"
        , ROUND((hsp.ADT_ARRIVAL_TIME - pat.BIRTH_DATE) / 365) "Age at Encounter"
        , v_enc.TEMPERATURE "Temperature"
        , hsp.ADT_ARRIVAL_TIME "Arrival Time"
        , hsp.ED_DEPARTURE_TIME "Departure Time"
        , ROUND((hsp.ED_DEPARTURE_TIME - hsp.ADT_ARRIVAL_TIME) * 24 * 60) "ED LOS in Minutes"
        , (CASE
            WHEN hsp.ED_DISPOSITION_C = 3
                THEN 'Y'
                ELSE 'n'
            END) "Admitted?"
        , zc_disp.NAME "Disposition"
        , rsn.ENC_REASON_NAME
        , rsn.LINE
--        , rsn.ENC_REASON_OTHER "Chief Complaint Other"
--        , edg.DX_ID
        , edg.DX_NAME "Discharge Dx Name"
        , dx.PRIMARY_DX_YN "Primary Dx?"
        , (CASE 
            WHEN NOT (img.ED_RAD_STATUS_C IS NULL)
                THEN 'Y'
                 ELSE 'n'
            END) "Imaging Ordered?"
        , ser.PROV_NAME "PCP"
        , epp.BENEFIT_PLAN_NAME
        , cvg_ord.FILING_ORDER
        , hsp_acc.HSP_ACCOUNT_ID
        , fc.FINANCIAL_CLASS_NAME
        , hsp_acc.TOT_CHGS "Total Charges"
        , hsp_acc.TOT_ADJ "Total Adjustments"
--        , (SELECT SUM(htx.TX_AMOUNT)
--            FROM HSP_TRANSACTIONS htx
--                LEFT OUTER JOIN HSP_BUCKET bkt ON htx.BUCKET_ID = bkt.BUCKET_ID
--                    AND bkt.BKT_TYPE_HA_C IN ('2', '3', '4', '6', '7')
--                WHERE bkt.HSP_ACCOUNT_ID = hsp_acc.HSP_ACCOUNT_ID
--                    AND htx.TX_TYPE_HA_C = 2
--            ) AS "Total All Payments"
        , (SELECT SUM(htx.TX_AMOUNT)
            FROM HSP_TRANSACTIONS htx
                LEFT OUTER JOIN HSP_BUCKET bkt ON htx.BUCKET_ID = bkt.BUCKET_ID
                    AND bkt.BKT_TYPE_HA_C IN ('2', '3', '6', '7')
            WHERE bkt.HSP_ACCOUNT_ID = hsp_acc.HSP_ACCOUNT_ID
                    AND htx.TX_TYPE_HA_C = 2
            ) AS "Total Insurance Payments"
        , (SELECT SUM(htx.TX_AMOUNT)
            FROM HSP_TRANSACTIONS htx
                LEFT OUTER JOIN HSP_BUCKET bkt ON htx.BUCKET_ID = bkt.BUCKET_ID
                    AND bkt.BKT_TYPE_HA_C = '4'
            WHERE bkt.HSP_ACCOUNT_ID = hsp_acc.HSP_ACCOUNT_ID
                    AND htx.TX_TYPE_HA_C = 2
            ) AS "Total Patient Payments"
        , hsp_acc.TOT_ACCT_BAL "Outstanding Balance"
        , (CASE
            WHEN cm.NAME LIKE 'DEXAMETHASONE%'
                THEN 'YES'
                ELSE 'no'
            END) "Decadron Given?"
        , cm.NAME "Med Name"
        , cm.FORM "Med Form"
        , cm.ROUTE "Med Route"
        , mar.SCHEDULED_TIME "Scheduled Time"
        , mar.TAKEN_TIME "Taken Time"
        , (SELECT MIN(ROUND((mar.TAKEN_TIME - hsp_fm.ADT_ARRIVAL_TIME) *24 * 60))
            FROM PAT_ENC_HSP hsp_fm  
                LEFT OUTER JOIN ORDER_MED med ON hsp_fm.PAT_ENC_CSN_ID = med.PAT_ENC_CSN_ID
                LEFT OUTER JOIN MAR_ADMIN_INFO mar ON med.ORDER_MED_ID = mar.ORDER_MED_ID
            WHERE hsp_fm.PAT_ENC_CSN_ID = hsp.PAT_ENC_CSN_ID
--                AND ROWNUM = 1
--            ORDER BY mar.TAKEN_TIME
            ) AS "Minutes Arrival to First Med"
    FROM PATIENT pat
        LEFT OUTER JOIN PAT_ENC_HSP hsp ON pat.PAT_ID = hsp.PAT_ID
        LEFT OUTER JOIN ZC_ED_DISPOSITION zc_disp ON hsp.ED_DISPOSITION_C = zc_disp.ED_DISPOSITION_C
        LEFT OUTER JOIN CLARITY_ADT adt ON hsp.PAT_ENC_CSN_ID = adt.PAT_ENC_CSN_ID
            AND adt.EVENT_TYPE_C = 1
        LEFT OUTER JOIN PAT_ENC_RSN_VISIT rsn ON hsp.PAT_ENC_CSN_ID = rsn.PAT_ENC_CSN_ID
        LEFT OUTER JOIN PAT_ENC_DX dx ON hsp.PAT_ENC_CSN_ID = dx.PAT_ENC_CSN_ID
        LEFT OUTER JOIN CLARITY_EDG edg ON dx.DX_ID = edg.DX_ID
        LEFT OUTER JOIN ED_RAD_STATUS img ON hsp.PAT_ENC_CSN_ID = img.PAT_ENC_CSN_ID AND img.ED_RAD_STATUS_C = '106006'
        LEFT OUTER JOIN ZC_ED_RAD_STATUS zc_img ON img.ED_RAD_STATUS_C = zc_img.ED_RAD_STATUS_C
        LEFT OUTER JOIN PAT_ACCT_CVG cvg ON pat.PAT_ID = cvg.PAT_ID
        LEFT OUTER JOIN CLARITY_EPP epp ON cvg.PLAN_ID = epp.BENEFIT_PLAN_ID
        LEFT OUTER JOIN PAT_CVG_FILE_ORDER cvg_ord ON cvg.COVERAGE_ID = cvg_ord.COVERAGE_ID
        LEFT OUTER JOIN HSP_ACCOUNT hsp_acc ON hsp.HSP_ACCOUNT_ID = hsp_acc.HSP_ACCOUNT_ID
        LEFT OUTER JOIN V_PAT_ENC v_enc ON hsp.PAT_ENC_CSN_ID = v_enc.PAT_ENC_CSN_ID
        LEFT OUTER JOIN CLARITY_SER ser ON v_enc.PCP_PROV_ID = ser.PROV_ID
        LEFT OUTER JOIN ZC_SEX zc_sex ON pat.SEX_C = zc_sex.RCPT_MEM_SEX_C
        LEFT OUTER JOIN ORDER_MED med ON hsp.PAT_ENC_CSN_ID = med.PAT_ENC_CSN_ID
        LEFT OUTER JOIN CLARITY_MEDICATION cm ON med.MEDICATION_ID = cm.MEDICATION_ID
        LEFT OUTER JOIN MAR_ADMIN_INFO mar ON med.ORDER_MED_ID = mar.ORDER_MED_ID
        LEFT OUTER JOIN ZC_MAR_RSLT zc_rslt ON mar.MAR_ACTION_C = zc_rslt.RESULT_C
        LEFT OUTER JOIN CLARITY_FC fc ON hsp_acc.ACCT_FIN_CLASS_C = fc.FINANCIAL_CLASS
    WHERE 
        NOT(hsp.ED_EPISODE_ID IS NULL)
        AND(hsp.ADMIT_CONF_STAT_C IS NULL
            OR NOT(hsp.ADMIT_CONF_STAT_C IN (2,3)))
        AND hsp.ADT_ARRIVAL_TIME >= to_date('2014-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss')
        AND hsp.ADT_ARRIVAL_TIME <= to_date('2015-12-31 00:00:00', 'yyyy-mm-dd hh24:mi:ss')
        AND ROUND((hsp.ADT_ARRIVAL_TIME - pat.BIRTH_DATE) / 365) < 19
        AND v_enc.TEMPERATURE < 100.5
        AND mar.MAR_ACTION_C = 1
        AND adt.DEPARTMENT_ID = 1000100010
--        AND hsp_acc.HSP_ACCOUNT_ID = '410020673'
        AND( UPPER (rsn.ENC_REASON_NAME) LIKE '%HEADACHE%'
            OR UPPER (rsn.ENC_REASON_NAME) LIKE '%MIGRAINE%'
            OR UPPER (rsn.ENC_REASON_OTHER) LIKE '%HEADACHE%'
            OR UPPER (rsn.ENC_REASON_OTHER) LIKE '%MIGRAINE%'
            OR UPPER (edg.DX_NAME) LIKE '%HEADACHE%'
            OR UPPER (edg.DX_NAME) LIKE '%MIGRAINE%')
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE 'TUBEROUS SCLEROSIS%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE 'NEUROFIBROMATOSIS%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%AVM%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%INTRACRANIAL HEMORRHAGE%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%SUBARACHNOID HEMORRHAGE%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%STROKE%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%CVA%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%NON-ACCIDENTAL TRAUMA%CHILD%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%FRACTURE%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%SEIZURE%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%HYDROCEPHALUS%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%INTRACRANIAL SHUNT%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%SHUNT MALFUNCTION%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%VP SHUNT%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%PSEUDOTUMOR CEREBRI%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%BENIGN HYPERTENSION%INTRACRANIAL PRESSURE'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%MULTIPLE SCLEROSIS%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%OPTIC NEURITIS%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%ADEM %' 
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%(ADEM)%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%VASCULITIS%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%INTRACRANIAL TUMOR%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%MASS%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%TUMOR%' 
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%LYMPHOMA%' 
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%LEUKEMIA%' 
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%ANEMIA%' 
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%INFECTION%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%INFECTIOUS%' 
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%MENINGITIS%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%SINUSITIS%' 
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%ENCEPHALITIS%' 
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%PNEUMONIA%' 
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%UPPER RESPIRATORY ILLNESS%' 
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%ROCKY MOUNTAIN%' 
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%BARTONELLA%' 
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%INFLUENZA%' 
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%STREP %'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%STREPTOCOCCAL%' 
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%STAPHYLOC%' 
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%COUGH%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%FEVER%' 
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%FEBRILE%' 
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%SEPSIS%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%SEPTIC%' 
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%BACTEREMIA%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%OTITIS MEDIA%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%ABSCESS%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%SORE THROAT%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%ACUTE URI %'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%VIRAL ILLNESS%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%VIRAL PHARYNGITIS%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%VP SHUNT%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%CEREBRAL VENTRICULOMEGALY%'
        AND UPPER (rsn.ENC_REASON_NAME) NOT LIKE '%BACTEREMIA%'
        AND UPPER (edg.DX_NAME) NOT LIKE 'TUBEROUS SCLEROSIS%'
        AND UPPER (edg.DX_NAME) NOT LIKE 'NEUROFIBROMATOSIS%'
        AND UPPER (edg.DX_NAME) NOT LIKE '%AVM%'
        AND UPPER (edg.DX_NAME) NOT LIKE '%INTRACRANIAL HEMORRHAGE%'
        AND UPPER (edg.DX_NAME) NOT LIKE '%SUBARACHNOID HEMORRHAGE%'
        AND UPPER (edg.DX_NAME) NOT LIKE '%STROKE%'
        AND UPPER (edg.DX_NAME) NOT LIKE '%CVA%'
        AND UPPER (edg.DX_NAME) NOT LIKE '%NON-ACCIDENTAL TRAUMA%CHILD%'
        AND UPPER (edg.DX_NAME) NOT LIKE '%FRACTURE%'
        AND UPPER (edg.DX_NAME) NOT LIKE '%SEIZURE%'
        AND UPPER (edg.DX_NAME) NOT LIKE '%HYDROCEPHALUS%'
        AND UPPER (edg.DX_NAME) NOT LIKE '%INTRACRANIAL SHUNT%'
        AND UPPER (edg.DX_NAME) NOT LIKE '%SHUNT MALFUNCTION%'
        AND UPPER (edg.DX_NAME) NOT LIKE '%VP SHUNT%'
        AND UPPER (edg.DX_NAME) NOT LIKE '%PSEUDOTUMOR CEREBRI%'
        AND UPPER (edg.DX_NAME) NOT LIKE '%BENIGN HYPERTENSION%INTRACRANIAL PRESSURE'
        AND UPPER (edg.DX_NAME) NOT LIKE '%MULTIPLE SCLEROSIS%'
        AND UPPER (edg.DX_NAME) NOT LIKE '%OPTIC NEURITIS%'
        AND UPPER (edg.DX_NAME) NOT LIKE '%ADEM %' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%(ADEM)%'
        AND UPPER (edg.DX_NAME) NOT LIKE '%VASCULITIS%'
        AND UPPER (edg.DX_NAME) NOT LIKE '%INTRACRANIAL TUMOR%'
        AND (UPPER (edg.DX_NAME) NOT LIKE '%MASS%' AND UPPER (edg.DX_NAME) NOT LIKE '%BODY MASS%')
        AND UPPER (edg.DX_NAME) NOT LIKE '%TUMOR%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%LYMPHOMA%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%LEUKEMIA%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%ANEMIA%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%INFECTION%'
        AND UPPER (edg.DX_NAME) NOT LIKE '%INFECTIOUS%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%MENINGITIS%'
        AND UPPER (edg.DX_NAME) NOT LIKE '%SINUSITIS%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%ENCEPHALITIS%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%PNEUMONIA%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%UPPER RESPIRATORY ILLNESS%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%ROCKY MOUNTAIN%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%BARTONELLA%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%INFLUENZA%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%STREP %'
        AND UPPER (edg.DX_NAME) NOT LIKE '%STREPTOCOCCAL%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%STAPHYLOC%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%COUGH%'
        AND UPPER (edg.DX_NAME) NOT LIKE '%FEVER%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%FEBRILE%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%SEPSIS%'
        AND UPPER (edg.DX_NAME) NOT LIKE '%SEPTIC%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%BACTEREMIA%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%OTITIS MEDIA%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%ABSCESS%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%SORE THROAT%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%ACUTE URI %' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%VIRAL ILLNESS%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%VIRAL PHARYNGITIS%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%VP SHUNT%' 
        AND UPPER (edg.DX_NAME) NOT LIKE '%CEREBRAL VENTRICULOMEGALY%' 
ORDER BY pat.PAT_MRN_ID, hsp.CONTACT_DATE, hsp.PAT_ENC_CSN_ID, rsn.LINE, dx.PRIMARY_DX_YN DESC, cm.NAME, mar.SCHEDULED_TIME
    )

PIVOT
    (MIN (ENC_REASON_NAME)
        FOR LINE IN ('1' AS PrimaryChiefComplaint, '2' AS SecondaryChiefComplaint1, '3' AS SecondaryChiefComplaint2)

    )
)

--PIVOT
--    (MIN(DX_NAME)
--        FOR DX_ID IN (SELECT DX_ID FROM PAT_ENC_DX)
--    )

)

PIVOT
    (MIN(BENEFIT_PLAN_NAME)
        FOR FILING_ORDER IN ('1' AS PrimaryCvgName, '2' AS SecondaryCvgName1, '3' AS SecondaryCvgName2)
    )
