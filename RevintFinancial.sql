/*****************************************************************************************
	DESCRIPTION: PULL FINANCIAL TRANSACTIONS.  
	runtime ~ 4 mins
******************************************************************************************/

/********************************************************************************************************
Text output:
1) Tools--> Options --> Query Results --> Sql Server --> Results to Text.
2) Change output format to Custom Delimited and put pipe in delimiter box.
3) In query select Query --> Results to File. Execute query, supply filename, change extension to .txt.

8/10/21 LDO - added Invoice number, DRG, and Deposit Date per Payton Argaez.
1/24/22 LDO - Requested change: Add a column to represent a supplemental manually created 
facilityCodeEMR value, intended to represent whether a given record was discharged before or 
after the corresponding facility’s Epic Go Live Date.  Per Payton Argaez.
********************************************************************************************************/
SET NOCOUNT ON
SET ANSI_WARNINGS OFF

DECLARE @STARTDATECD date = EPIC_UTIL.EFN_DIN('T-50')
	,@ENDDATECD date =  EPIC_UTIL.EFN_DIN('T-1')

/*****************************************************************************************
Create CTE of account numbers based on last updated date within the date range, or which
have transactions posted in the transactions within the date range.
******************************************************************************************/
;With cteRevintAccount as (
SELECT 	'EPIC' AS 'SOURCE_SYSTEM'
			,HAR.HSP_ACCOUNT_ID
			,Cast(ISNULL(HAR.DISCH_DATE_TIME,PEH.HOSP_DISCH_TIME) as date) 'DISCHG_DATE'  --2/24/22
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
			AND DATEDIFF(DAY, ISNULL(HAR.DISCH_DATE_TIME,PEH.HOSP_DISCH_TIME), GETDATE()) <= 545  --Limit to only discharge dates from 1.5 years old, even if something on account has changed
			And har.LOC_ID not in (10002,10006,10090)	--Exclude Rehab, Behav Health, Blue Ridge
			And har.SERV_AREA_ID = 10
			And sbo.SBO_HAR_TYPE_C = 0		--Include only HB HARs
			And vp.IS_VALID_PAT_YN <> 'N'	--Select only valid patients
			And har.ACCT_FIN_CLASS_C <> 4	--Exclude Self-pay  LDO 10/19/18 per Debbie Nash
)

/******************************************************************************************************************
MAIN CODE GETTING TRANSACTIONS
******************************************************************************************************************/
SELECT 
		TX.TX_ID AS 'TransactionId'

		--,HAR.HSP_ACCOUNT_ID AS 'VisitNumber'								--10/25/18
		,Concat(vals.EXT_VALUE, HAR.HSP_ACCOUNT_ID)			'VisitNumber'	--10/25/18

		,ISNULL(CONVERT(varchar(18),HAR.LOC_ID),'')			'FacilityCode'
		,ISNULL(ZTT.NAME,'')								'FinancialType'
		,ISNULL(CONVERT(VARCHAR(10),TX.TX_POST_DATE,101),'')  'PostDate'
		,ISNULL(EAP.PROC_CODE,'')							'FinancialCode'
		,ISNULL(EAP.PROC_NAME,'')							'FinancialName'
		,CAST(TX.TX_AMOUNT AS NUMERIC(18,2))				'FinancialAmount'
		,ISNULL(FC.FINANCIAL_CLASS_NAME,'')					'PayerFinancialClass'
		,ISNULL(CONVERT(VARCHAR(18),TX.PAYOR_ID),'')		'PayerCategoryId'
		,ISNULL(EPM.PAYOR_NAME,'')							'PayerCategoryName'
		,ISNULL(CONVERT(VARCHAR(18),TX.PRIMARY_PLAN_ID),'') 'PayerPlanId'
		,ISNULL(EPP.BENEFIT_PLAN_NAME,'')					'PayerPlanName'
		,CASE WHEN TX.TX_TYPE_HA_C = 2 then TX.SERVICE_DATE ELSE '' END 'DEPOSIT_DATE'  --8/10/21
		,ISNULL(TX2.PMT_DRG_CODE,'')						'DRG_CODE'					--8/10/21
		,ISNULL (TX.INVOICE_NUM,'')							'INVOICE_NUMBER'			--8/10/21

/* 1/24/22 start changes */ 
,CASE 
WHEN har.LOC_ID = 10060 AND TAL.DISCHG_DATE >= '2021-12-04' THEN '10060-Epic'
WHEN har.LOC_ID = 10065 AND TAL.DISCHG_DATE >= '2021-12-04' THEN '10065-Epic'
WHEN har.LOC_ID = 10001 AND TAL.DISCHG_DATE >= '2022-04-02' THEN '10001-Epic'
WHEN har.LOC_ID = 10005 AND TAL.DISCHG_DATE >= '2022-04-02' THEN '10005-Epic'
WHEN har.LOC_ID = 10003 AND TAL.DISCHG_DATE >= '2022-08-06' THEN '10003-Epic'
WHEN har.LOC_ID = 10007 AND TAL.DISCHG_DATE >= '2022-08-06' THEN '10007-Epic'
WHEN har.LOC_ID = 10010 AND TAL.DISCHG_DATE >= '2022-08-06' THEN '10010-Epic'
WHEN har.LOC_ID = 10040 AND TAL.DISCHG_DATE >= '2022-08-06' THEN '10040-Epic'
WHEN har.LOC_ID = 10050 AND TAL.DISCHG_DATE >= '2022-08-06' THEN '10050-Epic'
WHEN har.LOC_ID = 10070 AND TAL.DISCHG_DATE >= '2022-08-06' THEN '10070-Epic'
WHEN har.LOC_ID = 10080 AND TAL.DISCHG_DATE >= '2022-08-06' THEN '10080-Epic'
WHEN har.LOC_ID = 10500 AND TAL.DISCHG_DATE >= '2022-07-03' THEN '10500-Epic'  --Navicent
WHEN har.LOC_ID = 10300 AND TAL.DISCHG_DATE >= '2022-07-03' THEN '10300-Epic'  --Navicent
WHEN har.LOC_ID = 10600 AND TAL.DISCHG_DATE >= '2022-07-03' THEN '10600-Epic'  --Navicent
WHEN har.LOC_ID = 10400 AND TAL.DISCHG_DATE >= '2022-07-03' THEN '10400-Epic'  --Navicent
ELSE Cast(har.LOC_ID as varchar) 
END AS facilityCodeEMR
/* 1/24/22 end changes */ 

FROM HSP_ACCOUNT AS HAR 
INNER JOIN HSP_TRANSACTIONS AS TX 
	ON har.HSP_ACCOUNT_ID = TX.HSP_ACCOUNT_ID 
	AND tx.TX_TYPE_HA_C <> 1 ----- ALL NON CHARGE TRANSACTION TYPE
INNER JOIN cteRevintAccount AS TAL 
	ON HAR.HSP_ACCOUNT_ID = TAL.HSP_ACCOUNT_ID
LEFT JOIN ZC_TX_TYPE_HA AS ztt 
	ON TX.TX_TYPE_HA_C = ZTT.TX_TYPE_HA_C
LEFT JOIN CLARITY_EPM AS EPM 
	ON TX.PAYOR_ID = EPM.PAYOR_ID
LEFT JOIN CLARITY_EPP AS EPP 
	ON TX.PRIMARY_PLAN_ID = EPP.BENEFIT_PLAN_ID
LEFT JOIN CLARITY_FC AS FC 
	ON TX.FIN_CLASS_C = FC.FINANCIAL_CLASS
LEFT JOIN CLARITY_EAP EAP 
	ON TX.PROC_ID = EAP.PROC_ID
LEFT JOIN HSP_TRANSACTIONS_2 TX2	--8/10/21
	ON TX.TX_ID=TX2.TX_ID			--8/10/21

--Get Facility letter 10/25/18; Table_ID 1080050 is HB Legacy Fac Indicator Table
Left outer join INTERFACE_TBL_VALS vals on HAR.LOC_ID = vals.INT_VALUE and vals.TABLE_ID = 1080050

WHERE
---Limit to only Post Dates within the Scope Range
Cast(TX.TX_POST_DATE as date) between @STARTDATECD and @ENDDATECD

Order by 2
