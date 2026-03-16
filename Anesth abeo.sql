WITH
CASE_DATA
AS
(SELECT 
--    Patient Info
    pat.PAT_MRN_ID "MRN"
    , pat.PAT_ID
    , pat.PAT_NAME "Patient Name"
    , zc_s.NAME "Gender"
    , pat.BIRTH_DATE "DOB"
--Case Summary
    , orl.LOG_ID
    , orl.SURGERY_DATE "Date"
    , v_s.PNL_1_PRIM_SURG_NM_WID "Surgeon"
    , ser2.PROV_NAME "Responsible Provider"
    , v_s.ACTUAL_LOC_NAME "Location"
    , ser.PROV_NAME "Room"
    , v_s.PNL_1_PRIM_PROC_AS_ORDERED "Procedure"
    , zc_lat.NAME "Laterality"
    , orldx.PRE_OP_DIAG "Diagnosis"
    , v_s.ASA_RATING_C "ASA Status"
    , orl.CASE_TYPE_C
    , zc_occ.NAME "Case Class"
    , v_s.IN_PRE_PROCEDURE_DATETIME "In Pre-Procedure"
FROM OR_LOG orl
    LEFT OUTER JOIN ZC_OR_CASE_CLASS zc_occ ON orl.CASE_CLASS_C = zc_occ.CASE_CLASS_C
    LEFT OUTER JOIN PATIENT pat ON orl.PAT_ID = pat.PAT_ID
    LEFT OUTER JOIN ZC_SEX zc_s ON pat.SEX_C = zc_s.RCPT_MEM_SEX_C
    LEFT OUTER JOIN V_SURGERY v_s ON orl.LOG_ID = v_s.LOG_ID
    LEFT OUTER JOIN OR_LOG_PREOPDX orldx ON orl.LOG_ID = orldx.LOG_ID
    LEFT OUTER JOIN ZC_OR_LRB zc_lat ON v_s.PNL_1_PRIM_PROC_LATERALITY_C = zc_lat.LRB_C
    LEFT OUTER JOIN CLARITY_SER ser ON v_s.ACTUAL_ROOM_ID = ser.PROV_ID
    LEFT OUTER JOIN F_AN_RECORD_SUMMARY fans ON orl.LOG_ID = fans.LOG_ID
    LEFT OUTER JOIN CLARITY_SER ser2 ON fans.AN_RESP_PROV_ID = ser2.PROV_ID
WHERE 
    orl.LOC_ID IN (1024304,1024305,1024302,1024303)
--    AND orl.STATUS_C = 5 -- Complete
    AND orl.SURGERY_DATE <= EPIC_UTIL.EFN_DIN('t-3')
    AND orl.SURGERY_DATE >= EPIC_UTIL.EFN_DIN('t-3')
--    AND pat.PAT_MRN_ID = '1054809'
)

, ANES_PROVIDER1
AS
(SELECT *
FROM
(
SELECT DISTINCT
    cdt.LOG_ID
    , ser.PROV_ID
    , ser.PROV_NAME "Anes1 Name"
    , ser.PROV_TYPE "Role"
    , ans.AN_BEGIN_LOCAL_DTTM "Begin Time"
    , ans.AN_END_LOCAL_DTTM "End Time"
    , RANK() OVER ( PARTITION BY cdt.LOG_ID ORDER BY cdt.LOG_ID, ser.PROV_ID) rank
FROM CASE_DATA cdt
    LEFT OUTER JOIN F_AN_RECORD_SUMMARY fans ON cdt.LOG_ID = fans.LOG_ID
    LEFT OUTER JOIN AN_STAFF ans ON fans.AN_EPISODE_ID = ans.SUMMARY_BLOCK_ID
    LEFT OUTER JOIN CLARITY_SER ser ON ans.AN_PROV_ID = ser.PROV_ID
WHERE ans.AN_PROV_TYPE_C = 10
ORDER BY ser.PROV_ID
)
WHERE rank = 1
)

, ANES_PROVIDER2
AS
(SELECT *
FROM
(
SELECT DISTINCT
    cdt.LOG_ID
    , ser.PROV_ID
    , ser.PROV_NAME "Anes2 Name"
    , ser.PROV_TYPE "Role"
    , ans.AN_BEGIN_LOCAL_DTTM "Begin Time"
    , ans.AN_END_LOCAL_DTTM "End Time"
    , RANK() OVER ( PARTITION BY cdt.LOG_ID ORDER BY cdt.LOG_ID, ser.PROV_ID) rank
FROM CASE_DATA cdt
    LEFT OUTER JOIN F_AN_RECORD_SUMMARY fans ON cdt.LOG_ID = fans.LOG_ID
    LEFT OUTER JOIN AN_STAFF ans ON fans.AN_EPISODE_ID = ans.SUMMARY_BLOCK_ID
    LEFT OUTER JOIN CLARITY_SER ser ON ans.AN_PROV_ID = ser.PROV_ID
WHERE ans.AN_PROV_TYPE_C = 10
ORDER BY ser.PROV_ID
)
WHERE rank = 2
)

, CRNA_PROVIDER1
AS
(SELECT *
FROM
(
SELECT DISTINCT
    cdt.LOG_ID
    , ser.PROV_ID
    , ser.PROV_NAME "CRNA1 Name"
    , ser.PROV_TYPE "Role"
    , ans.AN_BEGIN_LOCAL_DTTM "Begin Time"
    , ans.AN_END_LOCAL_DTTM "End Time"
    , RANK() OVER ( PARTITION BY cdt.LOG_ID ORDER BY cdt.LOG_ID, ser.PROV_ID) rank
FROM CASE_DATA cdt
    LEFT OUTER JOIN F_AN_RECORD_SUMMARY fans ON cdt.LOG_ID = fans.LOG_ID
    LEFT OUTER JOIN AN_STAFF ans ON fans.AN_EPISODE_ID = ans.SUMMARY_BLOCK_ID
    LEFT OUTER JOIN CLARITY_SER ser ON ans.AN_PROV_ID = ser.PROV_ID
WHERE ans.AN_PROV_TYPE_C = 20
ORDER BY ser.PROV_ID
)
WHERE rank = 1
)

, CRNA_PROVIDER2
AS
(SELECT *
FROM
(
SELECT DISTINCT
    cdt.LOG_ID
    , ser.PROV_ID
    , ser.PROV_NAME "CRNA2 Name"
    , ser.PROV_TYPE "Role"
    , ans.AN_BEGIN_LOCAL_DTTM "Begin Time"
    , ans.AN_END_LOCAL_DTTM "End Time"
    , RANK() OVER ( PARTITION BY cdt.LOG_ID ORDER BY cdt.LOG_ID, ser.PROV_ID) rank
FROM CASE_DATA cdt
    LEFT OUTER JOIN F_AN_RECORD_SUMMARY fans ON cdt.LOG_ID = fans.LOG_ID
    LEFT OUTER JOIN AN_STAFF ans ON fans.AN_EPISODE_ID = ans.SUMMARY_BLOCK_ID
    LEFT OUTER JOIN CLARITY_SER ser ON ans.AN_PROV_ID = ser.PROV_ID
WHERE ans.AN_PROV_TYPE_C = 20
ORDER BY ser.PROV_ID
)
WHERE rank = 2
)

, ANESTH_EVENTS
AS
(SELECT *
FROM
    (SELECT *
    FROM
        (SELECT DISTINCT
            cdt.LOG_ID
            , cdt."MRN"
            , cdt."In Pre-Procedure"
            , evnt.EVENT_TYPE "Event Type"
            , evnt.EVENT_TIME "Event Time"
        FROM CASE_DATA cdt
            LEFT OUTER JOIN F_AN_RECORD_SUMMARY fans ON cdt.LOG_ID = fans.LOG_ID
            LEFT OUTER JOIN ED_IEV_PAT_INFO patinf ON fans.AN_52_ENC_CSN_ID = patinf.PAT_CSN
            LEFT OUTER JOIN ED_IEV_EVENT_INFO evnt ON patinf.EVENT_ID = evnt.EVENT_ID
        WHERE evnt.EVENT_TYPE IN ('1120000001', '1120000014', '1120000008', '1120000009', '100277', '100285', '1120000007', '1120000045',
                                                                '1120000015', '1120000002')
        )
    )

    PIVOT 
          (MAX ("Event Time") FOR  "Event Type" IN 
                            ('1120000001' AS "Anesthesia Start"
                            ,'1120000014' AS "Start Data Collection"
                            ,'1120000008' AS "Induction"
                            ,'1120000009' AS "Intubation"
                            ,'100277' AS "Anesthesia Ready"
                            ,'100285' AS "Incision Time"
                            ,'1120000007' AS "Emergence"
                            ,'1120000045' AS "Extubation"
                            ,'1120000015' AS "Stop Data Collection"
                            ,'1120000002' AS "Anesthesia Stop")
          )
)

, MEDS_ADMIN
AS
(SELECT DISTINCT
    fans.LOG_ID
--    pat.PAT_MRN_ID "Patient MRN"
--    , om.ORDER_MED_ID "Order Med ID"
    , cm.NAME "Drug Name"
--    , cm.STRENGTH "Drug Strength"
--    , vrx.COST "Drug Cost"
--    , vrx.BILLING_QUANTITY "Billing Quantity"
--    , aev."Anesthesia Start"
--    , mar.TAKEN_TIME "Dose Given Date/Time"
--    , aev."Anesthesia Stop"
--    , CASE WHEN aev."Anesthesia Start" <= mar.TAKEN_TIME THEN 'Yes' END AS "After Start"
--    , CASE WHEN aev."Anesthesia Stop" >= mar.TAKEN_TIME THEN 'Yes' END AS "Before Stop"
--    , mar.SIG "Dose Amount"
    , zcmu.NAME "Dose Unit"
    , (SELECT SUM(mar2.SIG)
        FROM CASE_DATA cdt2
            LEFT OUTER JOIN F_AN_RECORD_SUMMARY fans2 ON cdt2.LOG_ID = fans2.LOG_ID
            LEFT OUTER JOIN MAR_ADMIN_INFO mar2 ON fans2.AN_52_ENC_CSN_ID = mar2.MAR_ENC_CSN
            LEFT OUTER JOIN ORDER_MED om2 ON mar2.ORDER_MED_ID = om2.ORDER_MED_ID
            LEFT OUTER JOIN CLARITY_MEDICATION cm2 ON om2.MEDICATION_ID = cm2.MEDICATION_ID
            LEFT OUTER JOIN V_SURGERY vs2 ON fans2.LOG_ID = vs2.LOG_ID
            LEFT OUTER JOIN ANESTH_EVENTS aev2 ON cdt2.LOG_ID = aev2.LOG_ID
        WHERE aev2."Anesthesia Start" <= mar2.TAKEN_TIME
            AND aev2."Anesthesia Stop" >= mar2.TAKEN_TIME
            AND fans.LOG_ID = fans2.LOG_ID
            AND cm.NAME = cm2.NAME) AS "Calculated Total"
FROM CASE_DATA cdt
    LEFT OUTER JOIN F_AN_RECORD_SUMMARY fans ON cdt.LOG_ID = fans.LOG_ID
    LEFT OUTER JOIN MAR_ADMIN_INFO mar ON fans.AN_52_ENC_CSN_ID = mar.MAR_ENC_CSN
    LEFT OUTER JOIN ORDER_MED om ON mar.ORDER_MED_ID = om.ORDER_MED_ID
--    LEFT OUTER JOIN GROUPER_MED_RECS gmr ON om.MEDICATION_ID = gmr.EXP_MEDS_LIST_ID
    LEFT OUTER JOIN CLARITY_MEDICATION cm ON om.MEDICATION_ID = cm.MEDICATION_ID
    LEFT OUTER JOIN V_SURGERY vs ON fans.LOG_ID = vs.LOG_ID
    LEFT OUTER JOIN ZC_MED_UNIT zcmu ON mar.DOSE_UNIT_C = zcmu.DISP_QTYUNIT_C
--    LEFT OUTER JOIN PATIENT pat ON fans.AN_PAT_ID = pat.PAT_ID
--    LEFT OUTER JOIN V_RX_CHARGES vrx ON om.ORDER_MED_ID = vrx.ORDER_ID
    LEFT OUTER JOIN ANESTH_EVENTS aev ON cdt.LOG_ID = aev.LOG_ID
WHERE aev."Anesthesia Start" <= mar.TAKEN_TIME
    AND aev."Anesthesia Stop" >= mar.TAKEN_TIME
GROUP BY
    fans.LOG_ID
    , cm.NAME
    , mar.TAKEN_TIME
    , mar.SIG
    , zcmu.NAME
)

, PAT_POSITION
AS
(
SELECT
    cdt.LOG_ID
    , zc_pos.NAME "Position"
    , zc_prot.NAME "Checklist"
    , ed_ev.EVENT_DISPLAY_NAME
    , ed_ev.EVENT_TIME
FROM CASE_DATA cdt
    LEFT OUTER JOIN OR_LOG_LN_PATPOSP1 orl_pos ON cdt.LOG_ID = orl_pos.LOG_ID
    LEFT OUTER JOIN OR_LNLG_POSITION or_pos ON orl_pos.PAN_1_PATPOS_ID = or_pos.RECORD_ID
    LEFT OUTER JOIN ZC_OR_POS_BODY zc_pos ON or_pos.PAT_POSITION_C = zc_pos.OR_POS_BODY_C
    LEFT OUTER JOIN OR_LNLG_POS_PROT or_prot ON or_pos.RECORD_ID = or_prot.RECORD_ID
    LEFT OUTER JOIN ZC_PAT_PROTECTION zc_prot ON or_prot.PAT_PROTECTION_C = zc_prot.PAT_PROTECTION_C
    LEFT OUTER JOIN F_AN_RECORD_SUMMARY fans ON cdt.LOG_ID = fans.LOG_ID
    LEFT OUTER JOIN ED_IEV_PAT_INFO ed_pat ON fans.AN_52_ENC_CSN_ID = ed_pat.PAT_CSN
    LEFT OUTER JOIN ED_IEV_EVENT_INFO ed_ev ON ed_pat.EVENT_ID = ed_ev.EVENT_ID
)

, LDA
AS
(
SELECT
    cdt.PAT_ID
--    flo_gp2.FLO_MEAS_NAME
--    , flo_meas.FSD_ID
--    , flo_meas.LINE
    , flo_meas.ENTRY_TIME
--    , aev."Anesthesia Start"
--    , aev."Anesthesia Stop"
    , flo_gp.DISP_NAME "Type"
    , lda.PROPERTIES_DISPLAY "Details"
    , flo_gp2.DISP_NAME "Display Name"
    , flo_meas.MEAS_VALUE "Display Value"
    , emp.NAME "Provider Name"
    , ser.PROV_TYPE "Provider Title"
FROM CASE_DATA cdt
    LEFT OUTER JOIN IP_LDA_NOADDSINGLE lda ON cdt.PAT_ID = lda.PAT_ID
    LEFT OUTER JOIN IP_FLO_GP_DATA flo_gp ON lda.FLO_MEAS_ID = flo_gp.FLO_MEAS_ID
    LEFT OUTER JOIN IP_FLOWSHEET_ROWS flo_row ON lda.IP_LDA_ID = flo_row.IP_LDA_ID
    LEFT OUTER JOIN IP_FLWSHT_REC flo_rec ON flo_row.INPATIENT_DATA_ID = flo_rec.INPATIENT_DATA_ID
    LEFT OUTER JOIN IP_FLWSHT_MEAS flo_meas ON flo_row.LINE =flo_meas.OCCURANCE
        AND flo_rec.FSD_ID = flo_meas.FSD_ID
    LEFT OUTER JOIN CLARITY_EMP emp ON flo_meas.TAKEN_USER_ID = emp.USER_ID
    LEFT OUTER JOIN CLARITY_SER ser ON emp.PROV_ID = ser.PROV_ID
    LEFT OUTER JOIN IP_FLO_GP_DATA flo_gp2 ON flo_meas.FLO_MEAS_ID = flo_gp2.FLO_MEAS_ID
    LEFT OUTER JOIN ANESTH_EVENTS aev ON cdt.LOG_ID = aev.LOG_ID
WHERE aev."In Pre-Procedure" <= flo_meas.ENTRY_TIME
    AND aev."Anesthesia Stop" >= flo_meas.ENTRY_TIME
)

, ANESTH_TYPE
AS
(
SELECT
    fans.AN_LOG_ID
--    , sed.ELEMENT_ID
--    , sed.CONTEXT_NAME
    , sev.SMRTDTA_ELEM_VALUE "Anesth Type"
FROM CASE_DATA cdt
    INNER JOIN F_AN_RECORD_SUMMARY fans ON cdt.LOG_ID = fans.AN_LOG_ID
    INNER JOIN SMRTDTA_ELEM_DATA sed ON fans.AN_53_ENC_CSN_ID = sed.CONTACT_SERIAL_NUM
    INNER JOIN SMRTDTA_ELEM_VALUE sev ON sed.HLV_ID = sev.HLV_ID
WHERE sed.ELEMENT_ID = 'EPIC#0251' -- Workflow: Anesthesia Plan
)


SELECT
    cdt.LOG_ID "Log ID"
    , cdt."MRN"
    , cdt."Patient Name"
    , cdt."Gender"
    , cdt."DOB"
    , cdt."Date"
    , cdt."Surgeon"
    , cdt."Location"
    , cdt."Room"
    , cdt."Procedure"
    , cdt."Laterality"
    , cdt."Diagnosis"
    , cdt."ASA Status"
    , cdt."Case Class"
    , atp."Anesth Type"
    , ap1."Anes1 Name"
    , ap1."Role"
    , ap1."Begin Time"
    , ap1."End Time"
    , ap2."Anes2 Name"
    , ap2."Role"
    , ap2."Begin Time"
    , ap2."End Time"
    , cp1."CRNA1 Name"
    , cp1."Role"
    , cp1."Begin Time"
    , cp1."End Time"
    , cp2."CRNA2 Name"
    , cp2."Role"
    , cp2."Begin Time"
    , cp2."End Time"
    , aev."Anesthesia Start"
    , aev."Start Data Collection"
    , aev."Induction"
    , aev."Intubation"
    , aev."Anesthesia Ready"
    , aev."Incision Time"
    , aev."Emergence"
    , aev."Extubation"
    , aev."Stop Data Collection"
    , aev."Anesthesia Stop"
    , mad."Drug Name"
    , mad."Calculated Total"
    , mad."Dose Unit"
    , pos."Position"
    , pos."Checklist"
    , lda."Type"
    , lda."Details"
    , lda."Display Name"
    , lda."Display Value"
    , lda."Provider Name"
    , lda."Provider Title"
FROM CASE_DATA cdt
    LEFT OUTER JOIN ANES_PROVIDER1 ap1 ON cdt.LOG_ID = ap1.LOG_ID
    LEFT OUTER JOIN ANES_PROVIDER2 ap2 ON cdt.LOG_ID = ap2.LOG_ID
    LEFT OUTER JOIN CRNA_PROVIDER1 cp1 ON cdt.LOG_ID = cp1.LOG_ID
    LEFT OUTER JOIN CRNA_PROVIDER2 cp2 ON cdt.LOG_ID = cp2.LOG_ID
    LEFT OUTER JOIN ANESTH_EVENTS aev ON cdt.LOG_ID = aev.LOG_ID
    LEFT OUTER JOIN MEDS_ADMIN mad ON cdt.LOG_ID = mad.LOG_ID
    LEFT OUTER JOIN PAT_POSITION  pos ON cdt.LOG_ID = pos.LOG_ID
    LEFT OUTER JOIN LDA lda ON cdt.PAT_ID = lda.PAT_ID
    LEFT OUTER JOIN ANESTH_TYPE atp ON cdt.LOG_ID = atp.AN_LOG_ID
    
    
