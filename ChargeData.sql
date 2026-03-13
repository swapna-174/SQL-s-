/*
USE VSE-PRD-CLR1\CLARITY_PRD/Clarity_PRD

*****McKesson Charge Data Extract*****
Charge Data
Patient Charge Detail: The detail file should contain all charge transactions posted within the applicable time frame.

*******This Script is just a guide to help. 
*******Code changes may be required to yield correct results based on your Table Structures******

File Name:  ChargeDataYYYYMMDD.txt
Criteria / Frequency:
	Historical 	All accounts that have an admit date from 365 days back to present
	Weekly		A weekly file will be required to contain all entries with a posting date within the past 21 days
*/

--/* ------------------------------------- DATE --------------------------------------------------
-- Sets Date Options *** Comment out the appropriate date range in the Where Clause at bottom ***
DECLARE @Today DATE = GETDATE()
       ,@HistoricalTimeRange INT = 365
       ,@WeeklyTimeRange INT = 45 --Use if Files are sent Weekly 45 Days to capture Recurring Patients
       ,@DailyTimeRange INT = 7;  -- Use if Files are sent Daily

---Use for Weekly
DECLARE @StartDateHistorical DATE = DATEADD(DAY, -@HistoricalTimeRange, @Today)
       ,@EndDateHistorical DATE = DATEADD(DAY, -1, @Today)
       ,@StartDatePeriod DATE = DATEADD(DAY, -@WeeklyTimeRange, @Today)
       ,@EndDatePeriod DATE = DATEADD(DAY, -1, @Today)
       ,@StartDateAccounts DATE = DATEADD(DAY, -@HistoricalTimeRange, @Today)
       ,@EndDateAccounts DATE = DATEADD(DAY, -1, @Today)

---Use for Daily
----DECLARE @StartDateHistorical DATETIME2 = DATEADD(DAY, -@HistoricalTimeRange, @Today)
----       ,@EndDateHistorical DATETIME2 = DATEADD(DAY, -1, @Today)
----       ,@StartDatePeriod DATETIME2 = DATEADD(DAY, -@DailyTimeRange, @Today)
----       ,@EndDatePeriod DATETIME2 = DATEADD(DAY, -1, @Today)
----       ,@StartDateAccounts DATETIME2 = DATEADD(DAY, -@HistoricalTimeRange, @Today)
----       ,@EndDateAccounts DATETIME2 = DATEADD(DAY, -1, @Today)

------Testing
----SELECT @Today AS Today
----      ,@StartDateHistorical AS SDHistorical
----      ,@EndDateHistorical AS EDHistorical
----      ,@StartDateWeek AS SDWeek
----      ,@EndDateWeekly AS EDWeek;

--------------------------------------- END DATE ------------------------------------------------*/

;
WITH cteAccountsNumbers(HSP_ACCOUNT_ID, LOC_ID)
  AS (SELECT har.HSP_ACCOUNT_ID
            ,har.LOC_ID
      FROM HSP_ACCOUNT AS har
      LEFT OUTER JOIN VALID_PATIENT AS valept
                      ON har.PAT_ID = valept.PAT_ID
      WHERE CAST(har.ADM_DATE_TIME AS DATE) BETWEEN @StartDateAccounts AND @EndDateAccounts
            AND valept.IS_VALID_PAT_YN = 'y' --Removes Test Patients
            AND har.LOC_ID IN ('123456789') --Predetermined Facilities ***** GENERIC Value, ALTER based on requirements
            AND har.RESEARCH_ID IS NULL --Excludes Research HAR's
            AND har.ACCT_BILLSTS_HA_C NOT IN ('3', '20', '40', '99') --3 = Discharged/Not Billed,20 = Bad Debt 40 = Voided, 99 =  Combined
)
SELECT CAST(htr.HSP_ACCOUNT_ID AS VARCHAR(50)) AS PatientNumber
      ,NULL AS CycleNumber                                   --Unless your sytem uses a Cycle or encounter Number
      ,ISNULL(RTRIM(CONVERT(VARCHAR(23), htr.SERVICE_DATE, 121)), '') AS ServiceDate
      ,ISNULL(RTRIM(CONVERT(VARCHAR(23), htr.TX_POST_DATE, 121)), '') AS PostingDate
      ,CAST(eap.PROC_CODE AS VARCHAR(50)) AS ChargeCode      --NOT NULLABLE column
      ,ISNULL(CAST(htr.PROCEDURE_DESC AS VARCHAR(500)), '') AS ChargeDescription
      ,ISNULL(ROUND(CAST(htr.TX_AMOUNT AS DECIMAL(18, 2)), 2), 0.00) AS Amount
      ,CAST(htr.QUANTITY AS INT) AS Units
      ,ISNULL(CAST(CASE
                     WHEN LEN(htr.CPT_CODE) = 5
                     THEN htr.CPT_CODE
                   ELSE NULL
                   END AS VARCHAR(50))
             ,'') AS CPTCode
      ,ISNULL(CAST(club.REVENUE_CODE AS VARCHAR(50)), '') AS RevCode
      ,ISNULL(CAST(htr.HCPCS_CODE AS VARCHAR(50)), '') AS HCPCSCode
      ,ISNULL(CAST(ndc.RAW_11_DIGIT_NDC AS VARCHAR(50)), '') AS NDCCode
      ,ISNULL(CAST(htr.ERX_ID AS VARCHAR(50)), '') AS ERXId
      ,ISNULL(CAST(erx.NAME AS VARCHAR(200)), '') AS ERXDescription
      ,ISNULL(CAST(htr.SUP_ID AS VARCHAR(50)), '') AS SupplyId
      ,ISNULL(CAST(sup.SUPPLY_NAME AS VARCHAR(200)), '') AS SupplyDescription
      ,ISNULL(CAST(htr.IMPLANT_ID AS VARCHAR(50)), '') AS ImplantId
      ,ISNULL(CAST(imp.IMPLANT_NAME AS VARCHAR(200)), '') AS ImplantDescription
      ,CAST(har.LOC_ID AS VARCHAR(50)) AS FacilityIdentifier --Cannot be NULL
FROM HSP_TRANSACTIONS AS htr
JOIN cteAccountsNumbers AS har
     ON htr.HSP_ACCOUNT_ID = har.HSP_ACCOUNT_ID
LEFT OUTER JOIN CLARITY_EAP AS eap
                ON htr.PROC_ID = eap.PROC_ID
LEFT OUTER JOIN RX_NDC AS ndc
                ON htr.NDC_ID = ndc.NDC_ID
LEFT OUTER JOIN CLARITY_MEDICATION AS erx
                ON htr.ERX_ID = erx.MEDICATION_ID
LEFT OUTER JOIN OR_SPLY AS sup
                ON htr.SUP_ID = sup.SUPPLY_ID
LEFT OUTER JOIN OR_IMP AS imp
                ON htr.IMPLANT_ID = imp.IMPLANT_ID
LEFT OUTER JOIN CL_UB_REV_CODE AS club
                ON htr.UB_REV_CODE_ID = club.UB_REV_CODE_ID
WHERE
  /********************** Comment out the date range below that IS to be used. ***********************/

  --/* -- UNCOMMENT OUT THIS SECTION TO RUN FILE FOR THE WEEKLY PERIOD  --
  htr.TX_POST_DATE BETWEEN @StartDatePeriod AND @EndDatePeriod --PostDate ***** PERIOD ******
  AND htr.TX_TYPE_HA_C = '1'; --1 = Charges		

--*/

/* -- UNCOMMENT THIS SECTION TO RUN HISTORICAL FILE **-365 days to PRESENT** --
	htr.TX_POST_DATE BETWEEN @StartDateHistorical and @EndDateHistorical		--PostDate **** HISTORICAL ***		
	and htr.TX_TYPE_HA_C = '1'													--1 = Charges			
--*/