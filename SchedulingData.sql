/*
USE VSE-PRD-CLR1\CLARITY_PRD/Clarity_PRD

*****McKesson Scheduling Data Extract*****
File Name:  SchedulingDataYYYYMMDD.txt

*******This Script is just a guide to help. Code changes may be required to yield correct results based on your Table Structures******

Criteria / Frequency:
Daily FileCreation date +1 day to 21 days in the future
*/

--/* ------------------------------------- DATE --------------------------------------------------
-- Sets Date Options *** Comment out the appropriate date range in the Where Clause at bottom ***
SET ANSI_WARNINGS OFF;
SET NOCOUNT ON;

DECLARE @StartDate DATE = DATEADD(DAY, +1, CAST(GETDATE() AS DATE));
DECLARE @EndDate DATE = DATEADD(DAY, 21, @StartDate);

--------------------------------------- END DATE ------------------------------------------------*/

SELECT DISTINCT MAX(ISNULL(CAST(ept.PAT_MRN_ID AS VARCHAR(50)), '')) AS MedicalRecordNumber
               ,MAX(ISNULL(CAST(ept.PAT_FIRST_NAME AS VARCHAR(100)), '')) AS PatientFirstName
               ,MAX(ISNULL(CAST(LEFT(ept.PAT_MIDDLE_NAME, 1) AS VARCHAR(50)), '')) AS PatientMiddleInitial
               ,MAX(ISNULL(CAST(ept.PAT_LAST_NAME AS VARCHAR(100)), '')) AS PatientLastName
               ,MAX(ISNULL(CAST(REPLACE(ept.ADD_LINE_1,'|','') AS VARCHAR(150)), '')) AS PatientAddress1
               ,MAX(ISNULL(CAST(REPLACE(ept.ADD_LINE_2,'|','') AS VARCHAR(150)), '')) AS PatientAddress2
               ,MAX(ISNULL(CAST(ept.CITY AS VARCHAR(50)), '')) AS PatientCity
               ,MAX(ISNULL(CAST(ZC_STATE_PAT.NAME AS VARCHAR(50)), '')) AS PatientState
               ,MAX(ISNULL(CAST(ept.ZIP AS VARCHAR(50)), '')) AS PatientZip
               ,MAX(ISNULL(CAST(ept.HOME_PHONE AS VARCHAR(50)), '')) AS PatientHomePhone
               ,MAX(ISNULL(CAST(ept.BIRTH_DATE AS DATE), '')) AS PatientDOB
               ,MAX(ISNULL(CAST(ZC_SEX.ABBR AS VARCHAR(50)), '')) AS PatientSex
               ,MAX(ISNULL(CAST(epm1.PAYOR_ID AS VARCHAR(50)), '')) AS Insurance1Code
               ,MAX(ISNULL(CAST(epm1.PAYOR_NAME AS VARCHAR(100)), '')) AS Insurance1Name
               ,MAX(ISNULL(CAST(har.ACCT_FIN_CLASS_C AS VARCHAR(50)), '')) AS CurrentFinancialClassCode
               ,MAX(ISNULL(CAST(fc.name AS VARCHAR(100)), '')) AS CurrentFinancialClassName
               ,MAX(ISNULL(CAST(ref.EXTERNAL_ID_NUM AS VARCHAR(50)), '')) AS ReferralNumber
               ,MAX(ISNULL(CAST(zcrs.NAME AS VARCHAR(50)), '')) AS ReferralStatus
               ,MAX(ISNULL(CAST(vsa.APPT_DTTM AS DATE), '')) AS ServiceDate
               ,MAX(ISNULL(CAST(enc.PAT_ENC_CSN_ID AS VARCHAR(50)), '')) AS VisitNumber
               ,MAX(ISNULL(CAST(vsa.SERV_AREA_ID AS VARCHAR(50)), '')) AS ServiceAreaCode
               ,MAX(ISNULL(CAST(sa.SERV_AREA_NAME AS VARCHAR(100)), '')) AS ServiceAreaDescription
               ,MAX(ISNULL(CAST(edg.current_ICD10_LIST AS VARCHAR(50)), '')) AS DiagnosisCode
               ,MAX(ISNULL(CAST(edg.DX_NAME AS VARCHAR(100)), '')) AS DiagnosisDescription
               ,MAX(ISNULL(CAST(eap.PROC_CODE AS VARCHAR(50)), '')) AS ProcedureCode
               ,MAX(ISNULL(CAST(eap.PROC_NAME AS VARCHAR(100)), '')) AS ProcedureDescription
               ,ISNULL(CAST(vonc.MEDICATION_ID AS VARCHAR(50)), '') AS DrugCode
               ,MAX(ISNULL(CAST(vonc.order_template_description AS VARCHAR(500)), '')) AS DrugDescription
               ,MAX(ISNULL(CAST(medi.DISCRETE_DOSE AS NVARCHAR(50)), '')) AS DrugDosePrescribed
               ,NULL AS PriorAuthorizationStatus -- AS VARCHAR(50)
               ,ISNULL(CAST(zca.NAME AS VARCHAR(50)), '') AS AppointmentStatus
               ,MAX(ISNULL(CAST(vsa.LOC_ID AS VARCHAR(50)), '')) AS FacilityIdentifier
               ,CAST(CURRENT_TIMESTAMP AS DATE) AS FileCreateDate
               ,MAX(ISNULL(CAST(REPLACE(REPLACE(SUBSTRING(rnote.NOTE_TEXT,1,500),'|',''), '"', '') AS VARCHAR(500)), '')) AS Notes
FROM PAT_ENC AS enc
LEFT OUTER JOIN HSP_ACCOUNT AS acc
                ON enc.HSP_ACCOUNT_ID = har.HSP_ACCOUNT_ID
LEFT OUTER JOIN V_SCHED_APPT AS vsa
                ON enc.PAT_ENC_CSN_ID = vsa.PAT_ENC_CSN_ID
LEFT OUTER JOIN V_SCHED_EVENTS AS eve
                ON vsa.PAT_ENC_CSN_ID = eve.PAT_ENC_CSN_ID
LEFT OUTER JOIN CLARITY_LOC AS loc
                ON vsa.LOC_ID = loc.LOC_ID
LEFT OUTER JOIN CLARITY_DEP AS dep
                ON vsa.DEPARTMENT_ID = dep.DEPARTMENT_ID
LEFT OUTER JOIN PATIENT AS ept
                ON enc.PAT_ID = ept.PAT_ID
LEFT OUTER JOIN REFERRAL AS ref
                ON ept.PAT_ID = ref.PAT_ID
LEFT OUTER JOIN ZC_RFL_STATUS AS zcrs
                ON ref.RFL_STATUS_C = zcrs.RFL_STATUS_C
LEFT OUTER JOIN REFERRAL_DX AS refdx
                ON ref.REFERRAL_ID = refdx.REFERRAL_ID
                   AND refdx.LINE = '1'
LEFT OUTER JOIN CLARITY_EDG AS edg
                ON refdx.DX_ID = edg.dx_id
LEFT OUTER JOIN REFERRAL_PX AS refpx
                ON ref.REFERRAL_ID = refpx.REFERRAL_ID
LEFT OUTER JOIN REFERRAL_PX_NOTES AS refpxnote
                ON refpx.REFERRAL_ID = refpxnote.REFERRAL_ID
LEFT OUTER JOIN(SELECT rnote.REFERRAL_ID
                      ,MAX(tex.LINE) AS LINE
                      ,MAX(tex.NOTE_TEXT) AS NOTE_TEXT
                FROM RFL_HX_LINKED_NOTE AS rnote
                LEFT OUTER JOIN HNO_INFO AS ninfo
                                ON rnote.HX_NOTE_ID = ninfo.NOTE_ID
                LEFT OUTER JOIN HNO_NOTE_TEXT AS tex
                                ON ninfo.NOTE_ID = tex.NOTE_ID
                GROUP BY rnote.REFERRAL_ID) AS rnote
               ON ref.REFERRAL_ID = rnote.REFERRAL_ID
LEFT OUTER JOIN CLARITY_EAP AS eap
                ON refpx.PX_ID = eap.PROC_ID
LEFT OUTER JOIN V_ONC_TREATMENT_PLAN_ORDERS AS vonc
                ON ept.PAT_ID = vonc.PAT_ID
LEFT OUTER JOIN(SELECT med.ORDER_MED_ID
                      ,med.DISCRETE_DOSE
                      ,med2.DESCRIPTION
                FROM V_RX_ORDER AS med
                LEFT OUTER JOIN ORDER_MED AS med2
                                ON med.ORDER_MED_ID = med2.ORDER_MED_ID
                GROUP BY med.ORDER_MED_ID
                        ,med.DISCRETE_DOSE
                        ,med2.DESCRIPTION) AS medi
               ON vonc.ORDER_ID = medi.ORDER_MED_ID
LEFT OUTER JOIN CLARITY_MEDICATION AS cm
                ON vonc.MEDICATION_ID = cm.MEDICATION_ID
LEFT OUTER JOIN ERX_SEC_ORD_GRP AS grp
                ON cm.MEDICATION_ID = grp.MEDICATION_ID
LEFT OUTER JOIN ZC_STATE AS ZC_STATE_PAT
                ON ZC_STATE_PAT.STATE_C = ept.STATE_C
LEFT OUTER JOIN ZC_COUNTRY AS ctry
                ON ept.COUNTRY_C = ctry.COUNTRY_C
LEFT OUTER JOIN ZC_SEX
                ON ept.SEX_C = ZC_SEX.RCPT_MEM_SEX_C
LEFT OUTER JOIN ZC_FIN_CLASS AS fc
                ON har.ACCT_FIN_CLASS_C = fc.FIN_CLASS_c
LEFT OUTER JOIN HSP_ACCT_CVG_LIST AS list1
                ON har.HSP_ACCOUNT_ID = list1.HSP_ACCOUNT_ID
                   AND list1.LINE = '1' --Primary Coverage on HAR
LEFT OUTER JOIN COVERAGE AS cvg1
                ON list1.COVERAGE_ID = cvg1.COVERAGE_ID
LEFT OUTER JOIN CLARITY_EPM AS epm1
                ON cvg1.PAYOR_ID = epm1.PAYOR_ID
LEFT OUTER JOIN VALID_PATIENT AS val
                ON enc.PAT_ID = val.PAT_ID
LEFT OUTER JOIN HSP_TRANSACTIONS AS htr
                ON har.HSP_ACCOUNT_ID = htr.HSP_ACCOUNT_ID
LEFT OUTER JOIN ZC_APPT_STATUS AS zca
                ON vsa.APPT_STATUS_C = zca.APPT_STATUS_C
LEFT OUTER JOIN CLARITY_SA AS sa
                ON vsa.SERV_AREA_ID = sa.SERV_AREA_ID
WHERE CAST(enc.CONTACT_DATE AS DATE) BETWEEN @StartDate AND @EndDate
      AND val.IS_VALID_PAT_YN = 'y' --Patient is valid (not a test patient)
      AND har.RESEARCH_ID IS NULL --Excludes Research HAR's
      AND dep.DEPARTMENT_ID IN ('123456789') -- ****** Generic Values Alter for your system
      AND har.ACCT_BILLSTS_HA_C NOT IN ('40') --40 = Voided
      AND vonc.MEDICATION_ID IS NOT NULL
      AND zca.NAME NOT IN ('Canceled', 'Cancelled') --*/

GROUP BY enc.PAT_ENC_CSN_ID
        ,vonc.MEDICATION_ID
        ,zca.NAME;