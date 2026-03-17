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
        , info.INPATIENT_DATA_ID
        , enc_info.AUTHOR_USER_ID "AuthUserName"
--        , info.CURRENT_AUTHOR_ID
--        , emp.USER_NAME_EXT
--        , ser.PROV_ID "AuthProvID"
--        , ser.PROV_NAME "AuthProvName"
--        , ser.PROV_TYPE "AuthProvType"
        , ser2.PROV_ID "AuthProvID"
        , ser2.PROV_NAME "AuthProvName"
        , ser2.PROV_TYPE "AuthProvType"
--        , emp3.NAME "Entry Name"
--        , info.ENTRY_DATETIME "Entry Date"
        , zc_serv2.NAME "Service"
--        , ser2.PROV_ID "LinkedProvID"
--        , ser2.PROV_NAME "LinkedProvName"
--        , ser2.PROV_TYPE "LinkedProvType"
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
--        LEFT OUTER JOIN CLARITY_EMP emp ON info.CURRENT_AUTHOR_ID = emp.USER_ID
--        LEFT OUTER JOIN CLARITY_EMP emp3 ON info.ENTRY_USER_ID = emp3.USER_ID
--        LEFT OUTER JOIN CLARITY_SER ser ON emp.PROV_ID = ser.PROV_ID        
--        LEFT OUTER JOIN CLARITY_SER_SPEC spec ON ser.PROV_ID = spec.PROV_ID
--        LEFT OUTER JOIN ZC_SPECIALTY zc_spec ON spec.SPECIALTY_C = zc_spec.SPECIALTY_C
--        LEFT OUTER JOIN CLARITY_DEP dep ON emp.LGIN_DEPARTMENT_ID = dep.DEPARTMENT_ID
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
            AND EPIC_UTIL.EFN_UTC_TO_LOCAL(info.DATE_OF_SERVIC_DTTM) >= EPIC_UTIL.EFN_DIN('t-70')
            AND EPIC_UTIL.EFN_UTC_TO_LOCAL(info.DATE_OF_SERVIC_DTTM) <= EPIC_UTIL.EFN_DIN('t-7')
            AND ser2.PROV_ID <> 'E999101'
            AND enc_info.NOTE_STATUS_C = 2  -- 2=Signed
--            AND info.DATE_OF_SERVIC_DTTM >= EPIC_UTIL.EFN_DIN('{?StartDate}')
--            AND info.DATE_OF_SERVIC_DTTM <= EPIC_UTIL.EFN_DIN('{?EndDate}')
)

--
-- Join Notes and Discharges to their PB transactions
--

--, MISSING_TXNS
--AS
--(
    SELECT 
        fin."NoteID"
        , fin."PatEncCsnID"
        , enc.HSP_ACCOUNT_ID "HAR"
        , enc.ENC_TYPE_C
        , zc_et.NAME "Encounter Type"
--        , dis."HspAcctID"
--        , dis."PatClass"
--        , dis."BasePatClass"
        , loc.LOC_NAME "Billing Location"
        , par.LOC_NAME "Parent Location"
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
--        , fin."LinkedProvID"
--        , fin."LinkedProvName"
--        , fin."LinkedProvType"
        , arpb.TX_ID "TxID txn"
        , arpb.DEPARTMENT_ID "Department txn"
        , dep.DEPARTMENT_NAME "Billing Department"
        , arpb.SERVICE_AREA_ID "Service txn"
        , arpb.CPT_CODE "CPTCode txn"
        , arpb.SERVICE_DATE "Charge Service Date"
        , arpb.POST_DATE "Charge File Date"
        , eap.PROC_NAME "ProcedureName txn"
    FROM NOTES fin
        LEFT JOIN ARPB_TRANSACTIONS arpb ON fin."PatEncCsnID" = arpb.PAT_ENC_CSN_ID
            AND arpb.TX_TYPE_C = '1'
            AND TRUNC(fin."Note Service Date") = arpb.SERVICE_DATE
            AND (fin."AuthProvID" = arpb.BILLING_PROV_ID 
                OR fin."AuthProvID" = arpb.SERV_PROVIDER_ID)    
--                OR fin."LinkedProvID" = arpb.BILLING_PROV_ID 
--                OR fin."LinkedProvID" = arpb.SERV_PROVIDER_ID)
        LEFT OUTER JOIN CLARITY_EAP eap ON arpb.PROC_ID = eap.PROC_ID
        LEFT OUTER JOIN CLARITY_DEP dep ON arpb.DEPARTMENT_ID = dep.DEPARTMENT_ID
        LEFT OUTER JOIN CLARITY_LOC loc ON dep.REV_LOC_ID = loc.LOC_ID
        LEFT OUTER JOIN CLARITY_LOC par ON loc.HOSP_PARENT_LOC_ID = par.LOC_ID
        LEFT OUTER JOIN PAT_ENC enc ON fin."PatEncCsnID" = enc.PAT_ENC_CSN_ID
        LEFT OUTER JOIN HSP_ACCOUNT hsp ON enc.HSP_ACCOUNT_ID = hsp.HSP_ACCOUNT_ID
        LEFT OUTER JOIN ZC_DISP_ENC_TYPE zc_et ON enc.ENC_TYPE_C = zc_et.DISP_ENC_TYPE_C
    WHERE 
--        fin."Note Service Date">= '01-APR-2018'
        fin."Note Service Date">= EPIC_UTIL.EFN_DIN('t-70')
        AND fin."Note Service Date"<= EPIC_UTIL.EFN_DIN('t-7')
        AND hsp.ACCT_BASECLS_HA_C IN (1,2)
        AND enc.ENC_TYPE_C <> '2507'
--        fin."Note Service Date">= EPIC_UTIL.EFN_DIN('{?StartDate}')
--        AND fin."Note Service Date"<= EPIC_UTIL.EFN_DIN('{?EndDate}')


--)
