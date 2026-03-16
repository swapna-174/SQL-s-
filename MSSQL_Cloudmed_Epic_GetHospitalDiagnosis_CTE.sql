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

/******************************************************************************************

MAIN CODE LOGIC

******************************************************************************************/

SELECT   DISTINCT
		 'FACILITY_ID'				= ISNULL(CONVERT(VARCHAR(18),HAR.LOC_ID),'')
		,'ACCOUNT_NUMBER'			= HAR.HSP_ACCOUNT_ID
		,'SEQUENCE'					= DXALL.LINE -- 0 for admitting, 1 for Primary, 
		,'DIAGNOSIS_CODE'			= ISNULL(EDG.REF_BILL_CODE,'')
		,'DIAGNOSIS_DESCRIPTION'	= ISNULL(EDG.DX_NAME,'') 
		,'DIAGNOSIS_TYPE'			= DXALL.DXTYPE -- 'A' for Admitting, 'P' for Primary, 'F' for final
		,'DIAGNOSIS_VERSION'		= (CASE WHEN EDG.REF_BILL_CODE_SET_C = 1 THEN '9' 
										WHEN EDG.REF_BILL_CODE_SET_C = 2 THEN '10' 
		 								ELSE 'B' END)
		,'POA_CODE'					= ISNULL(poa.abbr,'')
		


FROM CTE_ACCT_LIST TAL 
INNER JOIN HSP_ACCOUNT HAR
	ON HAR.HSP_ACCOUNT_ID = TAL.HSP_ACCOUNT_ID
--- UNION ALL DIAGNOSIS RECORDS FROM BOTH MAIN AND ALTERNATE TABLES
INNER JOIN 
		(SELECT dx.HSP_ACCOUNT_ID 
				,DX.LINE
				,(CASE WHEN LINE = 1 THEN 'P' ELSE 'F' END) AS DXTYPE
				,DX.DX_ID AS DX_ID
				,DX.FINAL_DX_POA_C AS POACODE
				
		FROM dbo.HSP_ACCT_DX_LIST AS DX
		INNER JOIN CTE_ACCT_LIST AS tal 
			on DX.HSP_ACCOUNT_ID = tal.HSP_ACCOUNT_ID
		
		UNION ALL
		
		SELECT ADX.HSP_ACCOUNT_ID
				, 0 AS LINE
				,'A' AS DXTYPE
				,ADX.ADMIT_DX_ID AS DX_ID
				,NULL AS POACODE

		FROM dbo.HSP_ACCT_ADMIT_DX ADX
		INNER JOIN CTE_ACCT_LIST TAL
			ON TAL.HSP_ACCOUNT_ID = ADX.HSP_ACCOUNT_ID
		WHERE LINE = 1
		) AS DXALL ON HAR.HSP_ACCOUNT_ID = DXALL.HSP_ACCOUNT_ID

INNER JOIN dbo.CLARITY_EDG AS EDG 
	ON DXALL.DX_ID = EDG.DX_ID
LEFT JOIN dbo.ZC_DX_POA AS poa 
	ON DXALL.POACODE = poa.DX_POA_C
LEFT JOIN dbo.PATIENT AS PT 
	ON HAR.PAT_ID = PT.PAT_ID
	
