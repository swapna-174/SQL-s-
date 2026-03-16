WITH PAT_POP
AS
(
    SELECT DISTINCT
        pat.PAT_MRN_ID "MRN"
        , pat.PAT_ID
        , pat.PAT_NAME "Patient Name"
        , orl.LOG_ID "Log ID"
        , orl.SURGERY_DATE "Surgery Date"
        , ser.PROV_NAME "Surgery Provider Name"
        , pbt.TX_ID
    FROM ARPB_TRANSACTIONS pbt
        LEFT OUTER JOIN ARPB_TX_MODERATE atm ON pbt.TX_ID = atm.TX_ID
        LEFT OUTER JOIN PAT_ENC enc ON enc.PAT_ENC_CSN_ID = pbt.PAT_ENC_CSN_ID
        LEFT OUTER JOIN PATIENT pat ON pbt.PATIENT_ID = pat.PAT_ID
        LEFT OUTER JOIN OR_LOG orl ON atm.SURGICAL_LOG_ID = orl.LOG_ID
        LEFT OUTER JOIN V_LOG_BASED vlb ON orl.LOG_ID = vlb.LOG_ID
        LEFT OUTER JOIN CLARITY_SER ser ON vlb.PRIMARY_PHYSICIAN_ID = ser.PROV_ID
        
    WHERE
        pbt.CPT_CODE = '22633'
--        AND pbt.TX_TYPE_C = 1
        AND pbt.VOID_DATE IS NULL
        AND vlb.PRIMARY_PHYSICIAN_ID IN ('18662', '10141')
)

, CHG_PAY_ADJ
AS
(
SELECT DISTINCT
    pbt.TX_ID
    , pbt.PAT_ID
    , pbt.PROC_ID
    , pbt.SERVICE_PROV_ID
    , pbt.DEPARTMENT_ID
    , pbt.SERVICE_DATE
    , pbt.PAT_ENC_CSN_ID
    , enc.ENC_TYPE_C
    , zc_enc.NAME "Ancillary Encounter Type"
    , pbt.CPT_CODE
    , SUM(pbt.CHARGE) "Ancillary Total Charges"
    , SUM(pbt.PAYMENT) "Ancillary Total Payments"
    , SUM((pbt.DEBIT_ADJ + pbt.CREDIT_ADJ)) AS "Ancillary Total Adjustments"
FROM V_ARPB_TX_ACTIVITY pbt
    INNER JOIN ARPB_TRANSACTIONS arpb ON pbt.TX_ID = arpb.TX_ID
    INNER JOIN PAT_POP pp ON pbt.PAT_ID = pp.PAT_ID
    INNER JOIN PAT_ENC enc ON pbt.PAT_ENC_CSN_ID = enc.PAT_ENC_CSN_ID
    INNER JOIN ZC_DISP_ENC_TYPE zc_enc ON enc.ENC_TYPE_C = zc_enc.DISP_ENC_TYPE_C
    LEFT OUTER JOIN CLARITY_PRC prc ON enc.APPT_PRC_ID = prc.PRC_ID
WHERE
    pp."Surgery Date" - 365 <= pbt.SERVICE_DATE
    AND pp."Surgery Date" + 90 >= pbt.SERVICE_DATE
    AND pbt.VOID_YN = 0
    AND arpb.VOID_DATE IS NULL
GROUP BY
    pbt.TX_ID
    , pbt.PAT_ID
    , pbt.PROC_ID
    , pbt.SERVICE_PROV_ID
    , pbt.DEPARTMENT_ID
    , pbt.SERVICE_DATE
    , pbt.PAT_ENC_CSN_ID
    , enc.ENC_TYPE_C
    , zc_enc.NAME
    , pbt.CPT_CODE
)

SELECT DISTINCT
    pp."MRN"
    , pp."Patient Name"
    , pp."Log ID"
    , pp."Surgery Date"
    , pp."Surgery Provider Name"
    , eap.PROC_NAME "Ancillary Procedure"
    , ser.PROV_NAME "Ancillary Provider"
    , dep.DEPARTMENT_NAME "Ancillary Department"
    , cpa.SERVICE_DATE "Ancillary Service Date"
    , cpa."Ancillary Encounter Type"
    , cpa.PAT_ENC_CSN_ID "Ancillary CSN"
    , cpa.CPT_CODE "Ancillary CPT Code"
    , cpa."Ancillary Total Charges"
    , cpa."Ancillary Total Payments"
    , cpa."Ancillary Total Adjustments"


FROM PAT_POP pp
    INNER JOIN CHG_PAY_ADJ cpa ON pp.PAT_ID = cpa.PAT_ID
    LEFT OUTER JOIN CLARITY_EAP eap ON cpa.PROC_ID = eap.PROC_ID
    LEFT OUTER JOIN CLARITY_SER ser ON cpa.SERVICE_PROV_ID = ser.PROV_ID
    LEFT OUTER JOIN CLARITY_DEP dep ON cpa.DEPARTMENT_ID = dep.DEPARTMENT_ID
--WHERE cpa.PAT_ENC_CSN_ID = '30075357806'
--    TRUNC(MONTHS_BETWEEN(pp.SURGERY_DATE, pbt.SERVICE_DATE)) <=12
--    AND TRUNC(MONTHS_BETWEEN(pp.SURGERY_DATE, pbt.SERVICE_DATE)) >= 3

--    AND pbt.TX_TYPE_C = 1
ORDER BY
    pp."MRN"
    , pp."Log ID"
    , cpa.SERVICE_DATE