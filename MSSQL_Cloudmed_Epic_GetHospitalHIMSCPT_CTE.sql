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
,cte_modifiers
AS
(

SELECT  hacc.HSP_ACCOUNT_ID
       ,hacc.LINE
       ,hacc.CPT_MODIFIERS
       ,commas.firstcomma
       ,commas.secondcomma
       ,commas.thirdcomma
       ,CASE WHEN hacc.CPT_MODIFIERS IS NOT NULL THEN 
			 CASE WHEN commas.firstcomma > 0 
             THEN SUBSTRING(hacc.CPT_MODIFIERS,1,(commas.firstcomma - 1))
			 ELSE hacc.CPT_MODIFIERS
        END END  AS cptmod1
       ,CASE WHEN hacc.CPT_MODIFIERS IS NOT NULL
             THEN CASE WHEN commas.secondcomma = 0 THEN
							CASE WHEN commas.firstcomma = 0 THEN NULL
							ELSE SUBSTRING(hacc.CPT_MODIFIERS,firstcomma + 1, LEN(hacc.CPT_MODIFIERS))
							END 
                       WHEN commas.secondcomma > 0
                       THEN SUBSTRING(hacc.CPT_MODIFIERS,firstcomma + 1,
                                      (commas.secondcomma - commas.firstcomma
                                       - 1))
			
                  END
        END AS cptMOD2
       ,CASE WHEN hacc.CPT_MODIFIERS IS NOT NULL
             THEN CASE WHEN commas.thirdcomma = 0
                            AND commas.secondcomma = 0 THEN NULL
                       WHEN commas.thirdcomma = 0
                            AND commas.secondcomma > 0
                       THEN SUBSTRING(hacc.CPT_MODIFIERS,secondcomma + 1,
                                      (LEN(ISNULL(hacc.CPT_MODIFIERS,','))
                                           - commas.secondcomma))
                       WHEN commas.thirdcomma > 0
                       THEN SUBSTRING(hacc.CPT_MODIFIERS,secondcomma + 1,
                                      commas.thirdcomma - commas.secondcomma
                                      - 1)
                  END
        END AS cptMOD3

FROM    DBO.HSP_ACCT_CPT_CODES AS hacc
INNER JOIN (
            SELECT  t.HSP_ACCOUNT_ID
                   ,t.LINE
                   ,t.CPT_MODIFIERS
                   ,CHARINDEX(',',CPT_MODIFIERS,1) AS firstcomma
                   ,CASE WHEN CHARINDEX(',',CPT_MODIFIERS,1) = 0 THEN NULL
                         WHEN CHARINDEX(',',CPT_MODIFIERS,1) > 0
                         THEN CHARINDEX(',',CPT_MODIFIERS,
                                        (CHARINDEX(',',CPT_MODIFIERS,1) + 1))

				    -- XU,PT
                    END AS secondcomma
                   ,CASE WHEN CHARINDEX(',',CPT_MODIFIERS,
                                        (CHARINDEX(',',CPT_MODIFIERS,1) + 1)) = 0
                         THEN NULL
                         WHEN CHARINDEX(',',CPT_MODIFIERS,
                                        (CHARINDEX(',',CPT_MODIFIERS,1) + 1)) > 0
                         THEN CHARINDEX(',',CPT_MODIFIERS,
                                        (CHARINDEX(',',CPT_MODIFIERS,
                                                   (CHARINDEX(',',
                                                              CPT_MODIFIERS,1)
                                                    + 1)) + 1))
                    END AS thirdcomma
            FROM    DBO.HSP_ACCT_CPT_CODES AS t
			INNER JOIN CTE_ACCT_LIST AS tal ON t.HSP_ACCOUNT_ID = tal.hsp_account_id
           ) AS commas
        ON hacc.HSP_ACCOUNT_ID = commas.HSP_ACCOUNT_ID
           AND hacc.LINE = commas.LINE

)



SELECT distinct  
		--HAR.PAT_ID AS 						PATIENT_ID,
		--,ISNULL(PT.PAT_MRN_ID,'') AS 					MRN
		 'FACILITY_ID'							= ISNULL(CONVERT(varchar(18),HAR.LOC_ID),'')
		,'ACCOUNT_NUMBER'						= HAR.HSP_ACCOUNT_ID
		,'SEQUENCE'								= CPT.LINE 
		,'CPT_CHARGE_CODE'						= CPT.CPT_CODE
		,'CPT_CODE_DESCRIPTION'					= ISNULL(EAP.PROC_NAME,'')
		,'MODIFIER1'							= ISNULL(MODS.CPTMOD1,'')
		,'MODIFIER2'							= ISNULL(MODS.CPTMOD2,'')
		,'MODIFIER3'							= ISNULL(MODS.CPTMOD3,'')
		,'REVENUE_CODE'							= ISNULL(RIGHT('0000' + CONVERT(VARCHAR(4),CPT.PX_REV_CODE_ID),4),'')
		,'SERVICE_DATE'							= ISNULL(CONVERT(CHAR(10),CPT.CPT_CODE_DATE,101),'')
		,'PERFORMING_DOCTOR_CODE'				= ISNULL(CPT.CPT_PERF_PROV_ID,'')
		,'PERFORMING_DOCTOR_NAME'				= ISNULL(SER.PROV_NAME,'')
		,'PERFORMING_DOCTOR_NPI'				= coalesce(ID.IDENTITY_ID,SER2.NPI,'')
		,'PERFORMING_DOCTOR_SPECIALTY'			= ISNULL(ZSPEC.TITLE,'')
		

		
		
FROM  CTE_ACCT_LIST TAL
INNER JOIN DBO.HSP_ACCOUNT AS HAR 
 
	ON har.HSP_ACCOUNT_ID = tal.hsp_account_id
INNER JOIN dbo.HSP_ACCT_CPT_CODES AS CPT 
	ON HAR.HSP_ACCOUNT_ID = CPT.HSP_ACCOUNT_ID 
LEFT JOIN dbo.CLARITY_EAP EAP 
	ON CPT.CPT_CODE = EAP.PROC_CODE		
LEFT JOIN cte_modifiers AS mods 
		ON cpt.hsp_account_id = mods.HSP_ACCOUNT_ID
			AND cpt.line = mods.LINE
INNER JOIN dbo.CLARITY_LOC AS LOC 
	ON HAR.LOC_ID = LOC.LOC_ID

INNER JOIN dbo.CLARITY_SER AS SER 
	ON CPT.CPT_PERF_PROV_ID = SER.PROV_ID
INNER JOIN dbo.CLARITY_SER_2 AS SER2 
	ON SER.PROV_ID = SER2.PROV_ID
LEFT JOIN dbo.IDENTITY_SER_ID AS ID 
	ON SER.PROV_ID = ID.PROV_ID
	AND ID.IDENTITY_TYPE_ID = 60
LEFT JOIN dbo.CLARITY_SER_SPEC AS PSPEC 
	ON SER.PROV_ID = PSPEC.PROV_ID 
	AND PSPEC.LINE = 1
LEFT JOIN dbo.ZC_SPECIALTY AS ZSPEC 
	ON PSPEC.SPECIALTY_C = ZSPEC.SPECIALTY_C
