with MYPARAMS as 
	(
	select Trunc(EPIC_UTIL.EFN_DIN('01-JAN-2021')) as START_DATE,
		Trunc(EPIC_UTIL.EFN_DIN('09-MAR-2021')) as REPORT_BEGIN_DATE,
		Trunc(EPIC_UTIL.EFN_DIN('T')) as END_DATE 
	from DUAL
	), IMM_DAT as 
	(
	select distinct IMMUNE.PAT_ID,
		IMMUNE.IMM_HISTORIC_ADM_YN,
		Coalesce(IMMUNE.IMM_CSN, ORDER_PROC.PAT_ENC_CSN_ID) PAT_ENC_CSN_ID,
		ORDER_PROC.ORDER_PROC_ID,
		'Wake Forest Baptist Health' org_name,
		'Wake Forest Baptist Medical Center' admin_name,
		'34C001' vtrcks_prov_pin,
		case 
				when RX_NDC.RAW_11_DIGIT_NDC is not NULL then SubStr(RX_NDC.RAW_11_DIGIT_NDC, 1, 5) || '-' || SubStr(RX_NDC.RAW_11_DIGIT_NDC, 6, 4) || '-' || SubStr(RX_NDC.RAW_11_DIGIT_NDC, 10, 2) 
			end NDC,
		Cast(IMMUNE.IMMUNE_DATE as Date) IMMUNE_DATE,
		IMMUNE.IMMUNE_ID vax_event_id,
		ROW_NUMBER() 
	over 
		(
		partition by IMMUNE.PAT_ID 
		order by IMMUNE.PAT_ID, IMMUNE.IMMUNE_ID
		) dose_num, ROW_NUMBER() 
	over 
		(
		partition by IMMUNE.PAT_ID 
		order by IMMUNE.PAT_ID, IMMUNE.IMMUNE_ID Desc
		) dose_RANK, IMMUNE.LOT lot_number, IMMUNE.EXPIRATION_DATE vax_expiration_date, case 
				when ZC_SITE.TITLE = 'LEFT VASTUS LATERALIS' then 'Left Vastus Lateralis' 
				when ZC_SITE.TITLE = 'RIGHT VASTUS LATERALIS' then 'Right Vastus Lateralis' 
				when ZC_SITE.TITLE = 'RIGHT DELTOID' then 'Right Deltoid' 
				when ZC_SITE.TITLE = 'LEFT DELTOID' then 'Left Deltoid' 
				when ZC_SITE.TITLE = 'RIGHT UPPER QUAD. GLUTEUS' then 'Right Gluteus Medius' 
				when ZC_SITE.TITLE = 'LEFT UPPER QUAD. GLUTEUS' then 'Left Gluteus Medius' 
				when ZC_SITE.TITLE = 'RIGHT QUADRICEPS' then 'Right Thigh' 
				when ZC_SITE.TITLE = 'LEFT QUADRICEPS' then 'Left Thigh' 
				when ZC_SITE.TITLE = 'LEFT ARM' then 'Left Arm' 
				when ZC_SITE.TITLE = 'RIGHT ARM' then 'Right Arm' 
			end vax_admin_site, case 
				when Upper(ZC_ROUTE.NAME) = Upper('Intramuscular') then 'Intramuscular (IM)' 
				when Upper(ZC_ROUTE.NAME) = Upper('Subcutaneous') then 'Subcutaneous (SQ)' 
			end vax_route, E.EMP_NAME vax_admin_provider_name, EPIC_UTIL.EFN_DIN(IMMUNE.VIS_DATE_TEXT) vis_publication_date, 
		(
		select distinct case 
					when CL_QANSWER_QA.QUEST_ID = '127637' and CL_QANSWER_QA.QUEST_ANSWER is not NULL then CL_QANSWER_QA.QUEST_ANSWER 
					when CL_QANSWER_QA.QUEST_ID = '128081' and CL_QANSWER_QA.QUEST_ANSWER is not NULL then CL_QANSWER_QA.QUEST_ANSWER 
					else '1' 
				end quest_answer 
		from CL_QANSWER_QA 
		where 1 = 1 
			and CL_QANSWER_QA.QUEST_ID in ('127637', '128081') 
			and CL_QANSWER_QA.ANSWER_ID = IMMUNE.IMM_ANSWER_ID
		) vis_date_given_to_recipient, case 
				when IMMUNE.IMMNZTN_STATUS_C = 1 then 'FALSE' 
				else 'TRUE' 
			end AdverseReactionConsent, ' ' vax_reaction, ' ' vax_reaction_desc, tmpser.PROV_ID template_prov_id, tmpser.PROV_NAME template_prov_name, tmpser.PROV_TYPE template_prov_type, To_Char(IMMUNE.UPDATE_DATE, 'YYYY-MM-DD HH24:MI') vax_event_last_modified, case 
				when Trim(Coalesce(IMMUNE.IMM_PRODUCT, CLARITY_IMMUNZATN.NAME)) = 'covid 19 vaccine' then clarity_lot.PRODUCT 
				when Trim(Coalesce(IMMUNE.IMM_PRODUCT, CLARITY_IMMUNZATN.NAME)) = '' then clarity_lot.PRODUCT 
				else Coalesce(IMMUNE.IMM_PRODUCT, CLARITY_IMMUNZATN.NAME) 
			end product_name, case 
				when ENC_DEP.DEPARTMENT_ID is not NULL then ENC_DEP.DEPARTMENT_NAME || ' [' || ENC_DEP.DEPARTMENT_ID || ']' 
			end EPIC_DEPARTMENT, case 
				when CP.EXTERNAL_NAME is not NULL then Concat(CP.EXTERNAL_NAME, ' [' || CP.PRC_ID || ']') 
			end VISIT_TYPE, CP.PRC_ID, CLARITY_POS.ADDRESS_LINE_1 dep_address_line_1, CLARITY_POS.CITY DEP_CITY, CLARITY_POS.ZIP DEP_ZIP, InitCap(
			case 
					when (CLARITY_POS.CITY = 'WINSTON SALEM' and zc_cty.NAME is Null) then 'Forsyth' 
					else zc_cty.NAME 
				end) DEP_COUNTY 
	from IMMUNE 
		left join CLARITY_IMMUNZATN on CLARITY_IMMUNZATN.IMMUNZATN_ID = IMMUNE.IMMUNZATN_ID 
		left join ZC_IMMNZTN_STATUS on ZC_IMMNZTN_STATUS.INTERNAL_ID = IMMUNE.IMMNZTN_STATUS_C 
		left join ZC_ROUTE on IMMUNE.ROUTE_C = ZC_ROUTE.ROUTE_C 
		left join ZC_MFG on IMMUNE.MFG_C = ZC_MFG.MFG_C 
		left join ZC_SITE on IMMUNE.SITE_C = ZC_SITE.SITE_C 
		left join ZC_MED_UNIT on IMMUNE.IMMNZTN_DOSE_UNIT_C = ZC_MED_UNIT.DISP_QTYUNIT_C 
		left join RX_NDC on RX_NDC.NDC_ID = IMMUNE.NDC_NUM_ID 
		left join clarity_lot on IMMUNE.LOT = clarity_lot.LOT_NUM and IMMUNE.NDC_NUM_ID = clarity_lot.NDC_NUM_ID 
		left join ORDER_PROC on IMMUNE.ORDER_ID = ORDER_PROC.ORDER_PROC_ID and (ORDER_PROC.ORDER_STATUS_C is NULL or ORDER_PROC.ORDER_STATUS_C = '5') and ORDER_PROC.PROC_ID in ('142716', '142717', '142718', '142719', '142720') 
		left join PAT_ENC IMM_ENC on Coalesce(IMMUNE.IMM_CSN, ORDER_PROC.PAT_ENC_CSN_ID) = IMM_ENC.PAT_ENC_CSN_ID 
		left join CLARITY_EAP EAP on ORDER_PROC.PROC_ID = EAP.PROC_ID 
		left join CLARITY_PRC CP on IMM_ENC.APPT_PRC_ID = CP.PRC_ID 
		left join CLARITY_DEP ENC_DEP on IMM_ENC.DEPARTMENT_ID = ENC_DEP.DEPARTMENT_ID 
		left join CLARITY_LOC LOC on ENC_DEP.REV_LOC_ID = LOC.LOC_ID 
		left join CLARITY_POS on ENC_DEP.REV_LOC_ID = CLARITY_POS.POS_ID 
		left join ZC_COUNTY zc_cty on CLARITY_POS.COUNTY_C = zc_cty.COUNTY_C 
		left join CLARITY_LOC LOC2 on LOC.HOSP_PARENT_LOC_ID = LOC2.LOC_ID 
		left join CLARITY_EMP EMP on EMP.USER_ID = IMMUNE.GIVEN_BY_USER_ID 
		left join 
		(
		select CL_EMP_OT.USER_ID,
			NAMES_STATIC.FIRST_NAME || ' ' || NAMES_STATIC.LAST_NAME emp_name 
		from 
			(
			select distinct CL_EMP_OT.USER_ID,
				CL_EMP_OT.EMP_NAME_RECORD_ID,
				ROW_NUMBER() 
			over 
				(
				partition by CL_EMP_OT.USER_ID 
				order by CL_EMP_OT.USER_ID, CL_EMP_OT.CONTACT_DATE Desc
				) rank 
			from CL_EMP_OT 
			where 1 = 1
			) CL_EMP_OT 
			inner join NAMES_STATIC on NAMES_STATIC.RECORD_ID = CL_EMP_OT.EMP_NAME_RECORD_ID 
		where CL_EMP_OT.RANK = 1
		) E on EMP.USER_ID = E.USER_ID 
		left join 
		(
		select PAT_ENC_CSN_ID,
			PROV_ID,
			PROV_NAME,
			PROV_TYPE 
		from 
			(
			select distinct f_appt.PAT_ENC_CSN_ID,
				f_appt.APPT_DTTM,
				tmpser.PROV_ID,
				tmpser.PROV_NAME,
				tmpser.PROV_TYPE,
				ROW_NUMBER() 
			over 
				(
				partition by f_appt.PAT_ENC_CSN_ID, tmpser.PROV_ID 
				order by f_appt.PAT_ENC_CSN_ID, tmpser.PROV_ID, f_appt.CONTACT_DATE Desc
				) SER_rank 
			from f_sched_appt f_appt 
				left join APPT_UTIL_SNAPSHOT snp on f_appt.PAT_ENC_CSN_ID = snp.PAT_ENC_CSN_ID 
				left join clarity_ser tmpser on snp.UTIL_SNAP_PROV_ID = tmpser.PROV_ID 
			where f_appt.PRC_ID in ('586', '587', '588') 
				and Trunc(f_appt.APPT_DTTM) Between 
				(
				select MYPARAMS.START_DATE 
				from MYPARAMS
				) 
				and 
				(
				select MYPARAMS.END_DATE 
				from MYPARAMS
				) 
				and snp.UTIL_SNAP_CHANGE = '0'
			) 
		where SER_RANK = 1
		) tmpser on IMM_ENC.PAT_ENC_CSN_ID = tmpser.PAT_ENC_CSN_ID 
	where (tmpser.PROV_ID is NULL or tmpser.PROV_ID <> '8274') 
		and 1 = 1 
		and Trunc(IMMUNE.IMMUNE_DATE) Between 
		(
		select MYPARAMS.START_DATE 
		from MYPARAMS
		) 
		and 
		(
		select MYPARAMS.END_DATE 
		from MYPARAMS
		) 
		and IMMUNE.IMMNZTN_STATUS_C = 1 
		and CLARITY_IMMUNZATN.IMMUNZATN_ID in 
		(
		select distinct CLARITY_IMMUNZATN.IMMUNZATN_ID 
		from CLARITY_IMMUNZATN 
		where CLARITY_IMMUNZATN.NAME Like '%COV%2%' 
			and CLARITY_IMMUNZATN.NAME not Like '%(HISTORICAL)%'
		
	)), BASE_POP as 
	(
	select * 
	from IMM_DAT 
	where IMM_DAT.DOSE_RANK = 1 
		and IMM_DAT.IMM_HISTORIC_ADM_YN is NULL 
		and Trunc(IMM_DAT.IMMUNE_DATE) Between 
		(
		select MYPARAMS.REPORT_BEGIN_DATE 
		from MYPARAMS
		) 
		and 
		(
		select MYPARAMS.END_DATE 
		from MYPARAMS
		
	)), PAT_DEMO as 
	(
	select * 
	from 
		(
		select distinct PATIENT.PAT_ID,
			PATIENT.PAT_MRN_ID as MRN,
			PATIENT.PAT_FIRST_NAME,
			PATIENT.PAT_MIDDLE_NAME,
			PATIENT.PAT_LAST_NAME,
			Cast(PATIENT.BIRTH_DATE as Date) as BIRTH_DATE,
			case 
					when ZC_SEX.ABBR = 'F' then 'Female' 
					when ZC_SEX.ABBR = 'M' then 'Male' 
					when ZC_SEX.ABBR is NULL then 'Unknown' 
					when ZC_SEX.ABBR = 'U' then 'Unknown' 
					else 'Unknown' 
				end as PAT_GENDER,
			case 
					when Z_RACE1.NAME is NULL then 'Unknown' 
					when Z_RACE1.NAME = 'White or Caucasian' then 'White' 
					when Z_RACE1.NAME = 'Black or African American' then Z_RACE1.NAME 
					when Z_RACE1.NAME = 'American Indian or Alaska Native' then Z_RACE1.NAME 
					when Z_RACE1.NAME = 'Asian' then Z_RACE1.NAME 
					when Z_RACE1.NAME = 'Native Hawaiian or Other Pacific Islander' then Z_RACE1.NAME 
					when Z_RACE1.NAME = 'Patient Refused' then 'Declined to State' 
					when Z_RACE1.NAME = 'Unknown' then Z_RACE1.NAME 
					when Z_RACE1.NAME = 'Other' then Z_RACE1.NAME 
					else 'Other' 
				end as PATIENT_RACE1,
			case 
					when ZC_ETHNIC_GROUP.NAME is NULL then 'Unknown' 
					when ZC_ETHNIC_GROUP.NAME = 'Patient Refused' then 'Declined to State' 
					when ZC_ETHNIC_GROUP.NAME = 'Not Hispanic or Latino' then ZC_ETHNIC_GROUP.NAME 
					when ZC_ETHNIC_GROUP.NAME = 'Unknown' then ZC_ETHNIC_GROUP.NAME 
					when ZC_ETHNIC_GROUP.NAME = 'Hispanic or Latino' then ZC_ETHNIC_GROUP.NAME 
					else 'Unknown' 
				end as PATIENT_ETHNIC,
			PATIENT.ADD_LINE_1 PATIENT_ADDRESS1,
			PATIENT.ADD_LINE_2 PATIENT_ADDRESS2,
			PATIENT.CITY as PATIENT_CITY,
			ZC_STATE.NAME as PATIENT_STATE,
			PATIENT.ZIP as PATIENT_ZIP,
			case 
					when ZC_COUNTY.NAME in ('ALAMANCE', 'CUMBERLAND', 'JOHNSTON', 'RANDOLPH', 'ALEXANDER', 'CURRITUCK', 'JONES', 'RICHMOND', 'ALLEGHANY', 'DARE', 'LEE', 'ROBESON', 'ANSON', 'DAVIDSON', 'LENOIR', 'ROCKINGHAM', 'ASHE', 'DAVIE', 'LINCOLN', 'ROWAN', 'AVERY', 'DUPLIN', 'MACON', 'RUTHERFORD', 'BEAUFORT', 'DURHAM', 'MADISON', 'SAMPSON', 'BERTIE', 'EDGECOMBE', 'MARTIN', 'SCOTLAND', 'BLADEN', 'FORSYTH', 'MCDOWELL', 'STANLY', 'BRUNSWICK', 'FRANKLIN', 'MECKLENBURG', 'STOKES', 'BUNCOMBE', 'GASTON', 'MITCHELL', 'SURRY', 'BURKE', 'GATES', 'MONTGOMERY', 'SWAIN', 'CABARRUS', 'GRAHAM', 'MOORE', 'TRANSYLVANIA', 'CALDWELL', 'GRANVILLE', 'NASH', 'TYRRELL', 'CAMDEN', 'GREENE', 'NEW HANOVER', 'UNION', 'CARTERET', 'GUILFORD', 'NORTHAMPTON', 'VANCE', 'CASWELL', 'HALIFAX', 'ONSLOW', 'WAKE', 'CATAWBA', 'HARNETT', 'ORANGE', 'WARREN', 'CHATHAM', 'HAYWOOD', 'PAMLICO', 'WASHINGTON', 'CHEROKEE', 'HENDERSON', 'PASQUOTANK', 'WATAUGA', 'CHOWAN', 'HERTFORD', 'PENDER', 'WAYNE', 'CLAY', 'HOKE', 'PERQUIMANS', 'WILKES', 'CLEVELAND', 'HYDE', 'PERSON', 'WILSON', 'COLUMBUS', 'IREDELL', 'PITT', 'YADKIN', 'CRAVEN', 'JACKSON', 'POLK', 'YANCEY', 'OTHER') then InitCap(ZC_COUNTY.NAME) 
					when ZC_COUNTY.NAME is NULL then 'Other' 
					else 'Other' 
				end PATIENT_COUNTY,
			ZC_COUNTRY_2.ABBR as PATIENT_COUNTRY,
			ZC_PAT_LIVING_STAT.TITLE PAT_STATUS_C,
			case 
					when PATIENT.EMPY_STATUS_C in (1, 2, 7, 8) then 'STUDENT' 
					when PATIENT.EMPY_STATUS_C in (9) then 'UNKNOWN' 
					when PATIENT.EMPY_STATUS_C in (4) then 'EMPLOYED' 
					when PATIENT.EMPY_STATUS_C in (3) then 'UNEMPLOYED' 
					else 'OTHER' 
				end employment,
			EMERGENCY_CONTACTS.GUARDIAN_NAME,
			SubStr(EMERGENCY_CONTACTS.GUARDIAN_NAME, 0, 
				case 
						when Instr(EMERGENCY_CONTACTS.GUARDIAN_NAME, ',') - 1 < 0 then Length(EMERGENCY_CONTACTS.GUARDIAN_NAME) 
						else Instr(EMERGENCY_CONTACTS.GUARDIAN_NAME, ',') - 1 
					end) as GUARD_LAST_NAME,
			Replace(SubStr(EMERGENCY_CONTACTS.GUARDIAN_NAME, Instr(EMERGENCY_CONTACTS.GUARDIAN_NAME, ','), Length(EMERGENCY_CONTACTS.GUARDIAN_NAME)), ',', '') GUARD_FIRST_NAME,
			case 
					when ZREL.NAME is NULL then 'NA' 
					when ZREL.NAME = 'Unknown' then 'Unknown' 
					when ZREL.NAME = 'Other' then 'Other' 
					when ZREL.NAME = 'Spouse' then 'Spouse' 
					when ZREL.NAME = 'Husband' then 'Spouse' 
					when ZREL.NAME = 'Wife' then 'Spouse' 
					when ZREL.NAME = 'Step Parent' then 'Parent' 
					when ZREL.NAME = 'Stepmother' then 'Parent' 
					when ZREL.NAME = 'Stepfather' then 'Parent' 
					when ZREL.NAME = 'Father' then 'Parent' 
					when ZREL.NAME = 'Mother' then 'Parent' 
					when ZREL.NAME = 'Legal Guardian' then 'Legal Guardian' 
					when ZREL.NAME = 'Foster Parent' then 'Legal Guardian' 
					when ZREL.NAME = 'Brother' then 'Sibling' 
					when ZREL.NAME = 'Sister' then 'Sibling' 
					when ZREL.NAME = 'Son' then 'Child' 
					when ZREL.NAME = 'Daughter' then 'Child' 
					else 'Other' 
				end as GUARDIAN_REL,
			SubStr(EMERGENCY_CONTACTS.MOTHER_NAME, 0, 
				case 
						when Instr(EMERGENCY_CONTACTS.MOTHER_NAME, ',') - 1 < 0 then Length(EMERGENCY_CONTACTS.MOTHER_NAME) 
						else Instr(EMERGENCY_CONTACTS.MOTHER_NAME, ',') - 1 
					end) as mother_maiden_name,
			Coalesce(ZC_OCCUPATION.NAME, PAT3.OCCUPATION) OCCUPATION,
			ZC_INDUSTRY.NAME INDUSTRY,
			case 
					when OTHER_COMMUNCTN.OTHER_COMMUNIC_NUM is not NULL and OTHER_COMMUNCTN.OTHER_COMMUNIC_C = '1' then OTHER_COMMUNCTN.OTHER_COMMUNIC_NUM 
					when PATIENT.HOME_PHONE is not NULL then PATIENT.HOME_PHONE 
				end PATIENT_PHONE,
			case 
					when OTHER_COMMUNCTN.OTHER_COMMUNIC_NUM is not NULL and OTHER_COMMUNCTN.OTHER_COMMUNIC_C = '1' then 'Mobile' 
					when PATIENT.HOME_PHONE is not NULL then 'Home' 
				end PATIENT_PHONE_TYPE,
			case 
					when ZC_LANGUAGE.NAME is NULL then 'Unknown' 
					when ZC_LANGUAGE.NAME = 'Chinese' then 'Chinese' 
					when ZC_LANGUAGE.NAME = 'English' then 'English' 
					when ZC_LANGUAGE.NAME = 'Hindi' then 'Hindi' 
					when ZC_LANGUAGE.NAME = 'Japanese' then 'Japanese' 
					when ZC_LANGUAGE.NAME = 'Other' then 'Other' 
					when ZC_LANGUAGE.NAME = 'Arabic' then 'Arabic' 
					when ZC_LANGUAGE.NAME = 'Portuguese' then 'Portuguese' 
					when ZC_LANGUAGE.NAME = 'Russian' then 'Russian' 
					when ZC_LANGUAGE.NAME = 'Spanish' then 'Spanish' 
					else 'Other' 
				end PAT_LANGUAGE,
			PATIENT.EMAIL_ADDRESS,
			case 
					when PATIENT.IS_PHONE_REMNDR_YN = 'Y' then 'Y' 
					when PATIENT.IS_PHONE_REMNDR_YN is NULL then 'Y' 
					when PATIENT.IS_PHONE_REMNDR_YN = 'N' then 'N' 
					else 'Y' 
				end IS_PHONE_REMNDR_YN,
			ROW_NUMBER() 
		over 
			(
			partition by PATIENT.PAT_ID 
			order by PATIENT.PAT_ID, P_RACE1.PATIENT_RACE_C Desc
			) RANK 
		from 
			(
			select distinct BASE_POP.PAT_ID 
			from BASE_POP
			) BASE_POP 
			inner join PATIENT on BASE_POP.PAT_ID = PATIENT.PAT_ID 
			left join PATIENT_4 on PATIENT.PAT_ID = PATIENT_4.PAT_ID 
			left join PATIENT_3 PAT3 on PATIENT.PAT_ID = PAT3.PAT_ID 
			left join ZC_PAT_LIVING_STAT on PATIENT_4.PAT_LIVING_STAT_C = ZC_PAT_LIVING_STAT.PAT_LIVING_STAT_C 
			left join PAT_ADDRESS on PATIENT.PAT_ID = PAT_ADDRESS.PAT_ID 
			left join PATIENT_RACE P_RACE1 on PATIENT.PAT_ID = P_RACE1.PAT_ID and P_RACE1.LINE = 1 
			left join ZC_PATIENT_RACE Z_RACE1 on P_RACE1.PATIENT_RACE_C = Z_RACE1.PATIENT_RACE_C 
			left join ZC_SEX on PATIENT.SEX_C = ZC_SEX.RCPT_MEM_SEX_C 
			left join ZC_ETHNIC_GROUP on PATIENT.ETHNIC_GROUP_C = ZC_ETHNIC_GROUP.ETHNIC_GROUP_C 
			left join ZC_STATE on PATIENT.STATE_C = ZC_STATE.STATE_C 
			left join ZC_COUNTY on PATIENT.COUNTY_C = ZC_COUNTY.COUNTY_C 
			left join ZC_COUNTRY_2 on PATIENT.COUNTRY_C = ZC_COUNTRY_2.COUNTRY_2_C 
			left join EMERGENCY_CONTACTS on PATIENT.PAT_ID = EMERGENCY_CONTACTS.PAT_ID 
			left join ZC_OCCUPATION on PATIENT_4.OCCUPATION_C = ZC_OCCUPATION.OCCUPATION_C 
			left join ZC_INDUSTRY on PATIENT_4.INDUSTRY_C = ZC_INDUSTRY.INDUSTRY_C 
			left join ZC_PAT_RELATION ZREL on ZREL.PAT_RELATION_C = EMERGENCY_CONTACTS.GUARDIAN_REL_C 
			left join ZC_LANGUAGE on PATIENT.LANGUAGE_C = ZC_LANGUAGE.LANGUAGE_C 
			left join OTHER_COMMUNCTN on PATIENT.PAT_ID = OTHER_COMMUNCTN.PAT_ID 
		where 1 = 1
		) 
	where RANK = 1
	), DX_LIST as 
	(
	select distinct EDG_CURRENT_ICD10.CODE icd10_dx_code 
	from EDG_CURRENT_ICD10 
	where EDG_CURRENT_ICD10.CODE in ('T81.49XA', 'T86.49', 'T85.590A', 'T86.90', 'T86.5', 'T86.91', 'T86.00', 'T86.99', 'T86.01', 'T86.810', 'T86.02', 'T86.812', 'T86.09', 'T86.819', 'T86.10', 'T86.890', 'T86.11', 'T86.891', 'T86.12', 'T86.898', 'T86.13', 'T86.899', 'T86.19', 'T86.8409', 'T86.20', 'T86.8411', 'T86.21', 'T86.8419', 'T86.40', 'T86.8429', 'T86.41', 'T86.8489', 'T86.43', 'T86.8499', 'Q90.9', 'Q92.9')
	), dx as 
	(
	select distinct PAT_ID,
		CODE 
	from 
		(
		select distinct EDG.DX_NAME,
			case 
					when EDG_CURRENT_ICD10.CODE Like 'T%' then 'TX' 
					when EDG_CURRENT_ICD10.CODE Like 'Q%' then 'DS' 
				end code,
			EDG.DX_ID,
			PAT_ENC_DX.PAT_ID,
			PAT_ENC_DX.PAT_ENC_CSN_ID,
			PAT_ENC_DX.CONTACT_DATE,
			PAT_ENC_DX.PRIMARY_DX_YN 
		from BASE_POP 
			inner join PAT_ENC on BASE_POP.PAT_ID = PAT_ENC.PAT_ID 
			inner join CLARITY_dep DEP on PAT_ENC.DEPARTMENT_ID = DEP.DEPARTMENT_ID 
			inner join PAT_ENC_DX on PAT_ENC.PAT_ENC_CSN_ID = PAT_ENC_DX.PAT_ENC_CSN_ID 
			inner join CLARITY_EDG EDG on PAT_ENC_DX.DX_ID = EDG.DX_ID 
			inner join EDG_CURRENT_ICD10 on PAT_ENC_DX.DX_ID = EDG_CURRENT_ICD10.DX_ID 
			inner join DX_LIST on EDG_CURRENT_ICD10.CODE = DX_LIST.ICD10_DX_CODE 
		where 1 = 1 
			and Trunc(PAT_ENC_DX.CONTACT_DATE) Between Trunc((
					(
					select To_Date(MYPARAMS.START_DATE) 
					from MYPARAMS
					)) - 365) 
			and Trunc(
				(
				select To_Date(MYPARAMS.END_DATE) 
				from MYPARAMS
				)
		
	))), pl as 
	(
	select distinct PAT_ID,
		CODE 
	from 
		(
		select distinct EDG.DX_NAME,
			case 
					when EDG_CURRENT_ICD10.CODE Like 'T%' then 'TX' 
					when EDG_CURRENT_ICD10.CODE Like 'Q%' then 'DS' 
				end code,
			EDG.DX_ID,
			PROBLEM_LIST.PAT_ID,
			PROBLEM_LIST.PROBLEM_EPT_CSN,
			PROBLEM_LIST.DATE_OF_ENTRY,
			PROBLEM_LIST.PRINCIPAL_PL_YN 
		from BASE_POP 
			inner join PAT_ENC on BASE_POP.PAT_ID = PAT_ENC.PAT_ID 
			inner join CLARITY_dep DEP on PAT_ENC.DEPARTMENT_ID = DEP.DEPARTMENT_ID 
			inner join PROBLEM_LIST on PAT_ENC.PAT_ENC_CSN_ID = PROBLEM_LIST.PROBLEM_EPT_CSN 
			inner join CLARITY_EDG EDG on PROBLEM_LIST.DX_ID = EDG.DX_ID 
			inner join EDG_CURRENT_ICD10 on PROBLEM_LIST.DX_ID = EDG_CURRENT_ICD10.DX_ID 
			inner join DX_LIST on EDG_CURRENT_ICD10.CODE = DX_LIST.ICD10_DX_CODE 
		where 1 = 1 
			and (PROBLEM_LIST.NOTED_DATE Between Trunc((
						(
						select To_Date(MYPARAMS.START_DATE) 
						from MYPARAMS
						)) - 365) and Trunc(
					(
					select To_Date(MYPARAMS.END_DATE) 
					from MYPARAMS
					)) or PROBLEM_LIST.DATE_OF_ENTRY Between Trunc((
						(
						select To_Date(MYPARAMS.START_DATE) 
						from MYPARAMS
						)) - 365) and Trunc(
					(
					select To_Date(MYPARAMS.END_DATE) 
					from MYPARAMS
					)) or PROBLEM_LIST.UPDATE_DATE Between Trunc((
						(
						select To_Date(MYPARAMS.START_DATE) 
						from MYPARAMS
						)) - 365) and Trunc(
					(
					select To_Date(MYPARAMS.END_DATE) 
					from MYPARAMS
					))
		
	))), combined_DX_HX as 
	(
	select distinct PAT_ID,
		CODE 
	from 
		(
		select * 
		from DX 

		union all

		select * 
		from PL
		) 
	where 1 = 1
	), COMORBIDITY as 
	(
	select CORMO.PAT_ID,
		Count(CORMO.REGISTRY_ID) COMORBIDITIES 
	from 
		(
		select BASE_POP.PAT_ID,
			case 
					when PAT_ACTIVE_REG.REGISTRY_ID = 82299 and OBG.OBGYN_STAT_C = 4 then 4 
					when PAT_ACTIVE_REG.REGISTRY_ID = 82299 and (DM_WLL_ALL.SMOKING_STATUS_C in ('1', '2', '3', '4', '9', '10') or DM_WLL_ALL.SMOKING_USER_YN = 'Y') then 82014 
					when PAT_ACTIVE_REG.REGISTRY_ID = 82299 and DM_WLL_ALL.HAS_TYP_2_DIABETES_YN = 'Y' then 82000 
					when PAT_ACTIVE_REG.REGISTRY_ID = 82299 and combined_DX_HX.CODE = 'DS' then 1 
					when PAT_ACTIVE_REG.REGISTRY_ID = 82299 and combined_DX_HX.CODE = 'TX' then 2 
					else PAT_ACTIVE_REG.REGISTRY_ID 
				end REGISTRY_ID 
		from BASE_POP 
			left join combined_DX_HX on BASE_POP.PAT_ID = combined_DX_HX.PAT_ID and combined_DX_HX.CODE in ('DS', 'TX') 
			left join PAT_ACTIVE_REG on BASE_POP.PAT_ID = PAT_ACTIVE_REG.PAT_ID 
			left join DM_OBESITY on BASE_POP.PAT_ID = DM_OBESITY.PAT_ID 
			left join OBGYN_STAT OBG on BASE_POP.PAT_ENC_CSN_ID = OBG.UPDATE_CSN and OBG.OBGYN_STAT_C = 4 
			left join DM_WLL_ALL on BASE_POP.PAT_ID = DM_WLL_ALL.PAT_ID 
		where 1 = 1 
			and ((PAT_ACTIVE_REG.REGISTRY_ID in ('82030', '82005', '82009', '82004', '82006')) or (PAT_ACTIVE_REG.REGISTRY_ID = 82007 and DM_OBESITY.BMI_LAST >= 34) or (PAT_ACTIVE_REG.REGISTRY_ID = 82000 and DM_WLL_ALL.HAS_TYP_2_DIABETES_YN = 'Y') or (PAT_ACTIVE_REG.REGISTRY_ID = 82299 and (combined_DX_HX.CODE in ('DS', 'TX') or DM_WLL_ALL.SMOKING_USER_YN = 'Y' or DM_WLL_ALL.SMOKING_STATUS_C in ('1', '2', '3', '4', '9', '10'))))
		) CORMO 
	group by CORMO.PAT_ID
	), GRP as 
	(
	select * 
	from 
		(
		select distinct PAT.PAT_ID,
			case 
					when cvg.PAT_REC_OF_SUBS_ID = PAT.PAT_ID and cvg.PAYOR_ID = '405' then 'HEALTHCARE' 
					when cvg.PAT_REC_OF_SUBS_ID = PAT.PAT_ID and (EEP.EMPLOYER_NAME Like '%UNIVERSITY%' or EEP.EMPLOYER_NAME Like '%SCHOOL%' or EEP.EMPLOYER_NAME Like '%WFB%') then 'EDUCATION' 
					when cvg.PAT_REC_OF_SUBS_ID = PAT.PAT_ID and (EEP.EMPLOYER_NAME Like '%MEDICAL%' or EEP.EMPLOYER_NAME Like '%HOSPITAL%' or EEP.EMPLOYER_NAME Like '%HEALTH%' or EEP.EMPLOYER_NAME Like '%WFB%') then 'HEALTHCARE' 
					else Coalesce(PAT3.OCCUPATION, ZC_OCCUPATION.NAME, 'UNKNOWN') 
				end OCCUPATION,
			case 
					when cvg.PAT_REC_OF_SUBS_ID = PAT.PAT_ID and cvg.PAYOR_ID = '405' then 'HEALTHCARE' 
					when cvg.PAT_REC_OF_SUBS_ID = PAT.PAT_ID and (EEP.EMPLOYER_NAME Like '%UNIVERSITY%' or EEP.EMPLOYER_NAME Like '%SCHOOL%' or EEP.EMPLOYER_NAME Like '%WFB%') then 'EDUCATION' 
					when cvg.PAT_REC_OF_SUBS_ID = PAT.PAT_ID and (EEP.EMPLOYER_NAME Like '%MEDICAL%' or EEP.EMPLOYER_NAME Like '%HOSPITAL%' or EEP.EMPLOYER_NAME Like '%HEALTH%' or EEP.EMPLOYER_NAME Like '%WFB%') then 'HEALTHCARE' 
					else Coalesce(ZC_INDUSTRY.NAME, 'OTHER') 
				end INDUSTRY,
			case 
					when cvg.PAT_REC_OF_SUBS_ID = PAT.PAT_ID then Z1.NAME 
					when cvg.PAT_REC_OF_SUBS_ID <> PAT.PAT_ID and PAT.EMPY_STATUS_C in (1, 2, 7, 8) then 'STUDENT' 
					when cvg.PAT_REC_OF_SUBS_ID <> PAT.PAT_ID and PAT.EMPY_STATUS_C in (9) then 'UNKNOWN' 
					when cvg.PAT_REC_OF_SUBS_ID <> PAT.PAT_ID and PAT.EMPY_STATUS_C in (4) then 'EMPLOYED' 
					when cvg.PAT_REC_OF_SUBS_ID <> PAT.PAT_ID and PAT.EMPY_STATUS_C in (3) then 'UNEMPLOYED' 
					else 'OTHER' 
				end employment_STATUS,
			EEP.EMPLOYER_NAME,
			ROW_NUMBER() 
		over 
			(
			partition by PAT.PAT_ID 
			order by PAT.PAT_ID, cml.MEM_EFF_FROM_DATE Desc
			) RANK 
		from BASE_POP 
			inner join PATIENT PAT on PAT.PAT_ID = BASE_POP.PAT_ID 
			left join COVERAGE_MEM_LIST cml on cml.PAT_ID = PAT.PAT_ID 
			left join V_COVERAGE_PAYOR_PLAN cpp on cpp.COVERAGE_ID = cml.COVERAGE_ID 
			left join COVERAGE cvg on cml.COVERAGE_ID = cvg.COVERAGE_ID 
			left join PATIENT_3 PAT3 on PAT3.PAT_ID = BASE_POP.PAT_ID 
			left join PATIENT_4 on PAT.PAT_ID = PATIENT_4.PAT_ID 
			left join ZC_OCCUPATION on PATIENT_4.OCCUPATION_C = ZC_OCCUPATION.OCCUPATION_C 
			left join ZC_INDUSTRY on PATIENT_4.INDUSTRY_C = ZC_INDUSTRY.INDUSTRY_C 
			left join ZC_SUBSCR_EMP_STAT Z1 on cvg.SUBSCR_EMP_STAT_C = Z1.SUBSCR_EMP_STAT_C 
			left join CLARITY_EEP EEP on EEP.EMPLOYER_ID = cvg.SUBSCR_EMPLOYER_ID 
		where 1 = 1 
			and (cml.MEM_EFF_TO_DATE is NULL or Trunc(cml.MEM_EFF_TO_DATE) >= Trunc(BASE_POP.IMMUNE_DATE))
		) 
	where RANK = 1
	), ADMIN_IMMS as 
	(
	select 'WFBHCOVID' recip_authority_id,
		PAT_DEMO.MRN recip_id,
		PAT_DEMO.PAT_FIRST_NAME FirstName,
		PAT_DEMO.PAT_MIDDLE_NAME MiddleName,
		PAT_DEMO.PAT_LAST_NAME LastName,
		To_Char(PAT_DEMO.BIRTH_DATE, 'yyyy-mm-dd') PersonBirthDate,
		PAT_DEMO.PAT_GENDER Gender,
		case 
				when PAT_DEMO.GUARDIAN_NAME is not NULL then Trim(PAT_DEMO.GUARD_FIRST_NAME) 
				else Trim(PAT_DEMO.PAT_FIRST_NAME) 
			end resp_first_name,
		case 
				when PAT_DEMO.GUARDIAN_NAME is not NULL then ' ' 
				else Trim(PAT_DEMO.PAT_MIDDLE_NAME) 
			end resp_middle_name,
		case 
				when PAT_DEMO.GUARDIAN_NAME is not NULL then Trim(PAT_DEMO.GUARD_LAST_NAME) 
				else Trim(PAT_DEMO.PAT_LAST_NAME) 
			end resp_last_name,
		case 
				when PAT_DEMO.GUARDIAN_REL is NULL then 'Self' 
				when PAT_DEMO.GUARDIAN_REL = 'NA' then 'Self' 
				when (PAT_DEMO.GUARDIAN_REL = 'Unknown' and PAT_DEMO.GUARD_LAST_NAME is NULL and PAT_DEMO.GUARD_FIRST_NAME is Null) then 'Self' 
				when PAT_DEMO.GUARDIAN_REL = 'Unknown' and (PAT_DEMO.GUARD_LAST_NAME is not NULL or PAT_DEMO.GUARD_FIRST_NAME is not Null) then PAT_DEMO.GUARDIAN_REL 
				else PAT_DEMO.GUARDIAN_REL 
			end relationship_to_recip,
		PAT_DEMO.MOTHER_MAIDEN_NAME mother_maiden_name,
		Coalesce(PAT_DEMO.PATIENT_ADDRESS1, BASE_POP.dep_address_line_1) ADDRESS_1,
		PAT_DEMO.PATIENT_ADDRESS2 ADDRESS_2,
		Coalesce(PAT_DEMO.PATIENT_CITY, BASE_POP.DEP_CITY) cITY,
		Coalesce(PAT_DEMO.PATIENT_STATE, 'North Carolina') State,
		Coalesce(PAT_DEMO.PATIENT_COUNTRY, 'USA') Country,
		Coalesce(PAT_DEMO.PATIENT_ZIP, BASE_POP.DEP_ZIP) Zip,
		Coalesce(PAT_DEMO.PATIENT_COUNTY, BASE_POP.DEP_COUNTY) COUNTY,
		PAT_DEMO.PATIENT_RACE1 Race,
		PAT_DEMO.PATIENT_ETHNIC Ethnicity,
		case 
				when PAT_DEMO.PAT_LANGUAGE is NULL then 'English' 
				when PAT_DEMO.PAT_LANGUAGE = 'Unknown' then 'English' 
				else PAT_DEMO.PAT_LANGUAGE 
			end recip_primary_language,
		case 
				when PAT_DEMO.PATIENT_PHONE is not NULL then PAT_DEMO.PATIENT_PHONE 
			end recip_telephone_number,
		case 
				when PAT_DEMO.PATIENT_PHONE_TYPE is not NULL then PAT_DEMO.PATIENT_PHONE_TYPE 
				else 'Mobile' 
			end recip_telephone_number_type,
		PAT_DEMO.EMAIL_ADDRESS recip_email,
		case 
				when PAT_DEMO.IS_PHONE_REMNDR_YN is not NULL then PAT_DEMO.IS_PHONE_REMNDR_YN 
				when PAT_DEMO.IS_PHONE_REMNDR_YN is NULL then 'Unknown' 
				else 'Unknown' 
			end recall_notices,
		BASE_POP.ORG_NAME,
		BASE_POP.ADMIN_NAME,
		BASE_POP.VTRCKS_PROV_PIN,
		case 
				when BASE_POP.NDC Like '59267%' then '59267-1000-02' 
				when BASE_POP.NDC Like '80777%' then '80777-0273-99' 
				when BASE_POP.NDC Like '59676%' then '59676-0580-05' 
				else BASE_POP.NDC 
			end ndc,
		To_Char(BASE_POP.IMMUNE_DATE, 'yyyy-mm-dd') ADMIN_DATE,
		BASE_POP.vax_event_id,
		case 
				when BASE_POP.PRC_ID = '586' then 'Dose 1 Administered' 
				when (BASE_POP.PRC_ID is NULL and BASE_POP.DOSE_NUM = 1) then 'Dose 1 Administered' 
				when (BASE_POP.PRC_ID not in ('586', '587', '588') and BASE_POP.DOSE_NUM = 1) then 'Dose 1 Administered' 
				when BASE_POP.PRC_ID in ('587', '588') then 'Dose 2 Administered' 
				when (BASE_POP.DOSE_NUM > 1 or BASE_POP.VISIT_TYPE Like '%2ND DOSE%') then 'Dose 2 Administered' 
			end dose_num,
		BASE_POP.lot_number,
		To_Char(BASE_POP.vax_expiration_date, 'YYYY-MM-DD') vax_expiration_date,
		BASE_POP.VAX_ADMIN_SITE,
		BASE_POP.VAX_ROUTE,
		BASE_POP.vax_admin_provider_name,
		case 
				when BASE_POP.NDC Like '59267%' and BASE_POP.IMMUNE_DATE < '10-mar-2021' then '12-2020' 
				when BASE_POP.NDC Like '59267%' and BASE_POP.IMMUNE_DATE >= '10-mar-2021' then '03-2021' 
				else case 
					when To_Char(BASE_POP.VIS_PUBLICATION_DATE, 'MM-YYYY') <> '12-2020' then '12-2020' 
					when To_Char(BASE_POP.VIS_PUBLICATION_DATE, 'MM-YYYY') is NULL then '12-2020' 
					when To_Char(BASE_POP.VIS_PUBLICATION_DATE, 'MM-YYYY') = ' ' then '12-2020' 
					else To_Char(BASE_POP.VIS_PUBLICATION_DATE, 'MM-YYYY') 
				end 
			end vis_publication_date,
		case 
				when BASE_POP.VIS_DATE_GIVEN_TO_RECIPIENT is NULL then To_Char(BASE_POP.IMMUNE_DATE, 'yyyy-mm-dd') 
				when BASE_POP.VIS_DATE_GIVEN_TO_RECIPIENT = ' ' then To_Char(BASE_POP.IMMUNE_DATE, 'yyyy-mm-dd') 
				when BASE_POP.VIS_DATE_GIVEN_TO_RECIPIENT = '1' then To_Char(BASE_POP.IMMUNE_DATE, 'yyyy-mm-dd') 
				else To_Char(Coalesce(EPIC_UTIL.EFN_DIN(BASE_POP.VIS_DATE_GIVEN_TO_RECIPIENT), BASE_POP.IMMUNE_DATE), 'YYYY-MM-DD') 
			end vis_date_given_to_recipient,
		case 
				when COMORBIDITY.COMORBIDITIES = 1 then '1' 
				when COMORBIDITY.COMORBIDITIES > 1 then '2 or more' 
				when COMORBIDITY.COMORBIDITIES is NULL then 'None' 
			end cmorbid_status,
		case 
				when (Coalesce(GRP.INDUSTRY, GRP.OCCUPATION, PAT_DEMO.INDUSTRY) Like Upper('%HealthCare%')) and Coalesce(GRP.EMPLOYMENT_STATUS, PAT_DEMO.EMPLOYMENT) in ('Full Time', 'Part Time', 'Self Employed') then 'Group 1' 
				when (Trunc(Months_Between(BASE_POP.IMMUNE_DATE, PAT_DEMO.BIRTH_DATE) / 12) >= 65) then 'Group 2' 
				when (Coalesce(GRP.INDUSTRY, GRP.OCCUPATION, PAT_DEMO.INDUSTRY) Like Upper('%ChildCare%') or Coalesce(GRP.INDUSTRY, GRP.OCCUPATION, PAT_DEMO.INDUSTRY) Like Upper('%Education%')) then 'Group 3' 
				when (Trunc(Months_Between(BASE_POP.IMMUNE_DATE, PAT_DEMO.BIRTH_DATE) / 12) Between 16 and 64 or COMORBIDITY.COMORBIDITIES > 0) then 'Group 4' 
				else 'Group 5' 
			end recip_priority_group,
		'Unknown' SEROLOGY,
		' ' Date_of_Disease,
		BASE_POP.ADVERSEREACTIONCONSENT Vaccine_Refusal,
		case 
				when Upper(Coalesce(GRP.OCCUPATION, PAT_DEMO.OCCUPATION)) Like Upper('%Long Term Care Facility%') then 'Resident of Long Term Care Facility' 
				when Upper(Coalesce(GRP.OCCUPATION, PAT_DEMO.OCCUPATION)) Like Upper('%Congregant%Group%') then 'Resident of Congregant/Group Setting' 
				when Upper(Coalesce(GRP.OCCUPATION, PAT_DEMO.OCCUPATION)) Like Upper('Student') then 'Student' 
				when Upper(Coalesce(GRP.OCCUPATION, PAT_DEMO.OCCUPATION)) Like Upper('%Frontline%Worker%') then 'Frontline Essential Worker ( In Person at Work)' 
				when Upper(Coalesce(GRP.OCCUPATION, PAT_DEMO.OCCUPATION)) Like Upper('%Essential Worker%') then 'Other Essential Worker (non-frontline)' 
				when Upper(Coalesce(GRP.OCCUPATION, PAT_DEMO.OCCUPATION)) Like Upper('Health Care') then 'Patient-facing Healthcare/ Long Term Care Facility Worker' 
				when Upper(Coalesce(GRP.OCCUPATION, PAT_DEMO.OCCUPATION)) Like Upper('%Childcare%') then 'Childcare or PreK-12 Education' 
				when Upper(Coalesce(GRP.OCCUPATION, PAT_DEMO.OCCUPATION)) is NULL then 'None of the Above' 
				else 'None of the Above' 
			end Recipient_type,
		case 
				when (Upper(Coalesce(GRP.INDUSTRY, PAT_DEMO.INDUSTRY)) Like Upper('%HealthCare%') or Upper(Coalesce(GRP.INDUSTRY, PAT_DEMO.INDUSTRY)) Like Upper('%Health Care%')) then 'Health Care' 
				when Upper(Coalesce(GRP.INDUSTRY, PAT_DEMO.INDUSTRY)) Like Upper('Public Safety') then 'Public Safety' 
				when Upper(Coalesce(GRP.INDUSTRY, PAT_DEMO.INDUSTRY)) Like Upper('Food and agriculture') then 'Food and agriculture' 
				when Upper(Coalesce(GRP.INDUSTRY, PAT_DEMO.INDUSTRY)) Like Upper('Critical Manufacturing ') then 'Critical Manufacturing ' 
				when Upper(Coalesce(GRP.INDUSTRY, PAT_DEMO.INDUSTRY)) Like Upper('Commercial Facilities for Essential Goods') then 'Commercial Facilities for Essential Goods' 
				when Upper(Coalesce(GRP.INDUSTRY, PAT_DEMO.INDUSTRY)) Like Upper('Education') then 'Education' 
				when Upper(Coalesce(GRP.INDUSTRY, PAT_DEMO.INDUSTRY)) Like Upper('Transportation') then 'Transportation' 
				when Upper(Coalesce(GRP.INDUSTRY, PAT_DEMO.INDUSTRY)) Like Upper('Residentialï¿½facilities, housing,ï¿½and real estate') then 'Residentialï¿½facilities, housing,ï¿½and real estate' 
				when Upper(Coalesce(GRP.INDUSTRY, PAT_DEMO.INDUSTRY)) Like Upper('Finance') then 'Finance' 
				when Upper(Coalesce(GRP.INDUSTRY, PAT_DEMO.INDUSTRY)) Like Upper('IT%Communication%') then 'IT and Communication' 
				when Upper(Coalesce(GRP.INDUSTRY, PAT_DEMO.INDUSTRY)) Like Upper('Energy') then 'Energy' 
				when Upper(Coalesce(GRP.INDUSTRY, PAT_DEMO.INDUSTRY)) Like Upper('Water and Wastewater') then 'Water and Wastewater' 
				when Upper(Coalesce(GRP.INDUSTRY, PAT_DEMO.INDUSTRY)) Like Upper('Commercial facilities') then 'Commercial facilities' 
				when Upper(Coalesce(GRP.INDUSTRY, PAT_DEMO.INDUSTRY)) Like Upper('Government and Community Services') then 'Government and Community Services' 
				when Upper(Coalesce(GRP.INDUSTRY, PAT_DEMO.INDUSTRY)) Like Upper('Public works and infrastructure support services') then 'Public works and infrastructure support services' 
				when Upper(Coalesce(GRP.INDUSTRY, PAT_DEMO.INDUSTRY)) Like Upper('Industries involving chemicals or hazardous materials') then 'Industries involving chemicals or hazardous materials' 
				when Upper(Coalesce(GRP.INDUSTRY, PAT_DEMO.INDUSTRY)) Like Upper('Hygiene products and services') then 'Hygiene products and services' 
				when Upper(Coalesce(GRP.INDUSTRY, PAT_DEMO.INDUSTRY)) Like Upper('Public Health') then 'Public Health' 
				when Upper(Coalesce(GRP.INDUSTRY, PAT_DEMO.INDUSTRY)) Like Upper('Defense industrial base') then 'Defense industrial base' 
				when Upper(Coalesce(GRP.INDUSTRY, PAT_DEMO.INDUSTRY)) is NULL then 'Other / Not Applicable' 
				else 'Other / Not Applicable' 
			end INDUSTRY,
		To_Char(SysDate, 'YYYY-MM-DD') file_date,
		' ' ssn,
		' ' drivers_lic,
		' ' ins_policy,
		BASE_POP.VAX_EVENT_LAST_MODIFIED,
		BASE_POP.PAT_ID,
		case 
				when (BASE_POP.NDC Like '59267%' or Upper(BASE_POP.PRODUCT_NAME) Like Upper('PFIZER%COV%')) then 'Pfizer COVID-19 Vaccine (EUA)' 
				when (BASE_POP.NDC Like '80777%' or Upper(BASE_POP.PRODUCT_NAME) Like Upper('MODERNA%COV%')) then 'Moderna COVID-19 Vaccine (EUA)' 
				when (BASE_POP.NDC Like '59676%' or Upper(BASE_POP.PRODUCT_NAME) Like Upper('JANSSEN%COV%')) then 'Johnson Johnson COVID-19 Vaccine (EUA)' 
				when Upper(BASE_POP.PRODUCT_NAME) Like Upper('ASTRAZENECA%COV%') then 'AstraZeneca COVID19 Vaccine (EUA)' 
				else BASE_POP.PRODUCT_NAME 
			end PRODUCT_NAME,
		BASE_POP.template_prov_id epic_clinic_prov_id,
		BASE_POP.template_prov_name epic_clinic_prov,
		BASE_POP.EPIC_DEPARTMENT,
		BASE_POP.VISIT_TYPE,
		BASE_POP.DOSE_NUM patient_doses,
		BASE_POP.IMMUNE_DATE 
	from BASE_POP 
		inner join PAT_DEMO on BASE_POP.PAT_ID = PAT_DEMO.PAT_ID 
		left join COMORBIDITY on BASE_POP.PAT_ID = COMORBIDITY.PAT_ID 
		left join GRP on BASE_POP.PAT_ID = GRP.PAT_ID 
		left join combined_DX_HX on BASE_POP.PAT_ID = combined_DX_HX.PAT_ID 
	where 1 = 1
	and PAT_DEMO.MRN in (6157486
												, 6156845
												, 6159708
												, 6150392
												, 6153939
												, 6151033
												)
	) 
select ADMIN_IMMS.* 
from ADMIN_IMMS 
where 1 = 1

