WITH NOTES
AS
(
SELECT DISTINCT
        info.NOTE_ID "NoteID"
        , info.INPATIENT_DATA_ID
        , enc_info.AUTHOR_USER_ID "AuthUserName"
        , ser2.PROV_ID "AuthProvID"
        , ser2.PROV_NAME "AuthProvName"
        , ser2.PROV_TYPE "AuthProvType"
        , zc_serv2.NAME "Service"
        , zc_note.NAME "NoteType"
        , zc_ns.NAME "Note Status Name"
       , EPIC_UTIL.EFN_UTC_TO_LOCAL(info.DATE_OF_SERVIC_DTTM) "Note Service Date"
       , EPIC_UTIL.EFN_UTC_TO_LOCAL(enc_info.UPD_AUTHOR_INS_DTTM) "Note Signed Date"
       , info.PAT_ENC_CSN_ID "PatEncCsnID"
       , info.Pat_ID "PatID"
       , pat.PAT_MRN_ID "MRN"
        FROM HNO_INFO info
        INNER JOIN ZC_NOTE_TYPE_IP zc_note ON info.IP_NOTE_TYPE_C = zc_note.TYPE_IP_C
        LEFT OUTER JOIN NOTE_ENC_INFO enc_info ON info.NOTE_ID = enc_info.NOTE_ID
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
--            AND EPIC_UTIL.EFN_UTC_TO_LOCAL(info.DATE_OF_SERVIC_DTTM) >= EPIC_UTIL.EFN_DIN('t-70')
--            AND EPIC_UTIL.EFN_UTC_TO_LOCAL(info.DATE_OF_SERVIC_DTTM) <= EPIC_UTIL.EFN_DIN('t-7')
--            AND EPIC_UTIL.EFN_UTC_TO_LOCAL(info.DATE_OF_SERVIC_DTTM) > '13-FEB-2019'
--            AND EPIC_UTIL.EFN_UTC_TO_LOCAL(info.DATE_OF_SERVIC_DTTM) < '14-AUG-2019'
            AND EPIC_UTIL.EFN_UTC_TO_LOCAL(info.DATE_OF_SERVIC_DTTM) > '13-AUG-2019'
            AND EPIC_UTIL.EFN_UTC_TO_LOCAL(info.DATE_OF_SERVIC_DTTM) < '15-FEB-2020'
            AND ser2.PROV_ID <> 'E999101'
            AND enc_info.NOTE_STATUS_C = 2  -- 2=Signed
            AND info.PAT_ENC_CSN_ID IN ('30115136343', '30115303632')
--            AND info.DATE_OF_SERVIC_DTTM >= EPIC_UTIL.EFN_DIN('{?StartDate}')
--            AND info.DATE_OF_SERVIC_DTTM <= EPIC_UTIL.EFN_DIN('{?EndDate}')
)

--
-- Join Notes to their PB transactions
--

--, MISSING_TXNS
--AS
--(
    SELECT DISTINCT
        fin."NoteID"
        , fin."PatEncCsnID"
        , enc.HSP_ACCOUNT_ID "HAR"
        , zc_bc.NAME "Base Class"
        , zc_pc.NAME "Patient Class"
        , enc.ENC_TYPE_C "Encounter Type"
        , zc_et.NAME "Encounter Name"
        , dep2.DEPARTMENT_NAME "Adm Department"
        , dep.DEPARTMENT_NAME "Disch Department"
        , par.LOC_NAME "Parent Location"
        , fin."NoteType" "Note Type"
        , fin."Note Status Name"
        , fin."Note Service Date"
        , fin."Note Signed Date"
        , fin."AuthProvID" "Provider ID"
--        , fin."AuthUserName"
        , fin."AuthProvName" "Provider Name"
        , fin."AuthProvType" "Provider Type"
        , fin."Service" "Provider Service"
        , zc_ps.NAME "HAR Primary Service"
--        , fin."Entry Name"
--        , fin."Entry Date"
--        , fin."LinkedProvID"
--        , fin."LinkedProvName"
--        , fin."LinkedProvType"
--        , arpb.TX_ID "TxID txn"
--        , arpb.DEPARTMENT_ID "Department txn"
--        , dep.DEPARTMENT_NAME "Billing Department"
--        , arpb.SERVICE_AREA_ID "Service txn"
--        , arpb.CPT_CODE "CPTCode txn"
--        , arpb.SERVICE_DATE "Charge Service Date"
--        , arpb.POST_DATE "Charge File Date"
--        , eap.PROC_NAME "ProcedureName txn"
    FROM NOTES fin
        LEFT JOIN ARPB_TRANSACTIONS arpb ON fin."PatEncCsnID" = arpb.PAT_ENC_CSN_ID
            AND arpb.TX_TYPE_C = '1'
            AND TRUNC(fin."Note Service Date") = arpb.SERVICE_DATE
            AND (fin."AuthProvID" = arpb.BILLING_PROV_ID 
                OR fin."AuthProvID" = arpb.SERV_PROVIDER_ID)    
--                OR fin."LinkedProvID" = arpb.BILLING_PROV_ID 
--                OR fin."LinkedProvID" = arpb.SERV_PROVIDER_ID)
        LEFT OUTER JOIN CLARITY_EAP eap ON arpb.PROC_ID = eap.PROC_ID
--        LEFT OUTER JOIN CLARITY_DEP dep ON arpb.DEPARTMENT_ID = dep.DEPARTMENT_ID
--        LEFT OUTER JOIN CLARITY_LOC loc ON dep.REV_LOC_ID = loc.LOC_ID
--        LEFT OUTER JOIN CLARITY_LOC par ON loc.HOSP_PARENT_LOC_ID = par.LOC_ID
        LEFT OUTER JOIN PAT_ENC enc ON fin."PatEncCsnID" = enc.PAT_ENC_CSN_ID
        LEFT OUTER JOIN HSP_ACCOUNT hsp ON enc.HSP_ACCOUNT_ID = hsp.HSP_ACCOUNT_ID
        LEFT OUTER JOIN ZC_ACCT_BASECLS_HA zc_bc ON hsp.ACCT_BASECLS_HA_C = zc_bc.ACCT_BASECLS_HA_C
        LEFT OUTER JOIN ZC_DISP_ENC_TYPE zc_et ON enc.ENC_TYPE_C = zc_et.DISP_ENC_TYPE_C
        LEFT OUTER JOIN ZC_PRIM_SVC_HA zc_ps ON hsp.PRIM_SVC_HA_C = zc_ps.PRIM_SVC_HA_C
        LEFT OUTER JOIN ZC_PAT_CLASS zc_pc ON hsp.ACCT_CLASS_HA_C = zc_pc.ADT_PAT_CLASS_C
        LEFT OUTER JOIN CLARITY_DEP dep ON hsp.DISCH_DEPT_ID = dep.DEPARTMENT_ID
        LEFT OUTER JOIN CLARITY_LOC loc ON dep.REV_LOC_ID = loc.LOC_ID
        LEFT OUTER JOIN CLARITY_LOC par ON loc.HOSP_PARENT_LOC_ID = par.LOC_ID
        LEFT OUTER JOIN CLARITY_ADT adt ON  hsp.PRIM_ENC_CSN_ID = adt.PAT_ENC_CSN_ID
            AND adt.EVENT_TYPE_C=1
        LEFT OUTER JOIN CLARITY_DEP dep2 ON adt.DEPARTMENT_ID = dep2.DEPARTMENT_ID
        LEFT OUTER JOIN CLARITY_LOC loc2 ON dep2.REV_LOC_ID = loc2.LOC_ID
        LEFT OUTER JOIN CLARITY_LOC par2 ON loc2.HOSP_PARENT_LOC_ID = par2.LOC_ID
    WHERE 
--        fin."Note Service Date">= '01-APR-2018'
--        fin."Note Service Date">= EPIC_UTIL.EFN_DIN('t-70')
--        AND fin."Note Service Date"<= EPIC_UTIL.EFN_DIN('t-7')
--        fin."Note Service Date" > '13-FEB-2019'
--        AND fin."Note Service Date" < '14-AUG-2019'
        fin."Note Service Date" > '13-AUG-2019'
        AND fin."Note Service Date" < '15-FEB-2020'
        AND hsp.ACCT_BASECLS_HA_C IN (1,2)
        AND enc.ENC_TYPE_C <> '2507'
        AND arpb.CPT_CODE IS NULL
--        fin."Note Service Date">= EPIC_UTIL.EFN_DIN('{?StartDate}')
--        AND fin."Note Service Date"<= EPIC_UTIL.EFN_DIN('{?EndDate}')


--)
