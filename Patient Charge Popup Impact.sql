WITH NOTES
AS
--
-- This report queries for Hospitalist notes which do not have attached charges.  Exceptions are:
--    1. Progress Notes on the day of an admission: If an Admission Note and charge exists, additional Progress Notes 
--        on the same day do not generate additional charges. 
--    2. Interim Discharge Notes: When a shift change occurs, some providers write Interim Discharge Notes to "sign out patients".
--    	 These are not charged but there will be a Progress Note and a charge that day. 
--    3. Different author on note vs charge: When working with an APP many times the author of the note will be the APP
--    	 but the charge will go under the name of the MD as a shared visit. 
--
(
--
-- Find all notes by primary signer
-- 
SELECT DISTINCT
        info.NOTE_ID "NoteID"
        , enc_info.AUTHOR_USER_ID "AuthUserName"
--        , info.CURRENT_AUTHOR_ID
--        , emp.USER_NAME_EXT
        , ser.PROV_ID "AuthProvID"
        , ser.PROV_NAME "AuthProvName"
        , ser.PROV_TYPE "AuthProvType"
--        , emp3.NAME "Entry Name"
--        , info.ENTRY_DATETIME "Entry Date"
        , zc_serv2.NAME "Service"
        , ser2.PROV_ID "LinkedProvID"
        , ser2.PROV_NAME "LinkedProvName"
        , ser2.PROV_TYPE "LinkedProvType"
        , zc_note.NAME "NoteType"
--        , enc_info.NOTE_STATUS_C "Note Status Code"
--        , info.UNSIGNED_YN "Unsigned Y/N"
        , zc_ns.NAME "Note Status Name"
--        , info.DATE_OF_SERVIC_DTTM "UtcSerDate"
       , EPIC_UTIL.EFN_UTC_TO_LOCAL(info.DATE_OF_SERVIC_DTTM) "Note Service Date"
--       , info.ENTRY_DATETIME "Note Signed Date"
--       , enc_info.UPD_AUT_LOCAL_DTTM "Note Signed Date"
       , EPIC_UTIL.EFN_UTC_TO_LOCAL(enc_info.UPD_AUTHOR_INS_DTTM) "Note Signed Date"
       , info.PAT_ENC_CSN_ID "PatEncCsnID"
       , info.Pat_ID "PatID"
       , pat.PAT_MRN_ID "MRN"
        FROM HNO_INFO info
        INNER JOIN ZC_NOTE_TYPE_IP zc_note ON info.IP_NOTE_TYPE_C = zc_note.TYPE_IP_C
        -- Current Author
        LEFT OUTER JOIN CLARITY_EMP emp ON info.CURRENT_AUTHOR_ID = emp.USER_ID
        LEFT OUTER JOIN CLARITY_EMP emp3 ON info.ENTRY_USER_ID = emp3.USER_ID
        LEFT OUTER JOIN CLARITY_SER ser ON emp.PROV_ID = ser.PROV_ID        
        LEFT OUTER JOIN CLARITY_SER_SPEC spec ON ser.PROV_ID = spec.PROV_ID
        LEFT OUTER JOIN ZC_SPECIALTY zc_spec ON spec.SPECIALTY_C = zc_spec.SPECIALTY_C
        LEFT OUTER JOIN CLARITY_DEP dep ON emp.LGIN_DEPARTMENT_ID = dep.DEPARTMENT_ID
        -- Linked Author
        LEFT OUTER JOIN NOTE_ENC_INFO enc_info ON info.NOTE_ID = enc_info.NOTE_ID
--            AND emp.PROV_ID <> enc_info.AUTH_LNKED_PROV_ID
        LEFT OUTER JOIN CLARITY_SER ser2 ON enc_info.AUTH_LNKED_PROV_ID = ser2.PROV_ID
        LEFT OUTER JOIN CLARITY_SER_SPEC spec2 ON ser2.PROV_ID = spec2.PROV_ID
        LEFT OUTER JOIN ZC_SPECIALTY zc_spec2 ON spec2.SPECIALTY_C = zc_spec2.SPECIALTY_C
        LEFT OUTER JOIN ZC_CLINICAL_SVC zc_serv2 ON enc_info.AUTHOR_SERVICE_C = zc_serv2.CLINICAL_SVC_C
        LEFT OUTER JOIN CLARITY_EMP emp2 ON ser2.PROV_ID = emp2.PROV_ID
        LEFT OUTER JOIN CLARITY_DEP dep2 ON emp2.LGIN_DEPARTMENT_ID = dep2.DEPARTMENT_ID
        LEFT OUTER JOIN PATIENT pat ON info.PAT_ID = pat.PAT_ID
        LEFT OUTER JOIN ZC_CLINICAL_SVC zc_cs ON enc_info.AUTHOR_SERVICE_C = zc_cs.CLINICAL_SVC_C
        LEFT OUTER JOIN ZC_NOTE_STATUS zc_ns ON enc_info.NOTE_STATUS_C = zc_ns.NOTE_STATUS_C
        WHERE 
            info.IP_NOTE_TYPE_C IN ('1','2','3','4','5','29', '100003', '3043001135') 
            AND info.DATE_OF_SERVIC_DTTM >= EPIC_UTIL.EFN_DIN('t-42')
            AND info.DATE_OF_SERVIC_DTTM <= EPIC_UTIL.EFN_DIN('t-14')
            AND enc_info.NOTE_STATUS_C = 2  -- 2=Signed
--            AND info.DATE_OF_SERVIC_DTTM >= EPIC_UTIL.EFN_DIN('{?StartDate}')
--            AND info.DATE_OF_SERVIC_DTTM <= EPIC_UTIL.EFN_DIN('{?EndDate}')
)

, DISCHARGES
AS
(
--
-- Get the population of discharged patients
--
    SELECT DISTINCT
        peh.PAT_ENC_CSN_ID "PatEncCsnID"
        , zc_class.NAME "PatClass"
        , NVL(peh.DEPARTMENT_ID, adt.DEPARTMENT_ID) "Department_ID"
        , dep.REV_LOC_ID "LocID"
        , loc.LOC_NAME "Billing Location"
        , par.LOC_NAME "Parent Location"
        , peh.HOSP_ADMSN_TIME "HospAdmTime"
        , peh.INP_ADM_DATE "InpAdmTime"
        , peh.HOSP_DISCH_TIME "HospDisTime"
        , peh.HSP_ACCOUNT_ID "HspAcctID"
        , pat.PAT_ID
        , pat.PAT_NAME
        , pat.PAT_MRN_ID
        , CASE
            WHEN hsd.BASE_CLASS_MAP_C = 1 THEN 'Inpatient'
            WHEN hsd.BASE_CLASS_MAP_C = 2 THEN 'Outpatient'
            WHEN hsd.BASE_CLASS_MAP_C = 3 THEN 'Emergency' 
        END "BasePatClass" 
    FROM PAT_ENC_HSP peh
        LEFT OUTER JOIN CLARITY_ADT adt ON peh.DIS_EVENT_ID = adt.EVENT_ID
        INNER JOIN PATIENT_3 pat3 ON peh.PAT_ID = pat3.PAT_ID
        INNER JOIN PATIENT pat ON peh.PAT_ID = pat.PAT_ID
        LEFT OUTER JOIN CLARITY_DEP dep ON NVL(peh.DEPARTMENT_ID, adt.DEPARTMENT_ID) = dep.DEPARTMENT_ID
        LEFT OUTER JOIN CLARITY_LOC loc ON dep.REV_LOC_ID = loc.LOC_ID
        LEFT OUTER JOIN CLARITY_LOC par ON loc.HOSP_PARENT_LOC_ID = par.LOC_ID
        LEFT OUTER JOIN HSD_BASE_CLASS_MAP hsd ON peh.ADT_PAT_CLASS_C = hsd.ACCT_CLASS_MAP_C
        LEFT OUTER JOIN ZC_PAT_CLASS zc_class ON peh.ADT_PAT_CLASS_C = zc_class.ADT_PAT_CLASS_C
    WHERE peh.PAT_ENC_CSN_ID IN (SELECT DISTINCT fin."PatEncCsnID" FROM NOTES fin)
        AND (hsd.BASE_CLASS_MAP_C = 1 or zc_class.NAME = 'Observation') 
        AND loc.SERV_AREA_ID = 10
        AND NVL(pat3.IS_TEST_PAT_YN,'N') = 'N'
	
)

--
-- Join Notes and Discharges to their PB transactions
--

, MISSING_TXNS
AS
(
    SELECT 
        fin."NoteID"
        , dis."PatEncCsnID"
        , dis."HspAcctID"
        , dis."PatClass"
        , dis."BasePatClass"
        , dis.PAT_NAME
        , dis.PAT_ID
        , dis.PAT_MRN_ID
        , dis."Billing Location"
        , dis."Parent Location"
        , dis."HospAdmTime"
        , dis."InpAdmTime"
        , dis."HospDisTime"
        , fin."NoteType"
--        , fin."Note Status Code"
        , fin."Note Status Name"
--        , fin."Unsigned Y/N"
        , fin."Note Service Date"
        , fin."Note Signed Date"
        , fin."AuthProvID"
        , fin."AuthUserName"
        , fin."AuthProvName"
        , fin."AuthProvType"
        , fin."Service"
--        , fin."Entry Name"
--        , fin."Entry Date"
        , fin."LinkedProvID"
        , fin."LinkedProvName"
        , fin."LinkedProvType"
        , arpb.TX_ID "TxID txn"
        , arpb.DEPARTMENT_ID "Department txn"
        , dep.DEPARTMENT_NAME "Billing Department"
        , arpb.SERVICE_AREA_ID "Service txn"
        , arpb.CPT_CODE "CPTCode txn"
        , arpb.SERVICE_DATE "Charge Service Date"
        , arpb.POST_DATE "Charge File Date"
        , eap.PROC_NAME "ProcedureName txn"
    FROM DISCHARGES dis
        INNER JOIN NOTES fin ON dis."PatEncCsnID" = fin."PatEncCsnID"
        LEFT JOIN ARPB_TRANSACTIONS arpb ON dis."PatEncCsnID" = arpb.PAT_ENC_CSN_ID
            AND arpb.TX_TYPE_C = '1'
            AND (TRUNC(fin."Note Service Date") = arpb.SERVICE_DATE
                OR (CASE 
                    WHEN fin."NoteType" = 'Discharge Summaries' 
                    THEN TRUNC(dis."HospDisTime")
                END = arpb.SERVICE_DATE))
            AND (fin."AuthProvID" = arpb.BILLING_PROV_ID 
                OR fin."AuthProvID" = arpb.SERV_PROVIDER_ID    
                OR fin."LinkedProvID" = arpb.BILLING_PROV_ID 
                OR fin."LinkedProvID" = arpb.SERV_PROVIDER_ID)
        LEFT OUTER JOIN CLARITY_EAP eap ON arpb.PROC_ID = eap.PROC_ID
        LEFT OUTER JOIN CLARITY_DEP dep ON arpb.DEPARTMENT_ID = dep.DEPARTMENT_ID
    WHERE 
--        fin."Note Service Date">= '01-APR-2018'
        fin."Note Service Date">= EPIC_UTIL.EFN_DIN('t-42')
        AND fin."Note Service Date"<= EPIC_UTIL.EFN_DIN('t-14')
--        fin."Note Service Date">= EPIC_UTIL.EFN_DIN('{?StartDate}')
--        AND fin."Note Service Date"<= EPIC_UTIL.EFN_DIN('{?EndDate}')


)

--
-- Search CLARITY_UCL for charges on the record.
--

, RECORD_CHARGE
AS
(
SELECT DISTINCT
    "NoteID"
    , PAT_NAME "PatName"
    , PAT_MRN_ID "PatMrnID"
    , "HospAdmTime"
    , "NoteType"
--    , "Note Status Code"
    , "Note Status Name"
--    , "Unsigned Y/N"
    , "Note Service Date"
    , "Note Signed Date"
    , "AuthProvName"
    , "AuthProvType"
    , "Service"
--    , RECORD_NAME
--    , "Entry Name"
--    , "Entry Date"
    , "Billing Location"
    , "BasePatClass"
    , "Billing Department"
    , "Charge Service Date"
    , "Charge File Date"
    , "ProcedureName txn"
    , "ProcName ucl"
    , CASE 
        WHEN UCL_ITEMS > 0 
        THEN 'Y' ELSE 'N' 
    END "UCL_YN"
FROM
	(
	SELECT 
	    txn.*
        , eap.PROC_ID "ProcID ucl"
        , eap.PROC_NAME "ProcName ucl"
        , ucl.EPT_CSN "EPT CSN"
        , bar.RECORD_NAME
	    , SUM(
	        CASE 
                WHEN ucl.UCL_ID IS NOT NULL 
                THEN 1 ELSE 0 
	        END) UCL_ITEMS
	FROM MISSING_TXNS txn
	    LEFT OUTER JOIN CLARITY_UCL ucl ON txn."PatEncCsnID" = ucl.EPT_CSN
	        AND (TRUNC(txn."Note Service Date") = ucl.SERVICE_DATE_DT 
	            OR Case 
	                WHEN txn."NoteType" = 'Discharge Summaries' 
	                THEN TRUNC(txn."HospDisTime")
                END = ucl.SERVICE_DATE_DT)
            AND (txn."AuthProvID" = ucl.BILLING_PROVIDER_ID   
                OR txn."AuthProvID" = ucl.SERVICE_PROVIDER_ID 
                OR  txn."AuthUserName" = ucl.CREATED_USER_ID
                OR txn."LinkedProvID" = ucl.BILLING_PROVIDER_ID
                OR txn."LinkedProvID" = ucl.SERVICE_PROVIDER_ID)
	        AND ucl.CHG_DESTINATION_C = 8 
        LEFT OUTER JOIN CLARITY_EAP eap ON ucl.PROCEDURE_ID = eap.PROC_ID
        LEFT OUTER JOIN BILL_AREA bar ON ucl.PROV_BILL_AREA_C = bar.BILL_AREA_ID
	GROUP BY 
	PAT_NAME
	, PAT_MRN_ID
	, "Note Service Date"
	, "Note Signed Date"
    , "TxID txn"
    , "CPTCode txn"
    , "ProcedureName txn"
    , "NoteID"
    , "PatEncCsnID"
    , "HspAcctID"
    , "PatClass"  
    , "BasePatClass"
    , PAT_ID
    , "Billing Location"
    , "Parent Location"
    , "HospAdmTime"
    , "InpAdmTime"
    , "HospDisTime"
    , "NoteType"
--    , "Note Status Code"
    , "Note Status Name"
--    , "Unsigned Y/N"
    , "AuthProvID"
    , "AuthUserName"
    , "AuthProvName"
    , "AuthProvType"
    , "Service"
--    , "Entry Name"
--    , "Entry Date"
    , "LinkedProvID"
    , "LinkedProvName"
    , "LinkedProvType"
    , eap.PROC_ID
    , eap.PROC_NAME
    , ucl.EPT_CSN
    , bar.RECORD_NAME
    , "NoteID"
    , "Billing Department"
    , "Charge Service Date"
    , "Charge File Date"
    , "Service txn"
    , "Department txn"
	) 
ORDER BY 
    PAT_NAME
--    , "PatEncCsnID"
    , "Note Service Date"
)




--
-- Set a flag (1 or 0) for records with a charge
--

, CHARGE_FLAG
AS
(
SELECT 
    rcg.*
  , CASE
        WHEN (rcg."ProcedureName txn" IS NOT NULL
            OR rcg."ProcName ucl" IS NOT NULL)
        THEN 1
        ELSE 0
    END AS "ChargeFlag"
FROM RECORD_CHARGE rcg
)

, SUM_FLAG
AS

--
-- Sum the flags for each Note Service Date, for each patient.  When SumFlag = 0, this note had no charge AND there was no other hospitalist charge for the same date.
-- SumFlag can grow large due to duplicate records from many-to-many joins.
--

(
SELECT *
FROM
    (SELECT
        cfg.*
        , SUM(cfg."ChargeFlag") OVER ( PARTITION BY cfg."PatMrnID", TRUNC(cfg."Note Service Date") ORDER BY cfg."PatMrnID", TRUNC(cfg."Note Service Date")
            , cfg."ChargeFlag" DESC) "SumFlag"
    FROM CHARGE_FLAG cfg
    ORDER BY
    cfg."PatMrnID"
    , cfg."Note Service Date"DESC
    )
)

--
-- Return only records where SumFlag = 0 (Notes without charges).
--

SELECT
    "NoteID"
    , "PatMrnID"
    , "HospAdmTime"
    , "NoteType"
--    , "Note Status Code"
--    , "Note Status Name"
--    , "Unsigned Y/N"
    , "Note Service Date"
    , "Note Signed Date"
    , "Charge Service Date"
    , "Charge File Date"
    , "Service"
--    , RECORD_NAME
    , "AuthProvName"
    , "AuthProvType"
--    , "Entry Name"
--    , "Entry Date"
    , "Billing Location"
    , "Billing Department"
    , "BasePatClass"
FROM SUM_FLAG sfl
WHERE sfl."SumFlag" = 0
