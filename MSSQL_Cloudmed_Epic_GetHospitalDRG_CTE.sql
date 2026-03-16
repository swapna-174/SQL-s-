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

SELECT	
 'FACILITY_ID'				= ISNULL(CONVERT(VARCHAR(18),HAR.LOC_ID),'')	
,'ACCOUNT_NUMBER'			= HAR.HSP_ACCOUNT_ID			
,'SEQUENCE_NUMBER'			= DRGS.LINE
,'DRG'						= ISNULL(DRGS.DRG_MPI_CODE,'') 
,'SOI'						= ISNULL(convert(varchar(10),DRGS.DRG_PS),'')
,'DRG_NAME'					= ISNULL(CDRG.DRG_NAME,'') 
,'DRG_TYPE'					= COALESCE(ZDC.NAME,SUBSTRING(DRGID.ID_TYPE_NAME,1,7),'')
,'DRG_VERSION'				= ISNULL(DRGID.ID_TYPE_NAME,'')	
,'DRG_WEIGHT'				= ISNULL(CONVERT(VARCHAR(18),DRGS.DRG_WEIGHT),'')	
,'RISK_OF_MORTALITY'		= ISNULL(rom.abbr,'')	
,'CMG_CODE'					= ISNULL(HAR.CASE_MIX_GRP_CODE,'')			-- BOX 44 OF UB04
,'BILLED_DRG_FLAG'			= DRGS.DRG_BILLING_FLAG_YN /*Valid values 'yes' or 'no'*/

FROM CTE_ACCT_LIST TAL

INNER JOIN dbo.HSP_ACCOUNT AS HAR 	
	ON HAR.HSP_ACCOUNT_ID = TAL.HSP_ACCOUNT_ID 
INNER JOIN dbo.HSP_ACCT_MULT_DRGS AS DRGS 
	ON HAR.HSP_ACCOUNT_ID = DRGS.HSP_ACCOUNT_ID 
	-- AND DRGS.DRG_BILLING_FLAG_YN = 'Y'	
	/*MUST BE THE BILLING DRG, WHETHER MS OR APR
	JK - believe this should be removed as we want all the DRGs, not just the billing one*/

LEFT JOIN dbo.IDENTITY_ID_TYPE AS DRGID
	 ON DRGS.DRG_ID_TYPE_ID = DRGID.ID_TYPE 
LEFT JOIN dbo.CLARITY_DRG AS CDRG 
	ON DRGS.DRG_ID = CDRG.DRG_ID 		
LEFT JOIN dbo.ZC_SOI_ROM rom 
	ON rom.SOI_ROM_C = DRGS.DRG_ROM
LEFT JOIN dbo.ZC_DRG_CODE_SET ZDC
	ON ZDC.DRG_CODE_SET_C = CDRG.DRG_CODE_SET_C

