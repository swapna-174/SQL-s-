BEGIN

	USE CLARITY

END
;

--Variables for Recurring/Incremental phase
DECLARE @CurDate DATETIME
DECLARE @BeginDate DATETIME
SET @CurDate = CONVERT(DATETIME, DATEDIFF(DAY, 0, GETDATE()))
SET @BeginDate = DATEADD(DAY,-14,@CurDate) --To modify the lookback period, set the negative integer to the desired number of days (-14 is the default, looking back 14 days)
;

WITH CTE_ACCT_LIST
  AS
  (
        SELECT DISTINCT	HAR.HSP_ACCOUNT_ID
        FROM    CLARITY.dbo.HSP_ACCOUNT AS HAR
        INNER JOIN CLARITY.dbo.HSP_TRANSACTIONS AS HTR     -- Should be good for HB accounts and exclude PB accounts
                ON HTR.HSP_ACCOUNT_ID = HAR.HSP_ACCOUNT_ID
		INNER JOIN Clarity.dbo.HSP_ACCT_LAST_UPDATE AS HALU 
                ON HTR.HSP_ACCOUNT_ID = halu.HSP_ACCOUNT_ID
        --WHERE HALU.INST_OF_UPDATE_DTTM >= @BeginDate --Used for Recurring/Incremental phase, comment out for Testing/Historical phase
        WHERE HAR.DISCH_DATE_TIME BETWEEN @STARTDATE AND @ENDDATE --Used for Testing/Historical phase, comment out for Recurring/Incremental phase
	)	

/******************************************************************************************************************
MAIN CODE GETTING TRANSACTIONS

******************************************************************************************************************/


SELECT 

	 'FACILITY_ID'									= ISNULL(CONVERT(varchar(18),HAR.LOC_ID),'')
	,'ACCOUNT_NUMBER'								= HAR.HSP_ACCOUNT_ID
	,'FINANCIAL_TRANSACTION_ID'						= TX.TX_ID
	,'FINANCIAL_TYPE_CODE'							= TX.TX_TYPE_HA_C -- High Level Code for determining Payment versus Adjustment
	,'FINANCIAL_TYPE_DESCRIPTION'					= ISNULL(ZTT.NAME,'')
	,'FINANCIAL_TRANSACTION_CODE'					= ISNULL(EAP.PROC_CODE,'')
	,'FINANCIAL_TRANSACTION_CODE_DESCRIPTION'		= ISNULL(EAP.PROC_NAME,'')
	,'TRANSACTION_AMOUNT'							= CAST(TX.TX_AMOUNT AS NUMERIC(18,2)) 
	,'DEDUCTIBLE'									= ISNULL(TX.DEDUCTIBLE_AMOUNT,'0.00')
	,'COPAYMENT'									= ISNULL(TX.COPAY_AMOUNT,'0.00')
	,'COINSURANCE'									= ISNULL(TX.COINSURANCE_AMOUNT,'0.00') 
	,'COB_NUMBER'									= (CASE WHEN CVG.LINE IS NOT NULL THEN CVG.LINE  -- ZK - Some buckets have coverages that don't exist in HSP_ACCT_CVG_LIST.
															WHEN BKT.BKT_TYPE_HA_C IN (2,6,20,25) THEN 1  	-- We have four bucket types for both primary and secondary: standard claims, interim claims, home health RAP, and hospice.  
															WHEN BKT.BKT_TYPE_HA_C IN (3,7,21,26) THEN 2 ELSE NULL END)		
	,'PAYER_CODE'									= ISNULL(CONVERT(VARCHAR(18),TX.PAYOR_ID),'')
	,'PAYER_NAME'									= ISNULL(EPM.PAYOR_NAME,'')
	,'PAYER_FINANCIAL_CLASS'						= ISNULL(FC.FINANCIAL_CLASS_NAME,'SELF-PAY') 
	,'POSTING_DATE'									= ISNULL(CONVERT(VARCHAR(10),TX.TX_POST_DATE,101),'')
	,'DEPOSIT_DATE'									= (CASE WHEN TX.TX_TYPE_HA_C = 2 then TX.SERVICE_DATE ELSE NULL END)
    ,'USER_ID'										= ISNULL(TX.[USER_ID],'None')
	,'DRG_CODE'										= ISNULL(TX2.PMT_DRG_CODE,'') --  DRGCode
	,'INVOICE_NUMBER'								= ISNULL (TX.INVOICE_NUM,'')
	


FROM CTE_ACCT_LIST TAL

INNER JOIN dbo.HSP_ACCOUNT AS HAR 
	ON HAR.HSP_ACCOUNT_ID = TAL.HSP_ACCOUNT_ID

INNER JOIN dbo.HSP_TRANSACTIONS AS TX 
	ON har.HSP_ACCOUNT_ID = TX.HSP_ACCOUNT_ID 
	AND tx.TX_TYPE_HA_C <> 1
LEFT JOIN HSP_TRANSACTIONS_2 TX2
	ON TX.TX_ID=TX2.TX_ID

INNER JOIN dbo.CLARITY_LOC AS LOC 
	ON HAR.LOC_ID = LOC.LOC_ID	

	LEFT JOIN CLARITY.DBO.HSP_BUCKET AS BKT	
		ON TX.BUCKET_ID = BKT.BUCKET_ID
	LEFT JOIN CLARITY.DBO.CLARITY_EPP AS EPP
		ON BKT.BENEFIT_PLAN_ID = EPP.BENEFIT_PLAN_ID
	LEFT JOIN HSP_ACCT_CVG_LIST AS CVG
		ON BKT.HSP_ACCOUNT_ID = CVG.HSP_ACCOUNT_ID
		AND BKT.COVERAGE_ID = CVG.COVERAGE_ID

LEFT JOIN dbo.ZC_TX_TYPE_HA AS ztt 
	ON TX.TX_TYPE_HA_C = ZTT.TX_TYPE_HA_C
LEFT JOIN dbo.PATIENT AS PT 
	ON HAR.PAT_ID = PT.PAT_ID
LEFT JOIN dbo.CLARITY_EPM EPM 
	ON TX.PAYOR_ID = EPM.PAYOR_ID



LEFT JOIN dbo.CLARITY_FC AS FC 
	ON TX.FIN_CLASS_C = FC.FINANCIAL_CLASS
LEFT JOIN dbo.CLARITY_EAP EAP 
	ON TX.PROC_ID = EAP.PROC_ID
