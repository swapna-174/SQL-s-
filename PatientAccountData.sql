/*
USE VSE-PRD-CLR1\CLARITY_PRD/Clarity_PRD

*****McKesson Account Patient Data Extract*****
Account Patient Data
 Patient Data: The patient data files should contain one complete patient info record per patient number and cycle number
 (if the patient accounting system is cyclical) that falls within the criteria of selection.*

 *******This Script is just a guide to help. 
 *******Code changes may be required to yield correct results based on your Table Structures

File Name:  PatientAccountDataYYYYMMDD.txt

Criteria / Frequency:
 Historical 	All accounts that have an admit date from 365 days back to present
 Weekly			All accounts that have an admit date from 365 days back to present
*/

--/* ------------------------------------- DATE --------------------------------------------------
-- Sets Date Options *** Comment out the appropriate date range in the Where Clause at bottom ***
DECLARE @Today DATE = GETDATE()
       ,@AccountTimeRange INT = 365; --This can be modified to 21 days for sample file

DECLARE @StartDateAccounts DATE = DATEADD(DAY, -@AccountTimeRange, @Today)
       ,@EndDateAccounts DATE = DATEADD(DAY, -2, @Today)
--,@WeeklyRange DATETIME = DATEADD(DAY, -21, @Today)

----SELECT @Today AS Today
----,@StartDateAccounts AS SDHistorical
----,@EndDateAccounts AS EDHistorical
--------------------------------------- END DATE ------------------------------------------------*/

--==================================== Begin INSUR_PMTS CTE ============================================--
;
WITH cteAccountsNumbers(HSP_ACCOUNT_ID, LOC_ID)
  AS (SELECT har.HSP_ACCOUNT_ID
            ,har.LOC_ID
      FROM HSP_ACCOUNT AS har
      LEFT OUTER JOIN VALID_PATIENT AS valept
                      ON har.PAT_ID = valept.PAT_ID
      WHERE CAST(har.ADM_DATE_TIME AS DATE) BETWEEN @StartDateAccounts AND @EndDateAccounts
            AND valept.IS_VALID_PAT_YN = 'y' -- Removes Test Patients
            AND har.LOC_ID IN ('123456789') --  Predetermined Facilities ***** GENERIC Value, ALTER based on requirements
            AND har.RESEARCH_ID IS NULL --Excludes Research HAR's
            AND har.ACCT_BILLSTS_HA_C NOT IN ('3', '20', '40', '99') --3 = Discharged/Not Billed,20 = Bad Debt 40 = Voided, 99 =  Combined
)
    ,cteINSUR_PMTS
  AS (SELECT har.HSP_ACCOUNT_ID
            ,SUM(ipb.PAYMENT_TOTAL) AS "TotalInsurancePayments"
      FROM cteAccountsNumbers AS har
      LEFT OUTER JOIN HSP_bucket AS ipb
                      ON har.HSP_ACCOUNT_ID = ipb.HSP_ACCOUNT_ID
      WHERE ipb.BKT_TYPE_HA_C IN (2, 6, 3, 7) --2 - Primary Claim 3 - Secondary Claim 6 - Interim Primary Claim 7 - Interim Secondary Claim 
            AND ipb.BKT_STS_HA_C NOT IN (8, 6) --not in 8 - Rejected 6 - Error
      GROUP BY har.HSP_ACCOUNT_ID)
    --======================================= End INSUR_PMTS CTE ===========================================--

    --====================================== Begin PATIENT_PMTS CTE ========================================--
    ,ctePATIENT_PMTS
  AS (SELECT har.HSP_ACCOUNT_ID
            ,SUM(ppb.PAYMENT_TOTAL) AS "TotalPatientPayments"
      FROM cteAccountsNumbers AS har
      LEFT OUTER JOIN HSP_bucket AS ppb
                      ON har.HSP_ACCOUNT_ID = ppb.HSP_ACCOUNT_ID
      WHERE ppb.BKT_TYPE_HA_C = '4' --4 - Self-Pay
            AND ppb.BKT_STS_HA_C NOT IN (8, 6) --not in 8 - Rejected 6 - Error
      GROUP BY har.HSP_ACCOUNT_ID)
--======================================= End PATIENT_PMTS CTE =========================================--


SELECT CAST(har.HSP_ACCOUNT_ID AS VARCHAR(50)) AS PatientNumber         -- CANNOT Be NULL
      ,CAST(har.PATIENT_MRN AS VARCHAR(50)) AS MedicalRecordNumber      -- CANNOT Be NULL  Prior to Aug 2020 Epic
      ,CAST(hapm.PAT_MRN AS VARCHAR(50)) AS MedicalRecordNumber         -- CANNOT Be NULL  *****Use if HSP_ACCOUNT.PATIENT_MRN is Depricated Aug 2020 or new 
      ,CAST(ISNULL(har.PATIENT_MRN, hapm.PAT_MRN) AS VARCHAR(50)) AS MedicalRecordNumber --Potential New Code for both processes
      ,NULL AS CycleNumber
      ,RTRIM(CONVERT(VARCHAR(23), har.ADM_DATE_TIME, 121)) AS AdmitDate -- CANNOT Be NULL
      ,ISNULL(RTRIM(CONVERT(VARCHAR(23), har.DISCH_DATE_TIME, 121)), '') AS DischargeDate
      ,ISNULL(CAST(bscls.NAME AS VARCHAR(50)), '') AS MajorPatientType  --Inpatient or Outpatient
      ,ISNULL(CAST(REPLACE(blsts.NAME, '/', ', ') AS VARCHAR(50)), '') AS AccountType
      ,ISNULL(CAST(admtyp.NAME AS VARCHAR(50)), '') AS AdmissionType
      ,ISNULL(RTRIM(CAST(admsrc.NAME AS VARCHAR(100))), '') AS AdmissionSource
      ,ISNULL(CAST(svc.NAME AS VARCHAR(50)), '') AS HospitalServiceTypeCode
      ,ISNULL(CAST(loc.LOC_NAME AS VARCHAR(50)), '') AS ServiceLocationCode
      ,ISNULL(CAST(attser.PROV_ID AS VARCHAR(50)), '') AS AttendingPhysicianCode
      ,ISNULL(CAST(attser.PROV_NAME AS VARCHAR(50)), '') AS AttendingPhysicianName
      ,ISNULL(CAST(ept.PAT_FIRST_NAME AS VARCHAR(100)), '') AS PatientFirstName
      ,ISNULL(CAST(LEFT(ept.PAT_MIDDLE_NAME, 1) AS VARCHAR(50)), '') AS PatientMiddleInitial
      ,ISNULL(CAST(ept.PAT_LAST_NAME AS VARCHAR(100)), '') AS PatientLastName
      ,ISNULL(CAST(ept.ADD_LINE_1 AS VARCHAR(150)), '') AS PatientAddress1
      ,ISNULL(CAST(ept.ADD_LINE_2 AS VARCHAR(150)), '') AS PatientAddress2
      ,ISNULL(CAST(ept.CITY AS VARCHAR(50)), '') AS PatientCity
      ,ISNULL(CAST(ZC_STATE_PAT.NAME AS VARCHAR(50)), '') AS PatientState
      ,ISNULL(CAST(ept.ZIP AS VARCHAR(50)), '') AS PatientZip
      ,ISNULL(CAST(ept.HOME_PHONE AS VARCHAR(50)), '') AS PatientHomePhone
      ,ISNULL(CAST(ept.SSN AS VARCHAR(50)), '') AS PatientSSN
      ,ISNULL(RTRIM(CONVERT(VARCHAR(10), ept.BIRTH_DATE, 23)), '') AS PatientDOB
      ,ISNULL(CAST(ZC_SEX.ABBR AS VARCHAR(50)), '') AS PatientSex
      ,ISNULL(CAST(edgadm1.REF_BILL_CODE AS VARCHAR(100)), '') AS PrimaryDiagnosisCode
      ,ISNULL(CAST(edgadm2.REF_BILL_CODE AS VARCHAR(50)), '') AS SecondaryDiagnosisCode
      ,ISNULL(CAST(edgfin.REF_BILL_CODE AS VARCHAR(100)), '') AS DischargeDiagnosisCode
      ,ISNULL(CAST(drgcode.MPI_ID AS VARCHAR(50)), '') AS DRG
      ,CAST(har.LOC_ID AS VARCHAR(50)) AS FacilityIdentifier            -- CANNOT Be NULL
      ,ISNULL(CAST(loc.LOC_NAME AS VARCHAR(50)), '') FacilityName
      ,'EPIC' AS AccountingSystem                                       --(ADD Name of Patient Account System here example EPIC)
      ,ISNULL(CAST(har.ACCT_FIN_CLASS_C AS VARCHAR(50)), '') AS CurrentFinancialClassCode
      ,ISNULL(CAST(fc.name AS VARCHAR(100)), '') AS CurrentFinancialClassName
      ,ISNULL(CAST(epm1.PAYOR_ID AS VARCHAR(50)), '') AS Insurance1Code --
      ,ISNULL(CAST(epm1.PAYOR_NAME AS VARCHAR(150)), '') AS Insurance1Name
      ,ISNULL(CAST(epm2.PAYOR_ID AS VARCHAR(50)), '') AS Insurance2Code
      ,ISNULL(CAST(epm2.PAYOR_NAME AS VARCHAR(150)), '') AS Insurance2Name
      ,ISNULL(CAST(cvg1.SUBSCR_NUM AS VARCHAR(50)), '') AS Insurance1PolicyNumber
      ,ISNULL(ROUND(CAST(har.TOT_CHGS AS DECIMAL(18, 2)), 2), 0.00) AS TotalCharges
      ,ISNULL(ROUND(CAST(INSUR_PMTS.TotalInsurancePayments AS DECIMAL(18, 2)), 2), 0.00) AS TotalInsurancePayments
      ,ISNULL(ROUND(CAST(PATIENT_PMTS.TotalPatientPayments AS DECIMAL(18, 2)), 2), 0.00) AS TotalPatientPayments
      ,ISNULL(ROUND(CAST(har.TOT_ADJ AS DECIMAL(18, 2)), 2), 0.00) AS TotalAdjustments
      ,ISNULL(ROUND(CAST(har.TOT_ACCT_BAL AS DECIMAL(18, 2)), 2), 0.00) AS AccountBalance
FROM HSP_ACCOUNT AS har
JOIN cteAccountsNumbers
     ON cteAccountsNumbers.HSP_ACCOUNT_ID = har.HSP_ACCOUNT_ID
LEFT OUTER JOIN ZC_ACCT_CLASS_HA AS cls
                ON har.ACCT_CLASS_HA_C = cls.ACCT_CLASS_HA_C
LEFT OUTER JOIN ZC_ACCT_BASECLS_HA AS bscls
                ON har.ACCT_BASECLS_HA_C = bscls.ACCT_BASECLS_HA_C
LEFT OUTER JOIN ZC_ACCT_BILLSTS_HA AS blsts
                ON har.ACCT_BILLSTS_HA_C = blsts.ACCT_BILLSTS_HA_C
LEFT OUTER JOIN HSP_ACCOUNT_3 AS har3
                ON har.HSP_ACCOUNT_ID = har3.HSP_ACCOUNT_ID
LEFT OUTER JOIN ZC_HOSP_ADMSN_TYPE AS admtyp
                ON har3.ADMIT_TYPE_EPT_C = admtyp.HOSP_ADMSN_TYPE_C
LEFT OUTER JOIN ZC_MC_ADM_SOURCE AS admsrc
                ON har.ADMISSION_SOURCE_C = admsrc.ADMISSION_SOURCE_C
LEFT OUTER JOIN ZC_PRIM_SVC_HA AS svc
                ON har.PRIM_SVC_HA_C = svc.PRIM_SVC_HA_C
LEFT OUTER JOIN CLARITY_LOC AS loc
                ON har.LOC_ID = loc.LOC_ID
LEFT OUTER JOIN CLARITY_SER AS attser
                ON har.ATTENDING_PROV_ID = attser.PROV_ID
LEFT OUTER JOIN PATIENT AS ept
                ON har.PAT_ID = ept.PAT_ID
LEFT OUTER JOIN ZC_STATE AS ZC_STATE_PAT
                ON ZC_STATE_PAT.STATE_C = ept.STATE_C
LEFT OUTER JOIN ZC_COUNTRY AS ctry
                ON ept.COUNTRY_C = ctry.COUNTRY_C
LEFT OUTER JOIN ZC_SEX
                ON ept.SEX_C = ZC_SEX.RCPT_MEM_SEX_C
LEFT OUTER JOIN HSP_ACCT_ADMIT_DX AS admdx1 --Primary Admitting Diagnosis 
                ON har.HSP_ACCOUNT_ID = admdx1.HSP_ACCOUNT_ID
                   AND admdx1.LINE = '1'
LEFT OUTER JOIN CLARITY_EDG AS edgadm1
                ON admdx1.ADMIT_DX_ID = edgadm1.DX_ID
LEFT OUTER JOIN HSP_ACCT_ADMIT_DX AS admdx2 --Secondary Admitting Diagnosis
                ON har.HSP_ACCOUNT_ID = admdx2.HSP_ACCOUNT_ID
                   AND admdx2.LINE = '2'
LEFT OUTER JOIN CLARITY_EDG AS edgadm2
                ON admdx2.ADMIT_DX_ID = edgadm2.DX_ID
LEFT OUTER JOIN HSP_ACCT_DX_LIST AS findx --Final coded Diagnosis
                ON har.HSP_ACCOUNT_ID = findx.HSP_ACCOUNT_ID
                   AND findx.LINE = '1' --Line = 1 is the Primary diagnosis
LEFT OUTER JOIN CLARITY_EDG AS edgfin
                ON findx.DX_ID = edgfin.DX_ID
LEFT OUTER JOIN VALID_PATIENT AS valept
                ON har.PAT_ID = valept.PAT_ID
LEFT OUTER JOIN IDENTITY_ID_TYPE AS idtype --this code is to pull in just the Billing DRG Code
                ON har.BILL_DRG_IDTYPE_ID = idtype.ID_TYPE
LEFT OUTER JOIN CLARITY_DRG AS drgname
                ON har.FINAL_DRG_ID = drgname.DRG_ID
LEFT OUTER JOIN CLARITY_DRG_MPI_ID AS drgcode
                ON(har.FINAL_DRG_ID = drgcode.DRG_ID
                   AND har.BILL_DRG_IDTYPE_ID = drgcode.MPI_ID_TYPE)
LEFT OUTER JOIN ZC_FIN_CLASS AS fc
                ON har.ACCT_FIN_CLASS_C = fc.FIN_CLASS_c
LEFT OUTER JOIN HSP_ACCT_CVG_LIST AS list1
                ON har.HSP_ACCOUNT_ID = list1.HSP_ACCOUNT_ID
                   AND list1.line = '1' --Primary Coverage on HAR
LEFT OUTER JOIN COVERAGE AS cvg1
                ON list1.COVERAGE_ID = cvg1.COVERAGE_ID
LEFT OUTER JOIN CLARITY_EPM AS epm1
                ON cvg1.PAYOR_ID = epm1.PAYOR_ID
LEFT OUTER JOIN HSP_ACCT_CVG_LIST AS list2
                ON har.HSP_ACCOUNT_ID = list2.HSP_ACCOUNT_ID
                   AND list2.line = '2' --Secondary Coverage on HAR
LEFT OUTER JOIN COVERAGE AS cvg2
                ON list2.COVERAGE_ID = cvg2.COVERAGE_ID
LEFT OUTER JOIN CLARITY_EPM AS epm2
                ON cvg2.PAYOR_ID = epm2.PAYOR_ID
LEFT OUTER JOIN cteINSUR_PMTS
                ON har.HSP_ACCOUNT_ID = INSUR_PMTS.HSP_ACCOUNT_ID
LEFT OUTER JOIN ctePATIENT_PMTS
                ON har.HSP_ACCOUNT_ID = PATIENT_PMTS.HSP_ACCOUNT_ID
LEFT OUTER JOIN VALID_PATIENT AS val
                ON har.PAT_ID = val.PAT_ID
LEFT OUTER JOIN HSP_ACCT_PAT_MRN AS hapm --Use if Epic release is August 2020 or newer
                ON har.PAT_ID = hapm.PAT_ID;
