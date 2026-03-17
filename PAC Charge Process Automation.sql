SELECT
            TO_CHAR(orl.SURGERY_DATE,'MM/DD/YYYY') "Surgery Date"
            , orl.SURGERY_DATE
            , orl.LOG_ID
            , pat.PAT_ID
            , pat.PAT_MRN_ID
            , enc.PAT_ENC_CSN_ID
            , enc.INPATIENT_DATA_ID
            , pat.PAT_NAME
            , vlb.PRIMARY_PHYSICIAN_NM
            , bil.RECORD_NAME "Surgical Service"
            , loc2.LOC_NAME "Parent Location"
            , orl.CASE_CLASS_C
            , zc_cc.NAME "Case Class Name"
            , pbt.CPT_CODE
            , eap.PROC_NAME
            , vlp.WOUND_CLASS_NM
            , olc.TRACKING_EVENT_C
            , olc.TRACKING_TIME_IN
            , RANK() OVER ( PARTITION BY orl.LOG_ID ORDER BY orl.LOG_ID, pbt.CPT_CODE) rank
        FROM OR_LOG orl
            LEFT OUTER JOIN PAT_ENC enc ON enc.PAT_ENC_CSN_ID = pbt.PAT_ENC_CSN_ID
            LEFT OUTER JOIN PATIENT pat ON pbt.PATIENT_ID = pat.PAT_ID
            LEFT OUTER JOIN ZC_OR_CASE_CLASS zc_cc ON orl.CASE_CLASS_C = zc_cc.CASE_CLASS_C
            LEFT OUTER JOIN V_LOG_BASED vlb ON orl.LOG_ID = vlb.LOG_ID
            LEFT OUTER JOIN OR_LOG_CASE_TIMES olc ON orl.LOG_ID = olc.LOG_ID
            LEFT OUTER JOIN CLARITY_EAP eap ON pbt.PROC_ID = eap.PROC_ID
            LEFT OUTER JOIN ZC_OR_SERVICE zc_os ON orl.SERVICE_C = zc_os.SERVICE_C
            LEFT OUTER JOIN CLARITY_SER ser ON vlb.PRIMARY_PHYSICIAN_ID = ser.PROV_ID
            LEFT OUTER JOIN CLARITY_LOC loc ON orl.LOC_ID = loc.LOC_ID
            LEFT OUTER JOIN CLARITY_LOC loc2 ON loc.HOSP_PARENT_LOC_ID = loc2.LOC_ID
        WHERE
            FLOOR((orl.SURGERY_DATE - pat.BIRTH_DATE) / 365.25) >= 18
--            AND orl.SURGERY_DATE >= EPIC_UTIL.EFN_DIN('{?StartDate}')
--            AND orl.SURGERY_DATE <= EPIC_UTIL.EFN_DIN('{?EndDate}')
--            AND pbt.SERVICE_DATE >= EPIC_UTIL.EFN_DIN('{?StartDate}')
--            AND pbt.SERVICE_DATE <= EPIC_UTIL.EFN_DIN('{?EndDate}')
--            AND orl.SURGERY_DATE >= '01-Nov-2019'
            AND orl.SURGERY_DATE >= '01-Sep-2020'
            AND orl.SURGERY_DATE <= '30-Sep-2020'
            
            
            
--
-- Was a PAC appt completed prior to surgery?
--
, PAC_VISIT
AS
(
SELECT *
FROM
    (
    SELECT
        orl.LOG_ID
        , enc2.CONTACT_DATE
    FROM OR_CASE orc
        INNER JOIN PAT_OR_ADM_LINK lnk ON orc.LOG_ID = lnk.LOG_ID
        INNER JOIN PAT_ENC enc ON lnk.OR_LINK_CSN = enc.PAT_ENC_CSN_ID
        INNER JOIN PAT_ENC enc2 ON enc.HSP_ACCOUNT_ID = enc2.HSP_ACCOUNT_ID
            AND enc2.DEPARTMENT_ID IN ('1000106010 ','1008301044','1012301018', '1024301059')
            AND enc2.APPT_STATUS_C <> 3 --Not a cancelled visit ---PAC visit
        INNER JOIN OR_LOG orl ON orc.LOG_ID = orl.LOG_ID
            AND orl.OR_TIME_EVTS_ENT_C = 2  -- surgery completed
        INNER JOIN PAT_POP pp ON pp.LOG_ID = orl.LOG_ID
    WHERE
        enc2.APPT_TIME IS NOT NULL 
        AND orc.RECORD_CREATE_DATE <= enc2.APPT_TIME
        AND pp.LOG_ID = orl.LOG_ID
    ORDER BY
        enc2.CONTACT_DATE DESC
    )
--WHERE ROWNUM = 1
)
             
--
-- Was a PAC appt completed prior to surgery (PAC appointment not linked to the surgery)?
--
, UNLINKED_PAC_VISIT
AS
(
SELECT *
FROM
    (SELECT DISTINCT
        pp.LOG_ID
        , enc.CONTACT_DATE
    FROM PAT_POP pp
        INNER JOIN PAT_ENC enc ON pp.PAT_ID = enc.PAT_ID
            AND enc.DEPARTMENT_ID IN ('1000106010 ','1008301044','1012301018', '1024301059')
            AND enc.APPT_STATUS_C <> 3 --Not a cancelled visit ---PAC visit
    WHERE
        enc.APPT_TIME IS NOT NULL 
        AND enc.CONTACT_DATE >= pp.SURGERY_DATE - 60
        AND enc.CONTACT_DATE <= pp.SURGERY_DATE
        AND NOT EXISTS
            (SELECT
                pacv.LOG_ID
            FROM PAC_VISIT pacv
            WHERE pp.LOG_ID = pacv.LOG_ID        
            )
    ORDER BY
        enc.CONTACT_DATE DESC
    )
--WHERE ROWNUM = 1
)