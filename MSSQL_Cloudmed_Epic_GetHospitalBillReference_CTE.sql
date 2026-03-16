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
/********************************************MAIN QUERY*******************************************/

	SELECT DISTINCT

		 'LOCATION_ID'					= ISNULL(CONVERT(varchar(18),HAR.LOC_ID),'')
		,'ACCOUNT_NUMBER'				= HAR.HSP_ACCOUNT_ID
		,'BUCKET_ID' 					= B.BUCKET_ID
 		,'CLAIM_NUMBER'					= ISNULL(CONVERT(VARCHAR(18),B.LAST_CLM_INV_NUM),'')
		,'COB'							= ISNULL(CONVERT(VARCHAR(8),C.LINE),'')
		,'PAYOR_CODE'					= ISNULL(CONVERT(VARCHAR(18),B.PAYOR_ID),'')
		,'PAYOR_NAME'					= ISNULL(INS.PAYOR_NAME,'')
 		,'FIRST_BILL_DATE'				= ISNULL(FORMAT(B.FIRST_CLAIM_DATE,'MM/dd/yyyy'),'')
 		,'FIRST_BILL_DATE_EXTERNAL'		= ISNULL(FORMAT(B.FST_EXT_CLM_SENT_DT,'MM/dd/yyyy'),'')
 		,'MOST_RECENT_BILL_DATE'		= ISNULL(FORMAT(B.LAST_CLAIM_DATE,'MM/dd/yyyy'),'')
		,'BILL_STATUS'					= ISNULL(BKT.NAME,'') 
		,'BILL_TYPE_CODE'				= ISNULL(B.CLAIM_TYPE_HA_C,'')
		,'BILL_TYPE_NAME'				= ISNULL(CLM.NAME,'')
		,'TOTAL_CHARGES'				= ISNULL(CONVERT(VARCHAR(18),B.CHARGE_TOTAL),'')
		,'EXPECTED_PAYMENT_AMOUNT'		= ISNULL(B.XR_BILLED_AMOUNT,0)
		,'PAID_AMOUNT'					= ISNULL(B.PAYMENT_TOTAL,0)
		,'ADJUSTMENT_AMOUNT'			= ISNULL(B.ADJUSTMENT_TOTAL,0)
 		,'TOB'							= ISNULL(CONVERT(VARCHAR(18),CLP.UB_BILL_TYPE),'')
 		,'CONTRACT_EXPLANATION'			= ''
		,'CONTRACT_ID'					= ISNULL(CONVERT(VARCHAR(18),HCD.CONTRACT_ID),'')
		,'CONTRACT_NAME'				= ISNULL(CONT.CONTRACT_NAME,'')



	FROM CTE_ACCT_LIST TAL
	INNER JOIN dbo.HSP_ACCOUNT HAR
 		ON tal.HSP_ACCOUNT_ID = har.hsp_account_id
	inner join dbo.hsp_bucket B 
 		on HAR.hsp_account_id = b.hsp_account_id
	inner join dbo.HSP_ACCT_CVG_LIST C 
 		on b.HSP_ACCOUNT_ID = c.HSP_ACCOUNT_ID and b.COVERAGE_ID = c.COVERAGE_ID
	inner join dbo.clarity_epm INS 
 		on b.payor_id = ins.payor_id
	inner join dbo.ZC_CLAIM_TYPE_HA clm
  	 on b.CLAIM_TYPE_HA_C = clm.CLAIM_TYPE_HA_C
	inner join dbo.Zc_bkt_sts_ha bkt 
 		on b.bkt_sts_ha_c = bkt.bkt_sts_ha_c
	LEFT JOIN HSP_CLAIM_DETAIL2 CLP 
		ON CLP.INVOICE_NUM = B.LAST_CLM_INV_NUM
		AND CLP.HLB_ID = B.BUCKET_ID
		and CLP.CLAIM_ACCEPT_DTTM is not null
	LEFT JOIN HSP_CLAIM_DETAIL1 HCD
		on hcd.CLAIM_PRINT_ID = CLP.CLAIM_PRINT_ID
	LEFT JOIN dbo.VEN_NET_CONT CONT
		ON CONT.CONTRACT_ID = HCD.CONTRACT_ID
