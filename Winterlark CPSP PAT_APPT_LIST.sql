WITH 

--Dates for testing
START_DATE AS (SELECT to_date('2016-01-10 00:00:00', 'yyyy-mm-dd hh24:mi:ss') AS DTTM FROM DUAL)
,END_DATE AS (SELECT to_date('2021-01-26 23:59:59', 'yyyy-mm-dd hh24:mi:ss') AS DTTM FROM DUAL)
, 

--
-- Patient Employer Data - Exclude Medical Center employees from extract
--
CLARITY_EEP_FILTER
AS
(SELECT
	eep.EMPLOYER_ID
	,eep.EMPLOYER_NAME "EMPLOYER_NAME"
	,eep.ADDRESS1 "EMPLOYER_ADDRESS1"
	,eep.ADDRESS2 "EMPLOYER_ADDRESS2"
	,eep.CITY "EMPLOYER_CITY"
	,state.NAME "EMPLOYER_STATE"
	,eep.ZIP "EMPLOYER_ZIP"
	,eep.PHONE "EMPLOYER_PHONE"

FROM 
	CLARITY_EEP eep 
	LEFT JOIN  ZC_STATE state ON eep.STATE_C = state.STATE_C
			
WHERE
	(eep.ZIP <> '27109' AND eep.ZIP <> '27157') 
	AND (eep.PHONE NOT LIKE '336-758%' AND eep.PHONE NOT LIKE '336-713%' AND eep.PHONE NOT LIKE '336-716%')
   	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%Medical Center%')
   	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%BGSM%')
   	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%NCBH%')
   	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%Clinic%')
   	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('SM')   --Removed the %SM% because Smith is being excluded 
   	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%WFBH%')
   	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%WFBMC%')
   	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%WFUSM%') 
	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%FOREST BAPTIST%') 
   	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%WFU%')
   	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%WFUHS%')
   	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%WFUBMC%')
   	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%WFU SCHOOL%')
   	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%WAKE FOREST%')
   	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%Comp Rehab%') 
   	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%Community Physician%')
   	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%2240 Reynolda Road%')
   	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%Bowman Gray Tech Center R%')
   	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%NC Baptist Hospital%')
   	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%Wake Forest University%')
   	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%WFU Health Sciences%')
   	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%WFUBMC Community Physicians%')
	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%Lexington Medical Center%')
	AND upper(eep.EMPLOYER_NAME) NOT LIKE upper('%Davie Medical Center%')
   	AND upper(eep.ADDRESS1) NOT LIKE upper('%Medical Center%')
   	AND upper(eep.ADDRESS1) NOT LIKE upper('%BGSM%')
   	AND upper(eep.ADDRESS1) NOT LIKE upper('%NCBH%')
   	AND upper(eep.ADDRESS1) NOT LIKE upper('%Clinic%')
   	AND upper(eep.ADDRESS1) NOT LIKE upper('SM')   --Removed the %SM% because Smith is being excluded 
   	AND upper(eep.ADDRESS1) NOT LIKE upper('%WFBH%')
   	AND upper(eep.ADDRESS1) NOT LIKE upper('%WFBMC%')
   	AND upper(eep.ADDRESS1) NOT LIKE upper('%WFUSM%') 
   	AND upper(eep.ADDRESS1) NOT LIKE upper('%WFU%')
   	AND upper(eep.ADDRESS1) NOT LIKE upper('%WFUHS%')
   	AND upper(eep.ADDRESS1) NOT LIKE upper('%WFUBMC%')
   	AND upper(eep.ADDRESS1) NOT LIKE upper('%WFU SCHOOL%')
   	AND upper(eep.ADDRESS1) NOT LIKE upper('WAKE FOREST')  --Removed %, this would remove real addresses I.e. 1234 Wake Forest Blvd
	AND upper(eep.ADDRESS1) NOT LIKE upper('%FOREST BAPTIST%') 
   	AND upper(eep.ADDRESS1) NOT LIKE upper('%Comp Rehab%') 
   	AND upper(eep.ADDRESS1) NOT LIKE upper('%Community Physician%')
   	AND upper(eep.ADDRESS1) NOT LIKE upper('%2240 Reynolda Road%')
   	AND upper(eep.ADDRESS1) NOT LIKE upper('%Bowman Gray Tech Center R%')
   	AND upper(eep.ADDRESS1) NOT LIKE upper('%NC Baptist Hospital%')
   	AND upper(eep.ADDRESS1) NOT LIKE upper('%Wake Forest University%')
   	AND upper(eep.ADDRESS1) NOT LIKE upper('%WFU Health Sciences%')
   	AND upper(eep.ADDRESS1) NOT LIKE upper('%WFUBMC Community Physicians%')
         AND upper(eep.ADDRESS1) NOT LIKE upper('%Lexington Medical Center%')
         AND upper(eep.ADDRESS1) NOT LIKE upper('%Davie Medical Center%'))

--
-- Patient name and address
--

,PATIENT_META
AS
	(SELECT
		pat.PAT_ID
		,pat.PAT_MRN_ID "MRN Number"
		,pat.PAT_NAME "Patient Name"
		,title.NAME "Patient Title"
		,substr(upper(pat.PAT_FIRST_NAME),1,1) || substr(lower(pat.PAT_FIRST_NAME),2, length(pat.PAT_FIRST_NAME)) "Patient First Name"
		,substr(upper(pat.PAT_MIDDLE_NAME),1,1) || substr(lower(pat.PAT_MIDDLE_NAME),2, length(pat.PAT_MIDDLE_NAME)) "Patient Middle Name"
		,substr(upper(pat.PAT_LAST_NAME),1,1) || substr(lower(pat.PAT_LAST_NAME),2, length(pat.PAT_LAST_NAME))  "Patient Last Name"
		,suffix.NAME "Patient Suffix"
		,sex.NAME "Patient Gender"
		,pat.BIRTH_DATE "Patient DOB"
		,pat.ADD_LINE_1 "Patient Address Line 1"
		,pat.ADD_LINE_2 "Patient Address Line 2"
		,pat.CITY "Patient City"
		,state.ABBR "Patient State"
		,pat.ZIP "Patient Zip"
                                , zc_c.NAME "Patient County"
		,PAT.EMAIL_ADDRESS "Patient Email"
		,pat.HOME_PHONE "Patient Phone"
		,eep.EMPLOYER_NAME "Patient Employer"
		,eep.EMPLOYER_ADDRESS1 "Patient Employer Address 1"
		,eep.EMPLOYER_ADDRESS2 "Patient Employer Address 2"
		,eep.EMPLOYER_CITY "Patient Employer City"
		,eep.EMPLOYER_STATE "Patient Employer State"
		,eep.EMPLOYER_ZIP "Patient Employer Zip"
		,eep.EMPLOYER_PHONE "Patient Employer Phone"
	
	FROM
		PATIENT pat
		LEFT JOIN CLARITY_EEP_FILTER eep ON pat.EMPLOYER_ID = eep.EMPLOYER_ID
		LEFT JOIN  ZC_STATE state ON pat.STATE_C = state.STATE_C 
		LEFT JOIN  ZC_PAT_TITLE title ON pat.PAT_TITLE_C = title.PAT_TITLE_C
		LEFT JOIN  ZC_SEX sex ON pat.SEX_C = sex.RCPT_MEM_SEX_C 
		LEFT JOIN ZC_PAT_NAME_SUFFIX suffix ON pat.PAT_NAME_SUFFIX_C = suffix.PAT_NAME_SUFFIX_C
        LEFT OUTER JOIN ZC_COUNTY zc_c ON pat.COUNTY_C = zc_c.COUNTY_C
			
	WHERE
--      Exclude patients with any Psych related encounters, private/confidential encounters, or needs an interpreter.
		NOT EXISTS(SELECT
                        enc.PAT_ID
                    FROM
                        PAT_ENC enc
                            LEFT OUTER JOIN CLARITY_SER ser ON enc.VISIT_PROV_ID = ser.PROV_ID
                            LEFT OUTER JOIN CLARITY_SER_SPEC spec ON ser.PROV_ID = spec.PROV_ID
                            LEFT OUTER JOIN CLARITY_DEP dep ON enc.DEPARTMENT_ID = dep.DEPARTMENT_ID
                            LEFT OUTER JOIN CLARITY_LOC exloc ON dep.REV_LOC_ID = exloc.LOC_ID
                            LEFT OUTER JOIN PAT_ENC_5 enc_5 ON enc.PAT_ENC_CSN_ID = enc_5.PAT_ENC_CSN_ID
                    WHERE
                        pat.PAT_ID = enc.PAT_ID
                        -- Department Specialties
                        AND enc.DEPARTMENT_ID <> 1000103041
                        AND (dep.SPECIALTY IN ('Behavioral Health', 'Child and Adolescent Psychiatry', 'Counseling', 'Developmental and Behavioral Pediatrics'
                            , 'Pediatric Psychiatry', 'Pediatric Psychology', 'Psychiatry', 'Psychology')
                            OR UPPER(dep.DEPARTMENT_NAME) LIKE '%PSYC%'
                            -- Provider Specialties: BEHAVIORAL HEALTH, PSYCHIATRY, PSYCHOLOGY
                            OR spec.SPECIALTY_C IN ('75', '37', '38')
                            -- LPC - Licensed Professional Counselor at PP1 Family Medicine
                            OR (ser.PROV_TYPE LIKE 'Counselor%'
                                AND dep.SPECIALTY = 'Family Medicine')
                            -- Parent location = CareNet
                            OR exloc.HOSP_PARENT_LOC_ID = '100003'
                            -- Private/Confidential Encounter
                            OR enc_5.PVT_HOSP_ENC_C  IN (1,3,4,5,6)
                            -- Interpreter Needed
                            OR pat.INTRPTR_NEEDED_YN = 'Y'
                            )
--                        AND enc.DEPARTMENT_ID IN (1000104063,1000104066,1000116030,21501025,98101103,1002201002,1009801002,1009801003,
--							1009801004,1000104017,1005001005,1011101001,1000107004,1008301078,1008301084,1012301026,
--                                                                    1090000106,1090000208,1090000223)
                            )
--      Exclude Medicaid and WFBMC employees with Medcost
		AND NOT EXISTS(SELECT
							mem.PAT_ID
                        FROM
                            COVERAGE_MEM_LIST mem
                            INNER JOIN COVERAGE cov ON mem.COVERAGE_ID = cov.COVERAGE_ID
                        WHERE
                            pat.PAT_ID = mem.PAT_ID
                            AND ((cov.PAYOR_ID IN (200,201,202,203,204,205,206,207,209,290,994,998))
                                OR (cov.PAYOR_ID = 405 AND cov.PLAN_ID = 40501))
                            )
--      Exclude Dev Office - Opt Out of Fundraising
--      1/18/21 spb  Added 1- Anonymous, 2 - Confidential, 6 - Proisoner, 7 - High Profile/BTG per Greg McKnight.
		AND NOT EXISTS(SELECT
							pattype.PAT_ID
						FROM
							PATIENT_TYPE pattype
						WHERE
							pat.PAT_ID = pattype.PAT_ID AND pattype.PATIENT_TYPE_C IN (1,11, 2,6,7))
--      Exclude younger than 25
		AND floor(months_between(to_date(SYSDATE), pat.BIRTH_DATE) / 12) >= 26
--      Exclude deceased
		AND pat.PAT_STATUS_C <> 2 
--      Exclude patients with Medical Center addresses and phone numbers
		AND (pat.ZIP <> '27109' AND pat.ZIP <> '27157') 
		AND (pat.HOME_PHONE NOT LIKE '336-758%' AND pat.HOME_PHONE NOT LIKE '336-713%' AND pat.HOME_PHONE NOT LIKE '336-716%')
		AND upper(pat.PAT_NAME) NOT LIKE upper('%Medical Center%')
		AND upper(pat.PAT_NAME) NOT LIKE upper('%BGSM%')
		AND upper(pat.PAT_NAME) NOT LIKE upper('%NCBH%')
		AND upper(pat.PAT_NAME) NOT LIKE upper('%Clinic%')
		AND upper(pat.PAT_NAME) NOT LIKE upper('SM')   --Removed the %SM% because Smith is being excluded 
		AND upper(pat.PAT_NAME) NOT LIKE upper('%WFBH%')
		AND upper(pat.PAT_NAME) NOT LIKE upper('%WFBMC%')
		AND upper(pat.PAT_NAME) NOT LIKE upper('%WFUSM%') 
		AND upper(pat.PAT_NAME) NOT LIKE upper('%WFU%')
		AND upper(pat.PAT_NAME) NOT LIKE upper('%WFUHS%')
		AND upper(pat.PAT_NAME) NOT LIKE upper('%WFUBMC%')
		AND upper(pat.PAT_NAME) NOT LIKE upper('%WFU SCHOOL%')
		AND upper(pat.PAT_NAME) NOT LIKE upper('%WAKE FOREST%')
                                AND upper(pat.PAT_NAME) NOT LIKE upper('%FOREST BAPTIST%') 
		AND upper(pat.PAT_NAME) NOT LIKE upper('%Comp Rehab%') 
		AND upper(pat.PAT_NAME) NOT LIKE upper('%Community Physician%')
		AND upper(pat.PAT_NAME) NOT LIKE upper('%2240 Reynolda Road%')
		AND upper(pat.PAT_NAME) NOT LIKE upper('%Bowman Gray Tech Center R%')
		AND upper(pat.PAT_NAME) NOT LIKE upper('%NC Baptist Hospital%')
		AND upper(pat.PAT_NAME) NOT LIKE upper('%Wake Forest University%')
		AND upper(pat.PAT_NAME) NOT LIKE upper('%WFU Health Sciences%')
		AND upper(pat.PAT_NAME) NOT LIKE upper('%WFUBMC Community Physicians%')
		AND upper(pat.PAT_NAME) NOT LIKE upper('%Lexington Medical Center%')
		AND upper(pat.PAT_NAME) NOT LIKE upper('%Davie Medical Center%')
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('%Medical Center%')  -- Removed %, this would've remove 1234 Medical Center Blvd
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('%BGSM%')
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('%NCBH%')
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('%Clinic%')
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('SM')   --Removed the %SM% because Smith is being excluded 
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('%WFBH%')
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('%WFBMC%')
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('%WFUSM%') 
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('%WFU%')
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('%WFUHS%')
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('%WFUBMC%')
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('%WFU SCHOOL%')
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('WAKE FOREST')  --Removed %, this would remove real addresses I.e. 1234 Wake Forest Blvd
	                AND upper(pat.ADD_LINE_1) NOT LIKE upper('%FOREST BAPTIST%') 
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('%Comp Rehab%') 
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('%Community Physician%')
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('%2240 Reynolda Road%')
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('%Bowman Gray Tech Center R%')
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('%NC Baptist Hospital%')
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('%Wake Forest University%')
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('%WFU Health Sciences%')
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('%WFUBMC Community Physicians%')
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('%Lexington Medical Center%')
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('%Davie Medical Center%')
		AND upper(pat.ADD_LINE_1) NOT LIKE upper('%C/O%')
--      Exclude MRNs that begin with '<E'
                                AND pat.PAT_MRN_ID NOT LIKE '<E%'
    )

,VISIT_FILTER
AS
	(SELECT
	 	enc.PAT_ENC_CSN_ID

	FROM
	 	PAT_ENC enc
	 
	WHERE
		EXISTS (SELECT
					meta.PAT_ID
				FROM
					PATIENT_META meta
				WHERE
					enc.PAT_ID = meta.PAT_ID)
-- Added Arrived to Appt_Status_C
--	 		AND enc.APPT_STATUS_C = 2
        AND enc.DEPARTMENT_ID = 1000103041
--          Include completed (2) or arrived (6) appointment status
         AND enc.APPT_STATUS_C IN (2,6)
         AND enc.CHECKIN_TIME IS NOT NULL
         AND enc.CHECKOUT_TIME IS NOT NULL
--          Exclude inpatient as these patients will be chosen at discharge. Exclude lab visits, nurse only, clinical support, appointment, infusion,
--              anti-coag visit.
--          AND enc.ENC_TYPE_C NOT IN (1001, 3, 50, 2101, 2508, 201, 210527)
-- Changing date parameters to string from datetime; part of removing subreport from empty main report to get rid of blank first row
-- in output for Jewel Watts.

--          AND enc.CONTACT_DATE >=  EPIC_UTIL.EFN_DIN('{?SubStartDate}')
--          AND enc.CONTACT_DATE <  EPIC_UTIL.EFN_DIN('{?SubEndDate}') + 1
--Dates for testing
          AND enc.CONTACT_DATE BETWEEN (SELECT DTTM FROM START_DATE) AND (SELECT DTTM FROM END_DATE)
	 
--	 UNION
--	 
--	 SELECT
--	 	hsp.PAT_ENC_CSN_ID
--	 	
--	 FROM
--	 	PAT_ENC_HSP hsp
--	 
--	 WHERE
--	 		EXISTS (SELECT
--						meta.PAT_ID
--					FROM
--						PATIENT_META meta
--					WHERE
--						hsp.PAT_ID = meta.PAT_ID)
---- Per Greg McKnight, removed the exclusion of ICU encounters
------          Exclude ICU encounters
----			AND hsp.DEPARTMENT_ID NOT IN (1090101017,1008301003,1000102030,1000102023,1000103036,1000105005,1000105006,1000105007,1000105008,
----				1000105009,1000105010,1000105024,1000106013,1090000018)
--
----          Exclude patients discharged to assisted living, another hospital, court/law enforcement, psych, long-term care, skilled nursing, 
----              and left against medical advice.
----          1/18/21 spb  Removed 3 - Skilled Nursing, 213 - SNF with Planned Readmit; added 50 - Hospice/Home, 51 - Hospice/Medical facility,
----              210 - Hospice in Place per Greg McKnight.
--            AND (hsp.DISCH_DISP_C NOT IN (10,204,205,21,217,222,63,64,65,67,7,50,51,210)
---- Added line to include NULL Discharge codes
--                OR hsp.DISCH_DISP_C  IS NULL)
----          Exclude Inpatient Psych and Outpatient Psych
--            AND hsp.ADT_PAT_CLASS_C NOT IN (135,152)
----          Exclude Psych Service
--            AND hsp.HOSP_SERV_C NOT IN (122,181,182)
----          Exclude Private Hospital Encounters
--            AND hsp.PVT_HSP_ENC_C  NOT IN (1,3,4,5,6)
--
--
---- Changing date parameters to string from datetime; part of removing subreport from empty main report to get rid of blank first row
---- in output for Jewel Watts.
--
----			AND hsp.HOSP_DISCH_TIME >=  EPIC_UTIL.EFN_DIN('{?SubStartDate}')
----			AND hsp.HOSP_DISCH_TIME <  EPIC_UTIL.EFN_DIN('{?SubEndDate}') + 1)
--
--
----Dates for testing
--          AND hsp.HOSP_DISCH_TIME BETWEEN (SELECT DTTM FROM START_DATE) AND (SELECT DTTM FROM END_DATE)
)


,VISIT_META
AS
	(SELECT
		row_number() OVER (PARTITION BY enc.PAT_ID ORDER BY enc.CONTACT_DATE DESC) "SEQ_NUM"
		,pat.*
		,acct.ACCOUNT_NAME "Guarantor Name"
		,NULL "Guarantor Title"
		,CASE WHEN REPLACE(trim(SUBSTR(account_name,instr(account_name,',')+1 )),' ','') = trim(SUBSTR(account_name,instr(account_name,',')+1)) 
		 		THEN trim(SUBSTR(account_name,instr(account_name,',') +1)) 
		        ELSE SUBSTR(trim(SUBSTR(account_name,instr(account_name,',') +1)),1, instr(trim(SUBSTR(account_name,instr(account_name,',')+1)) ,' ',1)) 
		END "Guarantor First Name"
	 	,CASE WHEN REPLACE(trim(SUBSTR(account_name,instr(account_name,',')+1 )),' ','') = trim(SUBSTR(account_name,instr(account_name,',')+1)) 
	 	 		THEN NULL 
	          	ELSE SUBSTR(trim(SUBSTR(account_name,instr(account_name,',')+1) ), instr(trim(SUBSTR(account_name,instr(account_name,',')+1)) ,' ')+1) 
		END "Guarantor Middle Name"
		,trim(SUBSTR(account_name,1,instr(account_name,',')-1)) "Guarantor Last Name"
		,NULL "Guarantor Suffix"
		,acct.BILLING_ADDRESS_1 "Guarantor Address Line 1"
		,acct.BILLING_ADDRESS_2 "Guarantor Address Line 2"
		,acct.CITY "Guarantor City"
		,acct.NAME "Guarantor State"
		,acct.ZIP "Guarantor Zip"
		,acct.HOME_PHONE "Guarantor Phone"
		,eep.EMPLOYER_NAME "Guarantor Employer"
		,eep.EMPLOYER_ADDRESS1 "Guarantor Employer Address 1"
		,eep.EMPLOYER_ADDRESS2 "Guarantor Employer Address 2"
		,eep.EMPLOYER_CITY "Guarantor Employer City"
		,eep.EMPLOYER_STATE "Guarantor Employer State"
		,eep.EMPLOYER_ZIP "Guarantor Employer Zip"
		,eep.EMPLOYER_PHONE "Guarantor Employer Phone"
		,count(enc.PAT_ENC_CSN_ID) OVER (PARTITION BY enc.PAT_ID) "Patient CSN Count"
		,enc.APPT_TIME "Appointment Date/Time"
                   ,visitser.PROV_ID "Appointment Provider ID" 
		,visitser.PROV_NAME "Appointment Provider"
                   ,visitser.PROV_TYPE "Appointment Provider Type"
		,apptdep.DEPARTMENT_NAME "Appointment Department"
		, apptdep.SPECIALTY "Appointment Dept Specialty"
		,apptloc2.LOC_NAME "Appointment Parent Location"
                                ,hsp.HOSP_DISCH_TIME "Discharge Date/Time"
                   ,hspser.PROV_ID "Inpatient Provider ID"
		,hspser.PROV_NAME "Inpatient Provider"
                   ,hspser.PROV_TYPE "Inpatient Provider Type"
		,hspdep.DEPARTMENT_NAME "Inpatient Department"
		, hspdep.SPECIALTY "Inpatient Department Specialty"
        , zc_prim.NAME "Inpatient Primary Service Name"
		,hsploc2.LOC_NAME "Inpatient Parent Location"
                   ,apptdep.DEPARTMENT_ID "Appointment Department ID"
                   ,hspdep.DEPARTMENT_ID "Inpatient Department ID"
--
-- Added to get Self Pay and Bad Debt info for Greg
--
        , hspacct.ACCT_FIN_CLASS_C "Financial Class"

       ,(CASE
            WHEN hspacct.ACCT_FIN_CLASS_C = 4
                THEN 'YES'
                ELSE 'no'
            END) AS "Self-Pay?"
        , acct.HB_BADDEBT_BALANCE
        , acct.BAD_DEBT_BALANCE
        , acct."Bad Debt Total"
--     

	
	FROM
		PAT_ENC enc
		INNER JOIN PATIENT_META pat ON enc.PAT_ID = pat.PAT_ID
		LEFT JOIN CLARITY_DEP apptdep ON enc.DEPARTMENT_ID = apptdep.DEPARTMENT_ID 
                        AND (enc.APPT_STATUS_C = 2 OR enc.APPT_STATUS_C = 6)
		LEFT JOIN CLARITY_SER visitser ON enc.VISIT_PROV_ID = visitser.PROV_ID
		LEFT JOIN HSP_ACCOUNT hspacct ON enc.HSP_ACCOUNT_ID = hspacct.HSP_ACCOUNT_ID
		LEFT JOIN PAT_ENC_HSP hsp ON enc.PAT_ENC_CSN_ID = hsp.PAT_ENC_CSN_ID
		LEFT JOIN CLARITY_DEP hspdep ON hsp.DEPARTMENT_ID = hspdep.DEPARTMENT_ID 
                        AND hsp.HOSP_DISCH_TIME IS NOT NULL
		LEFT JOIN CLARITY_SER hspser ON coalesce(hsp.BILL_ATTEND_PROV_ID, hsp.ADMISSION_PROV_ID, DISCHARGE_PROV_ID) = hspser.PROV_ID
                   LEFT OUTER JOIN CLARITY_LOC apptloc ON apptdep.REV_LOC_ID = apptloc.LOC_ID
                   LEFT OUTER JOIN CLARITY_LOC apptloc2 ON apptloc.HOSP_PARENT_LOC_ID = apptloc2.LOC_ID
                   LEFT OUTER JOIN CLARITY_LOC hsploc ON hspdep.REV_LOC_ID = hsploc.LOC_ID
                   LEFT OUTER JOIN CLARITY_LOC hsploc2 ON hsploc.HOSP_PARENT_LOC_ID = hsploc2.LOC_ID
                   LEFT OUTER JOIN ZC_PRIM_SVC_HA zc_prim ON hspacct.PRIM_SVC_HA_C = zc_prim.PRIM_SVC_HA_C
--Changed  next line from INNER JOIN to LEFT JOIN
		LEFT JOIN (SELECT
						acct.ACCOUNT_ID
						,acct.ACCOUNT_NAME
						,acct.BILLING_ADDRESS_1
						,acct.BILLING_ADDRESS_2 
					 	,acct.CITY 
						,state.NAME 
						,acct.ZIP 
						,acct.HOME_PHONE
						,acct.EMPLOYER_ID
--
-- Added to get Self Pay and Bad Debt info for Greg
--
                        , acct.HB_BADDEBT_BALANCE
                        , acct.BAD_DEBT_BALANCE
                         , SUM(acct.HB_BADDEBT_BALANCE + acct.BAD_DEBT_BALANCE) AS "Bad Debt Total"
					FROM
						ACCOUNT acct
						LEFT JOIN ZC_STATE state ON acct.STATE_C = state.STATE_C
					WHERE
						(acct.ZIP <> '27109' AND acct.ZIP <> '27157') 
						AND (acct.HOME_PHONE NOT LIKE '336-758%' AND acct.HOME_PHONE NOT LIKE '336-713%' AND acct.HOME_PHONE NOT LIKE '336-716%')
--
-- Removed the following because: 1. couldn't determine the purpose of it and 2. it was causing pts that should be included to be excluded.
--
--						AND NOT EXISTS(SELECT
--									 		1
--										 FROM
--										 	CLARITY_EEP_FILTER eep
--										 WHERE
--									 		eep.EMPLOYER_ID = acct.EMPLOYER_ID)
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('%Medical Center%')  -- Removed %, this would've remove 
--												1234 Medical Center Blvd
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('%BGSM%')
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('%NCBH%')
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('%Clinic%')
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('SM')   --Removed the %SM% because Smith is being excluded 
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('%WFBH%')
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('%WFBMC%')
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('%WFUSM%') 
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('%WFU%')
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('%WFUHS%')
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('%WFUBMC%')
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('%WFU SCHOOL%')
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('WAKE FOREST')  --Removed %, this would remove real addresses 
--												I.e. 1234 Wake Forest Blvd
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('%FOREST BAPTIST%') 
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('%Comp Rehab%') 
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('%Community Physician%')
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('%2240 Reynolda Road%')
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('%Bowman Gray Tech Center R%')
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('%NC Baptist Hospital%')
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('%Wake Forest University%')
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('%WFU Health Sciences%')
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('%WFUBMC Community Physicians%')
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('%Lexington Medical Center%')
											AND upper(acct.ACCOUNT_NAME) NOT LIKE upper('%Davie Medical Center%')
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%Medical Center%')  -- Removed %, this would've remove 
--												1234 Medical Center Blvd
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%BGSM%')
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%NCBH%')
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%Clinic%')
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('SM')   --Removed the %SM% because Smith is being excluded 
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%WFBH%')
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%WFBMC%')
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%WFUSM%') 
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%WFU%')
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%WFUHS%')
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%WFUBMC%')
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%WFU SCHOOL%')
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('WAKE FOREST')  --Removed %, this would remove real addresses 
--												I.e. 1234 Wake Forest Blvd
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%FOREST BAPTIST%') 
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%Comp Rehab%') 
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%Community Physician%')
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%2240 Reynolda Road%')
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%Bowman Gray Tech Center R%')
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%NC Baptist Hospital%')
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%Wake Forest University%')
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%WFU Health Sciences%')
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%WFUBMC Community Physicians%')
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%Lexington Medical Center%')
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%Davie Medical Center%')
											AND upper(acct.BILLING_ADDRESS_1) NOT LIKE upper('%C/O%')
--
-- Added to get Self Pay and Bad Debt info for Greg
--
                        GROUP BY
                            acct.ACCOUNT_ID
                            ,acct.ACCOUNT_NAME
                            ,acct.BILLING_ADDRESS_1
                            ,acct.BILLING_ADDRESS_2 
                            ,acct.CITY 
                            ,state.NAME 
                            ,acct.ZIP 
                            ,acct.HOME_PHONE
                            ,acct.EMPLOYER_ID
                            , acct.HB_BADDEBT_BALANCE
                            , acct.BAD_DEBT_BALANCE
--									
) acct ON enc.ACCOUNT_ID = acct.ACCOUNT_ID
		LEFT JOIN CLARITY_EEP_FILTER eep ON acct.EMPLOYER_ID = eep.EMPLOYER_ID
		
		WHERE
			EXISTS (SELECT
						visit.PAT_ENC_CSN_ID
					FROM
						VISIT_FILTER visit
					WHERE
						enc.PAT_ENC_CSN_ID = visit.PAT_ENC_CSN_ID))

SELECT
	*

FROM
	VISIT_META

WHERE
	VISIT_META.SEQ_NUM = 1
            AND ("Appointment Provider ID" IS NULL 
                OR NOT REGEXP_LIKE ( "Appointment Provider ID" , '[A-Z a-z]'))
            AND ("Inpatient Provider ID" IS NULL 
                OR NOT REGEXP_LIKE ("Inpatient Provider ID", '[A-Z a-z]'))
            AND "Patient Name" NOT LIKE 'ZZZ%'
            AND (VISIT_META.HB_BADDEBT_BALANCE IS NULL
                OR VISIT_META.HB_BADDEBT_BALANCE = 0)
            AND (VISIT_META.BAD_DEBT_BALANCE IS NULL
                OR VISIT_META.BAD_DEBT_BALANCE = 0)


 