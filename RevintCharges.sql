/********************************************************************************************************
Runtime: ~35 mins
Text output:
1) Tools--> Options --> Query Results --> Sql Server --> Results to Text.
2) Change output format to Custom Delimited and put pipe in delimiter box.
3) In query select Query --> Results to File. Execute query, supply filename, change extension to .txt.

1/24/22 LDO - Requested change: Add a column to represent a supplemental manually created 
facilityCodeEMR value, intended to represent whether a given record was discharged before or 
after the corresponding facility’s Epic Go Live Date.  Per Payton Argaez.
Also changed cteRevintAccount to a temp table.
********************************************************************************************************/
SET NOCOUNT ON
SET ANSI_WARNINGS OFF

DECLARE @STARTDATECD date = EPIC_UTIL.EFN_DIN('T-50')
	,@ENDDATECD date =  EPIC_UTIL.EFN_DIN('T-1')


IF OBJECT_ID('TempDB..##TMP_RevintChgAccount') IS NOT NULL DROP TABLE ##TMP_RevintChgAccount

/*****************************************************************************************
Create temp table of account numbers based on last updated date within the date range, or which
have transactions posted in the transactions within the date range.
******************************************************************************************/
--;With cteRevintAccount as (
SELECT 	'EPIC' AS 'SOURCE_SYSTEM'
			,HAR.HSP_ACCOUNT_ID
			,Cast(ISNULL(HAR.DISCH_DATE_TIME,PEH.HOSP_DISCH_TIME) as date) 'DISCHG_DATE'  --2/24/22
		INTO ##TMP_RevintChgAccount
        FROM HSP_ACCOUNT AS HAR
        LEFT JOIN PAT_ENC_HSP AS PEH
			ON HAR.PRIM_ENC_CSN_ID = PEH.PAT_ENC_CSN_ID      
        LEFT JOIN HSP_ACCT_LAST_UPDATE AS halu
                ON HAR.HSP_ACCOUNT_ID = halu.HSP_ACCOUNT_ID   
		/* Standard validation info */
		Left Outer Join HSP_ACCT_SBO sbo		on sbo.HSP_ACCOUNT_ID = har.HSP_ACCOUNT_ID  --to get only HB HARs
		Left Outer Join VALID_PATIENT vp		on har.PAT_ID = vp.PAT_ID --to get only valid (non-test) patients				  
        WHERE 
			har.ACCT_BASECLS_HA_C = '1'  --Limit to inpatient records only
			AND Cast(ISNULL(halu.INST_OF_UPDATE_DTTM,har.INST_OF_UPDATE) as date) between @STARTDATECD and @ENDDATECD  --Limit to the scoped date range
			AND DATEDIFF(DAY, ISNULL(HAR.DISCH_DATE_TIME,PEH.HOSP_DISCH_TIME), GETDATE()) <= 550  --Limit to only discharge dates from 1.5 years old, even if something on account has changed
			And har.LOC_ID not in (10002,10006,10090)	--Exclude Rehab, Behav Health, Blue Ridge
			And har.SERV_AREA_ID = 10
			And sbo.SBO_HAR_TYPE_C = 0		--Include only HB HARs
			And vp.IS_VALID_PAT_YN <> 'N'	--Select only valid patients
			And har.ACCT_FIN_CLASS_C <> 4	--Exclude Self-pay  LDO 10/19/18 per Debbie Nash
--)

/******************************************************************************************************************
MAIN CODE GETTING CHARGE TRANSACTIONS
******************************************************************************************************************/
SELECT  
     HSP_TRANSACTIONS.TX_ID AS 'ChargeId' --Unique transaction Identifier
	 
	 --,HSP_TRANSACTIONS.HSP_ACCOUNT_ID AS 'VisitNumber'	--					--10/25/18
	 ,Concat(vals.EXT_VALUE, HSP_TRANSACTIONS.HSP_ACCOUNT_ID) AS 'VisitNumber'	--10/25/18
	 
	 ,ISNULL(CONVERT(VARCHAR(20),HSP_ACCOUNT.LOC_ID),'') AS 'FacilityCode'
	 
	 --,ISNULL(CONVERT(VARCHAR(18),HSP_TRANSACTIONS.UB_REV_CODE_ID),'')  AS 'RevenueCode'  --LDO
	 ,ISNULL(CL_UB_REV_CODE.REVENUE_CODE,'')							 AS 'RevenueCode'	--LDO

--- DATES
    ,ISNULL(CONVERT(VARCHAR(10),HSP_TRANSACTIONS.SERVICE_DATE,101),'') AS 'ServiceDate'
    ,CONVERT(VARCHAR(10),HSP_TRANSACTIONS.TX_POST_DATE,101) AS 'PostingDate'
-- Charge Code Info
	,ISNULL(EAP.PROC_CODE,'') 'ChargeCode'
    ,ISNULL(HSP_TRANSACTIONS.PROCEDURE_DESC,'') AS 'ChargeDescription' 
	,ISNULL(HSP_TRANSACTIONS.NDC_ID,'') AS 'PharmacyNCDID'
	,COALESCE(PHARM.NAME, PHARM.GENERIC_NAME,'') AS 'MedicationName'
--- quantity and amount
     ,HSP_TRANSACTIONS.QUANTITY AS 'Quantity'
     ,HSP_TRANSACTIONS.TX_AMOUNT AS 'Amount'
--- cpt/hcpcs code info
	,ISNULL(HSP_TRANSACTIONS.CPT_CODE, '') AS 'CPTCode'
	,ISNULL(HSP_TRANSACTIONS.HCPCS_CODE,'') AS 'HCPCSCode'
	---- MODIFIERS
	-- HSP_TRANSACTIONS.MODIFIERS is a comma separated string. PARSENAME function allows reading from a string that's separated by periods.
	-- So replace commas in HSP_TRANSACTIONS.MODIFIERS with periods. Then use PARSENAME to read each modifier separated by period.
	, CONVERT(VARCHAR(10), ISNULL(PARSENAME(REPLACE(HSP_TRANSACTIONS.MODIFIERS,',','.')
			, LEN( HSP_TRANSACTIONS.MODIFIERS) - LEN(REPLACE(HSP_TRANSACTIONS.MODIFIERS,',','')) + 1), '')) AS 'Modifier1'
	, CONVERT(VARCHAR(10), ISNULL(PARSENAME(REPLACE(HSP_TRANSACTIONS.MODIFIERS,',','.')
			, LEN( HSP_TRANSACTIONS.MODIFIERS) - LEN(REPLACE(HSP_TRANSACTIONS.MODIFIERS,',','')) + 0), '')) AS 'Modifier2'

/* 1/24/22 start changes */ 
,CASE 
WHEN HSP_ACCOUNT.LOC_ID = 10060 AND TAL.DISCHG_DATE >= '2021-12-04' THEN '10060-Epic'
WHEN HSP_ACCOUNT.LOC_ID = 10065 AND TAL.DISCHG_DATE >= '2021-12-04' THEN '10065-Epic'
WHEN HSP_ACCOUNT.LOC_ID = 10001 AND TAL.DISCHG_DATE >= '2022-04-02' THEN '10001-Epic'
WHEN HSP_ACCOUNT.LOC_ID = 10005 AND TAL.DISCHG_DATE >= '2022-04-02' THEN '10005-Epic'
WHEN HSP_ACCOUNT.LOC_ID = 10003 AND TAL.DISCHG_DATE >= '2022-08-06' THEN '10003-Epic'
WHEN HSP_ACCOUNT.LOC_ID = 10007 AND TAL.DISCHG_DATE >= '2022-08-06' THEN '10007-Epic'
WHEN HSP_ACCOUNT.LOC_ID = 10010 AND TAL.DISCHG_DATE >= '2022-08-06' THEN '10010-Epic'
WHEN HSP_ACCOUNT.LOC_ID = 10040 AND TAL.DISCHG_DATE >= '2022-08-06' THEN '10040-Epic'
WHEN HSP_ACCOUNT.LOC_ID = 10050 AND TAL.DISCHG_DATE >= '2022-08-06' THEN '10050-Epic'
WHEN HSP_ACCOUNT.LOC_ID = 10070 AND TAL.DISCHG_DATE >= '2022-08-06' THEN '10070-Epic'
WHEN HSP_ACCOUNT.LOC_ID = 10080 AND TAL.DISCHG_DATE >= '2022-08-06' THEN '10080-Epic'
WHEN HSP_ACCOUNT.LOC_ID = 10500 AND TAL.DISCHG_DATE >= '2022-07-03' THEN '10500-Epic'  --Navicent
WHEN HSP_ACCOUNT.LOC_ID = 10300 AND TAL.DISCHG_DATE >= '2022-07-03' THEN '10300-Epic'  --Navicent
WHEN HSP_ACCOUNT.LOC_ID = 10600 AND TAL.DISCHG_DATE >= '2022-07-03' THEN '10600-Epic'  --Navicent
WHEN HSP_ACCOUNT.LOC_ID = 10400 AND TAL.DISCHG_DATE >= '2022-07-03' THEN '10400-Epic'  --Navicent
ELSE Cast(HSP_ACCOUNT.LOC_ID as varchar) 
END AS facilityCodeEMR
/* 1/24/22 end changes */ 

FROM  HSP_ACCOUNT HSP_ACCOUNT  
--INNER JOIN cteRevintAccount AS TAL
Inner Join ##TMP_RevintChgAccount as TAL
	ON HSP_ACCOUNT.HSP_ACCOUNT_ID = TAL.HSP_ACCOUNT_ID
INNER JOIN	HSP_TRANSACTIONS AS HSP_TRANSACTIONS
	ON HSP_ACCOUNT.HSP_ACCOUNT_ID = HSP_TRANSACTIONS.HSP_ACCOUNT_ID
	AND HSP_TRANSACTIONS.TX_TYPE_HA_C = 1  --- CHARGE TRANSACTION TYPE

---POSSIBLY REMOVE NEXT 2 TABLES, ONLY columns we are concerned about are ServiceDate and PostDate        
--LEFT JOIN ZC_TX_TYPE_HA AS ZC_TX_TYPE_HA
--    ON ZC_TX_TYPE_HA.TX_TYPE_HA_C = HSP_TRANSACTIONS.TX_TYPE_HA_C
--LEFT JOIN ZC_TX_SOURCE_HA AS ZC_TX_SOURCE_HA
--    ON HSP_TRANSACTIONS.TX_SOURCE_HA_C = ZC_TX_SOURCE_HA.TX_SOURCE_HA_C

---PULL CHARGE CODE AND NAME
LEFT JOIN CLARITY_EAP AS EAP
    ON EAP.PROC_ID = HSP_TRANSACTIONS.PROC_ID

--- UB REV CODES
LEFT JOIN CL_UB_REV_CODE AS CL_UB_REV_CODE 
	ON CL_UB_REV_CODE.UB_REV_CODE_ID = HSP_TRANSACTIONS.UB_REV_CODE_ID

--- PHARMACY CHARGE INFORMATION
LEFT JOIN CLARITY_MEDICATION AS PHARM 
	ON HSP_TRANSACTIONS.ERX_ID = PHARM.MEDICATION_ID

--Get Facility letter 10/25/18; Table_ID 1080050 is HB Legacy Fac Indicator Table
Left outer join INTERFACE_TBL_VALS vals on HSP_ACCOUNT.LOC_ID = vals.INT_VALUE and vals.TABLE_ID = 1080050

WHERE   
---Limit to only Post Dates within the Scope Range
Cast(HSP_TRANSACTIONS.TX_POST_DATE as date) between @STARTDATECD and @ENDDATECD

--order by 2

IF OBJECT_ID('TempDB..##TMP_RevintChgAccount') IS NOT NULL DROP TABLE ##TMP_RevintChgAccount