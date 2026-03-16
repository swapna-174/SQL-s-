/********************************************************************************************************
Runtime: ~3 mins
Text output:
1) Tools--> Options --> Query Results --> Sql Server --> Results to Text.
2) Change output format to Custom Delimited and put pipe in delimiter box.
3) In query select Query --> Results to File. Execute query, supply filename, change extension to .txt.

8/16/21 LDO - For admit dept exclude Cancelled event subtype
10/26/21 LDO - Added patient first and last name per Courtney Schaefer
1/24/22 LDO - Requested change: Add a column to represent a supplemental manually created 
facilityCodeEMR value, intended to represent whether a given record was discharged before or 
after the corresponding facility’s Epic Go Live Date.  Per Payton Argaez.
********************************************************************************************************/
SET NOCOUNT ON
SET ANSI_WARNINGS OFF

DECLARE @STARTDATECD date = EPIC_UTIL.EFN_DIN('T-50')
	,@ENDDATECD date =  EPIC_UTIL.EFN_DIN('T-1')

IF OBJECT_ID('TempDB..##TMP_RevintBucket') IS NOT NULL DROP TABLE ##TMP_RevintBucket
IF OBJECT_ID('TempDB..##TMP_RevintCVG') IS NOT NULL DROP TABLE ##TMP_RevintCVG
IF OBJECT_ID('TempDB..##TMP_RevintAccount') IS NOT NULL DROP TABLE ##TMP_RevintAccount

/*****************************************************************************************
Create CTE of account numbers based on last updated date within the date range, or which
have transactions posted in the transactions within the date range.
******************************************************************************************/

--;With cteRevintAccount as (
SELECT 	'EPIC' AS 'SOURCE_SYSTEM'
			,HAR.HSP_ACCOUNT_ID
			,Cast(ISNULL(HAR.DISCH_DATE_TIME,PEH.HOSP_DISCH_TIME) as date) 'DISCHG_DATE'  --2/24/22
		INTO ##TMP_RevintAccount
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
--)

SELECT  bkt.HSP_ACCOUNT_ID
        ,MAX(bkt.LAST_CLM_INV_NUM) AS LAST_CLM_INV_NUM
        ,MAX(bkt.FIRST_CLAIM_DATE) AS FIRST_CLAIM_DATE
        ,MAX(bkt.FST_EXT_CLM_SENT_DT) AS FST_EXT_CLM_SENT_DT
        ,MAX(bkt.EXT_CLAIM_SENT_DT) AS EXT_CLAIM_SENT_DT
        ,MAX(bkt.LAST_CLAIM_DATE) AS LAST_CLAIM_DATE
INTO    ##TMP_RevintBucket
FROM    HSP_BUCKET bkt
INNER JOIN ##TMP_RevintAccount TAL
        ON bkt.HSP_ACCOUNT_ID = TAL.HSP_ACCOUNT_ID
WHERE   bkt.BKT_TYPE_HA_C = 2 --- PRIMARY BUCKET 
GROUP BY bkt.HSP_ACCOUNT_ID

--- INDEX THE TEMP TABLE
CREATE UNIQUE NONCLUSTERED INDEX IDX_CSN ON ##TMP_RevintBucket(HSP_ACCOUNT_ID)
   INCLUDE(LAST_CLM_INV_NUM,FIRST_CLAIM_DATE,FST_EXT_CLM_SENT_DT,EXT_CLAIM_SENT_DT)

/************************************************************************************************************
CREATION OF COVERAGE TEMP TABLE - to get one record per account and up to 3 payors and plans
***************************************************************************************************************/
SELECT  HALU.HSP_ACCOUNT_ID
        ,MAX(CASE WHEN HCVG.LINE = 1 THEN FC.FINANCIAL_CLASS_NAME
            END) AS PRIM_FIN_CLASS
        ,MAX(CASE WHEN HCVG.LINE = 1 THEN EPM.PAYOR_ID
            END) AS PRIM_PAYOR_ID
        ,MAX(CASE WHEN HCVG.LINE = 1 THEN ISNULL(EPM.PAYOR_NAME,'')
            END) AS PRIM_PAYOR_NAME
        ,MAX(CASE WHEN HCVG.LINE = 1 THEN EPP.BENEFIT_PLAN_ID
            END) AS PRIM_PLAN_ID
        ,MAX(CASE WHEN HCVG.LINE = 1 THEN ISNULL(EPP.BENEFIT_PLAN_NAME,'')
            END) AS PRIM_PLAN_NAME
INTO    ##TMP_RevintCVG
FROM    ##TMP_RevintAccount AS HALU --- JUST USE SCOPED ACCOUNTS
INNER JOIN HSP_ACCT_CVG_LIST AS HCVG
        ON HALU.HSP_ACCOUNT_ID = HCVG.HSP_ACCOUNT_ID
LEFT JOIN COVERAGE AS CVG
        ON HCVG.COVERAGE_ID = CVG.COVERAGE_ID
LEFT JOIN CLARITY_EPM AS EPM
        ON CVG.PAYOR_ID = EPM.PAYOR_ID
LEFT JOIN CLARITY_EPP AS EPP
        ON EPP.BENEFIT_PLAN_ID = CVG.PLAN_ID
LEFT JOIN CLARITY_FC AS FC
        ON EPM.FINANCIAL_CLASS = FC.FINANCIAL_CLASS
WHERE   HCVG.LINE IN (1,2,3)
GROUP BY HALU.HSP_ACCOUNT_ID
  
CREATE INDEX IDX_COVERAGE ON ##TMP_RevintCVG(HSP_ACCOUNT_ID) 
INCLUDE(PRIM_FIN_CLASS,PRIM_PAYOR_ID,PRIM_PAYOR_NAME,PRIM_PLAN_ID,PRIM_PLAN_NAME) --,SEC_FIN_CLASS,SEC_PAYOR_ID,SEC_PAYOR_NAME
--,SEC_PLAN_ID, SEC_PLAN_NAME,TERT_FIN_CLASS,TERT_PAYOR_ID,TERT_PAYOR_NAME,TERT_PLAN_ID,TERT_PLAN_NAME)  


--LDO 9/26/18 - Get AH MRN
;with cteMRN as
(Select  pat.PAT_ID	   
       , i.IDENTITY_ID  AHMRN
     From PATIENT pat
       Left outer join IDENTITY_ID i		on pat.PAT_id = i.PAT_ID 
       Left outer join IDENTITY_ID_TYPE t	on i.IDENTITY_TYPE_ID = t.ID_TYPE
     Where t.ID_TYPE = 14 --AHMRN
)

 /*********************************************************************************************************************
 MAIN CODE TO PULL DATA 
 *********************************************************************************************************************/
SELECT  DISTINCT
		--HAR.HSP_ACCOUNT_ID AS 'VisitNumber'	
		Concat(vals.EXT_VALUE, HAR.HSP_ACCOUNT_ID)  'VisitNumber'

        ,ISNULL(CONVERT(VARCHAR(18),HOSP.LOC_ID),'')  'FacilityID'
        ,ISNULL(HOSP.LOC_NAME,'')  'FacilityName'
        
		--,ISNULL(PT.PAT_MRN_ID,'')  'MRN'	--LDO 9/26/18
		,ISNULL(cteMRN.AHMRN,'')  'MRN'		--LDO 9/26/18
		
		--,ISNULL(CONVERT(VARCHAR(10),ISNULL(HAR.ADM_DATE_TIME,PEH.HOSP_ADMSN_TIME),101),'')  'AdmitDate'		  --LDO 9/26/18
		,Concat(CONVERT(nvarchar,ISNULL(HAR.ADM_DATE_TIME,PEH.HOSP_ADMSN_TIME),101), ' ',						  --LDO 9/26/18
			convert(nvarchar,CAST(ISNULL(HAR.ADM_DATE_TIME,PEH.HOSP_ADMSN_TIME) as time),100))	'AdmitDateTime'   --LDO 9/26/18
		
		,ISNULL(admdep.DEPARTMENT_NAME,'')					'AdmitDepartment'		--LDO 10/4/18

        --,ISNULL(CONVERT(VARCHAR(30),ISNULL(HAR.DISCH_DATE_TIME,PEH.HOSP_DISCH_TIME),101),'')  'DischargeDate' ---FOR SERIES ACCOUNTS THIS WILL BE LAST APPT DISCH 9/26/18
		,Concat(CONVERT(nvarchar,ISNULL(HAR.DISCH_DATE_TIME,PEH.HOSP_DISCH_TIME),101), ' ',							  --LDO 9/26/18
			convert(nvarchar,CAST(ISNULL(HAR.DISCH_DATE_TIME,PEH.HOSP_DISCH_TIME) as time),100))	'DischargeDate'   --LDO 9/26/18

		,ISNULL(dischdep.DEPARTMENT_NAME,'')				'DischargeDepartment'	--LDO 10/4/18

        ,ISNULL(SEX.ABBR,'')  'Gender'
        ,ISNULL(CONVERT(VARCHAR(10),PT.BIRTH_DATE,101),'')  'DOB'
		,ISNULL(PEH.DISCH_DISP_C,'')  'DischargeDispositionCode'
        ,ISNULL(ZDISP.NAME,'')  'DischargeDispositionName'
        ,ISNULL(CONVERT(VARCHAR(10),HAR.ACCT_BASECLS_HA_C),'')  'PatientClassCode'
        ,ISNULL(ZBC.NAME,'')  'PatientClassName'
        ,ISNULL(HAR.ACCT_CLASS_HA_C,'')  'PatientTypeCode'
        ,ISNULL(ZPC.NAME,'')  'PatientTypeName'
        ,ISNULL(CONVERT(VARCHAR(18),HAR.ACCT_BILLSTS_HA_C),'')  'BillStatusCode'
        ,ISNULL(zbs.NAME,'')  'BillStatusName'
        ,ISNULL(CONVERT(VARCHAR(10),HAR.CODING_STATUS_C),'')  'CodingStatusCode'
        ,ISNULL(ZCS.NAME,'')  'CodingStatusName' 
        
		--,ISNULL(HAR.ADMISSION_SOURCE_C,'') 	'AdmitSource'		--LDO 10/4/18
		,ISNULL(cev2.ADMSN_SRC,'')				'AdmitSource'		--LDO 10/4/18

        --,ISNULL(zsrc.NAME,'')  'AdmitSourceName'
        ,ISNULL(HAR.ADMISSION_TYPE_C,'')  'AdmitType'
        --,ISNULL(zaty.NAME,'')  'AdmitTypeName'
--- COORDINATION of BENDFIRT INFORMATION 
        ,ISNULL(CONVERT(VARCHAR(18),CVG.PRIM_FIN_CLASS),'')  'PrimaryPayerFinancialClass'
        ,ISNULL(CONVERT(VARCHAR(18),CVG.PRIM_PAYOR_ID),'')  'PrimaryPayerCategoryId'
        ,ISNULL(CVG.PRIM_PAYOR_NAME,'')  'PrimaryPayerCategoryName'
        ,ISNULL(CONVERT(VARCHAR(18),CVG.PRIM_PLAN_ID),'')  'PrimaryPayerPlanId'
        ,ISNULL(CVG.PRIM_PLAN_NAME,'')  'PrimaryPayerPlanName'          
--- ATTENDING PHYSICIAN INFO
        ,ISNULL(CONVERT(VARCHAR(18),ATSER.PROV_ID),'')  'PhysicianAttendingNPI'
        ,ISNULL(ATSER.PROV_NAME,'')  'PhysicianAttendingName'
--- DRG INFO
		,ISNULL(HAR.Abstract_user_id, '')  'FinalCoder'
        ,ISNULL(DRGS.DRG_MPI_CODE,'')  'DRGCodeBilled'
        ,ISNULL(DRGID.ID_TYPE_NAME,'')  'DRGType'
        ,ISNULL(CDRG.DRG_NAME,'')  'DRGNameBilled'
		,CASE
			WHEN HAR.ACCT_BASECLS_HA_C = 1 
				THEN isnull(convert(varchar,HAR.BILL_DRG_PS),'')
            ELSE ''
        END AS 'SOI'
        ,ISNULL (CONVERT(VARCHAR(10),har.BILL_DRG_ROM), '')	 'ROM'
--- BALANCE INFORMATION
        ,ISNULL(CONVERT(VARCHAR(18),HAR.TOT_ACCT_BAL),'')  'AccountBalance' 
        ,ISNULL(CONVERT(VARCHAR(18),HAR.TOT_CHGS),'')  'TotalCharges'
        ,ISNULL(CONVERT(VARCHAR(18),HAR.TOT_PMTS),'')  'TotalPayments'
        ,ISNULL(CONVERT(VARCHAR(18),HAR.TOT_ADJ),'')  'TotalAdjustments'
--- Bill Dates
        ,ISNULL(CONVERT(VARCHAR(10),BKT.FIRST_CLAIM_DATE,101),'')  'BillDateOriginal'
        ,ISNULL(CONVERT(VARCHAR(10),BKT.LAST_CLAIM_DATE,101),'')  'BillDateMostRecent'
 ,har.PRIM_ENC_CSN_ID  
 ,pt.PAT_FIRST_NAME	'PatientFirstName'		--LDO 10/26/21
 ,pt.PAT_LAST_NAME	'PatientLastName'		--LDO 10/26/21

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

    FROM    HSP_ACCOUNT AS HAR
    INNER JOIN ##TMP_RevintAccount TAL
            ON HAR.HSP_ACCOUNT_ID = TAL.HSP_ACCOUNT_ID
    LEFT JOIN PATIENT AS PT
            ON HAR.PAT_ID = PT.PAT_ID

--- USE PREVIOUSLY DERIVED CTE FOR COVERAGE INFORMATION FOR ACCOUNT
    LEFT JOIN ##TMP_RevintCVG AS CVG
            ON HAR.HSP_ACCOUNT_ID = CVG.HSP_ACCOUNT_ID

--- CATEGORY TABLES FOR ACCOUNT AND PATIENT LEVEL CODES
    LEFT JOIN ZC_ACCT_BASECLS_HA AS ZBC
            ON HAR.ACCT_BASECLS_HA_C = ZBC.ACCT_BASECLS_HA_C
    LEFT JOIN ZC_ACCT_CLASS_HA AS ZPC
            ON HAR.ACCT_CLASS_HA_C = ZPC.ACCT_CLASS_HA_C
    LEFT JOIN ZC_ACCT_BILLSTS_HA AS zbs
            ON HAR.ACCT_BILLSTS_HA_C = zbs.ACCT_BILLSTS_HA_C
    LEFT JOIN ZC_CODING_STS_HA AS ZCS
            ON HAR.CODING_STATUS_C = ZCS.CODING_STATUS_C
    LEFT JOIN ZC_SEX AS SEX
            ON PT.SEX_C = SEX.RCPT_MEM_SEX_C
    
	--LDO changes 9/26/18
	--LEFT JOIN ZC_ADM_SOURCE AS zsrc
    --        ON HAR.ADMISSION_SOURCE_C = zsrc.ADMIT_SOURCE_C
    LEFT JOIN ZC_MC_ADM_SOURCE AS zsrc
            ON HAR.ADMISSION_SOURCE_C = zsrc.ADMISSION_SOURCE_C
	--end

    LEFT JOIN ZC_ER_ADMIT_TYP_HA AS zaty
            ON HAR.ADMISSION_TYPE_C = zaty.ER_ADMIT_TYP_HA_C

--- CLAIM INFO
    LEFT JOIN ##TMP_RevintBucket AS BKT
            ON HAR.HSP_ACCOUNT_ID = BKT.HSP_ACCOUNT_ID 

--- Claim Values (LDO 4/10/18)
	Left outer join CLM_VALUES cev on BKT.LAST_CLM_INV_NUM = cev.INV_NUM
	inner join CLM_VALUES_2 cev2   on cev.RECORD_ID = cev2.RECORD_ID

--- ENCOUNTER DATA. USING ONLY HOSPITAL ENCOUNTERS, NOT PAT_ENC, TO REDUCE DATA SET
    LEFT JOIN PAT_ENC_HSP PEH
            ON HAR.HSP_ACCOUNT_ID = PEH.HSP_ACCOUNT_ID
            AND HAR.PRIM_ENC_CSN_ID = PEH.PAT_ENC_CSN_ID

--- ENCOUNTER LEVEL CATEGORY TABLES
    LEFT JOIN ZC_DISCH_DISP AS ZDISP
            ON PEH.DISCH_DISP_C = ZDISP.DISCH_DISP_C

    LEFT JOIN CLARITY_LOC AS HOSP
            ON HAR.LOC_ID = HOSP.LOC_ID

--- ENCOUNTER ADMITTING, ATTENDING
    LEFT JOIN CLARITY_SER ATSER
            ON ISNULL(HAR.ATTENDING_PROV_ID,PEH.BILL_ATTEND_PROV_ID) = ATSER.PROV_ID

-----GET DRG INFORMATION
    LEFT JOIN HSP_ACCT_MULT_DRGS AS DRGS
            ON HAR.HSP_ACCOUNT_ID = DRGS.HSP_ACCOUNT_ID
               AND DRGS.DRG_BILLING_FLAG_YN = 'Y'	--- MUST BE THE BILLING DRG, WHETHER MS OR APR
    LEFT JOIN IDENTITY_ID_TYPE AS DRGID
            ON DRGS.DRG_ID_TYPE_ID = DRGID.ID_TYPE
    LEFT JOIN CLARITY_DRG AS CDRG
            ON HAR.FINAL_DRG_ID = CDRG.DRG_ID

--Join to get MRN - LDO - 9/26/18
left outer join cteMRN						on PT.PAT_ID = cteMRN.PAT_ID

--LDO 10/4/18 - get admit department
left outer join CLARITY_ADT adt				on har.PRIM_ENC_CSN_ID = adt.PAT_ENC_CSN_ID 
	and adt.EVENT_TYPE_C = 1		 
	and adt.EVENT_SUBTYPE_C <> 2 --Exclude Cancelled subtype 8/16/21 LDO											
left outer join CLARITY_DEP admdep			on adt.DEPARTMENT_ID = admdep.DEPARTMENT_ID

--LDO 10/4/18 - get discharge department
Left outer join CLARITY_DEP dischdep		on har.DISCH_DEPT_ID = dischdep.DEPARTMENT_ID

--Get Facility letter 10/25/18; Table_ID 1080050 is HB Legacy Fac Indicator Table
Left outer join INTERFACE_TBL_VALS vals on HAR.LOC_ID = vals.INT_VALUE and vals.TABLE_ID = 1080050

--order by 1

IF OBJECT_ID('TempDB..##TMP_RevintBucket') IS NOT NULL DROP TABLE ##TMP_RevintBucket
IF OBJECT_ID('TempDB..##TMP_RevintCVG') IS NOT NULL DROP TABLE ##TMP_RevintCVG
IF OBJECT_ID('TempDB..##TMP_RevintAccount') IS NOT NULL DROP TABLE ##TMP_RevintAccount