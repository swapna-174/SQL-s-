/*
USE VSE-PRD-CLR1\CLARITY_PRD/Clarity_PRD

*****McKesson Transaction Data Extract*****
Transaction Data
Patient Transaction Detail: The detail file should contain all payment/write-off/denial transactions posted within the applicable time frame.

*******This Script is just a guide to help. 
*******Code changes may be required to yield correct results based on your Table Structures******

File Name:  TransactionDataYYYYMMDD.txt
Criteria / Frequency:
	Historical 	All accounts that have an admit date from 365 days back to present
	Weekly		A weekly file will be required to contain all entries with a posting date within the past 21 days
*/

--/* ------------------------------------- DATE --------------------------------------------------
-- Sets Date Options *** Comment out the appropriate date range in the Where Clause at bottom ***
DECLARE @Today DATE = GETDATE()
       ,@HistoricalTimeRange INT = 365
       ,@WeeklyTimeRange INT = 21 --Use if Files are sent Weekly
       ,@DailyTimeRange INT = 7;  -- Use if Files are sent Daily

---Use for Weekly
DECLARE @StartDateHistorical DATE = DATEADD(DAY, -@HistoricalTimeRange, @Today)
       ,@EndDateHistorical DATE = DATEADD(DAY, -1, @Today)
       ,@StartDatePeriod DATE = DATEADD(DAY, -@WeeklyTimeRange, @Today)
       ,@EndDatePeriod DATE = DATEADD(DAY, -1, @Today)
       ,@StartDateAccounts DATE = DATEADD(DAY, -@HistoricalTimeRange, @Today)
       ,@EndDateAccounts DATE = DATEADD(DAY, -1, @Today);

---Use for Daily
--DECLARE @StartDateHistorical DATE = DATEADD(DAY, -@HistoricalTimeRange, @Today)
--       ,@EndDateHistorical DATE = DATEADD(DAY, -1, @Today)
--       ,@StartDatePeriod DATE = DATEADD(DAY, -@DailyTimeRange, @Today)
--       ,@EndDatePeriod DATE = DATEADD(DAY, -1, @Today)
--       ,@StartDateAccounts DATDATEETIME2 = DATEADD(DAY, -@HistoricalTimeRange, @Today)
--       ,@EndDateAccounts DATE = DATEADD(DAY, -1, @Today)

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
      ,NULL AS CycleNumber
      ,ISNULL(RTRIM(CONVERT(VARCHAR(23), htr.SERVICE_DATE, 121)), '') AS TransactionDate
      ,ISNULL(RTRIM(CONVERT(VARCHAR(23), htr.TX_POST_DATE, 121)), '') AS PostingDate
      ,ISNULL(CAST(eap.PROC_CODE AS VARCHAR(50)), '') AS TransactionCode
      ,CASE --The CASE below may require in depth testing to ensure accuracy
         WHEN htr.TX_TYPE_HA_C BETWEEN 3 AND 4
         THEN 'Adjustment'
         WHEN bucket.BKT_TYPE_HA_C = 4
         THEN 'PatPmt'
         WHEN bucket.BKT_TYPE_HA_C IN (2, 3, 6, 7)
         THEN 'InsPmt'
       END AS TransactionType                                -- This Cannot be NULL																									
      ,ISNULL(CAST(htr.PROCEDURE_DESC AS VARCHAR(100)), '') AS TransactionDescription
      ,ISNULL(ROUND(CAST(htr.TX_AMOUNT AS DECIMAL(18, 2)), 2), 0.00) AS Amount
      ,ISNULL(CAST(htr.PAYOR_ID AS VARCHAR(50)), '') AS InsuranceCode
      ,ISNULL(CAST(htr.FIN_CLASS_C AS VARCHAR(50)), '') AS CurrentFinancialClassCode
      ,CAST(har.LOC_ID AS VARCHAR(50)) AS FacilityIdentifier -- Cannot be NULL
FROM HSP_TRANSACTIONS AS htr
JOIN cteAccountsNumbers AS har -- This should be a JOIN to prevent data being sent with out an account
     ON htr.HSP_ACCOUNT_ID = har.HSP_ACCOUNT_ID
LEFT OUTER JOIN CLARITY_EAP AS eap
                ON htr.PROC_ID = eap.PROC_ID
LEFT OUTER JOIN ZC_TX_TYPE_HA AS txtyp
                ON htr.TX_TYPE_HA_C = txtyp.TX_TYPE_HA_C
LEFT OUTER JOIN ZC_FIN_CLASS AS fc
                ON htr.FIN_CLASS_C = fc.FIN_CLASS_C
LEFT OUTER JOIN CLARITY_EPM AS epm
                ON htr.payor_id = epm.payor_id
LEFT OUTER JOIN HSP_bucket AS bucket
                ON htr.HSP_ACCOUNT_ID = bucket.HSP_ACCOUNT_ID
                   AND htr.BUCKET_ID = bucket.BUCKET_ID
WHERE
  /********************** Comment out the date range below that IS to be used. ***********************/

  --/* -- UNCOMMENT OUT THIS SECTION TO RUN FILE FOR THE WEEKLY PERIOD --
  htr.TX_POST_DATE BETWEEN @StartDatePeriod AND @EndDatePeriod --PostDate ***** PERIOD ******
  AND htr.TX_TYPE_HA_C <> '1'; --1 = Charges.....this is including TX Types 2,3,4(Payments,Cr Adj ,Debit Adj)			
--*/

/* -- UNCOMMENT THIS SECTION TO RUN HISTORICAL FILE **-365 days to PRESENT** --
	htr.TX_POST_DATE BETWEEN  @StartDateHistorical and @EndDateHistorical		--PostDate **** HISTORICAL ***		
	and htr.TX_TYPE_HA_C <> '1'	--1 = Charges.....this is including TX Types 2,3,4(Payments,Cr Adj ,Debit Adj)			
                           
--*/