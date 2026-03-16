--SELECT *
--FROM ZC_OR_ANSTAFF_TYPE

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
WHERE 
    orl.LOC_ID IN (1024304,1024305,1024302,1024303)
--    AND orl.STATUS_C = 5 -- Complete
    AND orl.SURGERY_DATE <= EPIC_UTIL.EFN_DIN('t-1')
--    AND pat.PAT_MRN_ID IN ('2351606', '1855176', '3267139', '4389836', '1777559')
    AND pat.PAT_MRN_ID = '4389836'
)

, ANESTH_EVENTS
AS
(
SELECT *
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

, LDA
AS
(
SELECT
    cdt.LOG_ID
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




--
--
--, PAT_POSITION
--AS
--(
--SELECT
--    cdt.LOG_ID
--    , zc_pos.NAME "Position"
--    , zc_prot.NAME "Checklist"
--    , ed_ev.EVENT_DISPLAY_NAME
--    , ed_ev.EVENT_TIME
--FROM CASE_DATA cdt
--    LEFT OUTER JOIN OR_LOG_LN_PATPOSP1 orl_pos ON cdt.LOG_ID = orl_pos.LOG_ID
--    LEFT OUTER JOIN OR_LNLG_POSITION or_pos ON orl_pos.PAN_1_PATPOS_ID = or_pos.RECORD_ID
--    LEFT OUTER JOIN ZC_OR_POS_BODY zc_pos ON or_pos.PAT_POSITION_C = zc_pos.OR_POS_BODY_C
--    LEFT OUTER JOIN OR_LNLG_POS_PROT or_prot ON or_pos.RECORD_ID = or_prot.RECORD_ID
--    LEFT OUTER JOIN ZC_PAT_PROTECTION zc_prot ON or_prot.PAT_PROTECTION_C = zc_prot.PAT_PROTECTION_C
--    LEFT OUTER JOIN F_AN_RECORD_SUMMARY fans ON cdt.LOG_ID = fans.LOG_ID
--    LEFT OUTER JOIN ED_IEV_PAT_INFO ed_pat ON fans.AN_52_ENC_CSN_ID = ed_pat.PAT_CSN
--    LEFT OUTER JOIN ED_IEV_EVENT_INFO ed_ev ON ed_pat.EVENT_ID = ed_ev.EVENT_ID
--)
