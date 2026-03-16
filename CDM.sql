/*
Optional Extract 4:  Charge Description Master (CDM) Data
File Description:  The hospital’s CDM file including all active and inactive charge codes (for hospital billing)
*/

With EAP2 as
               (SELECT  FAS.PROC_ID, EAP2.CPT_CODE,EAP2.CODE_TYPE_C
FROM
	(select MAX(contact_date_real)CT_DT, PROC_ID
           	from CLARITY_EAP_OT
           	group by PROC_ID
           	)FAS
	INNER JOIN CLARITY_EAP_OT EAP2
           	 ON EAP2.PROC_ID = FAS.PROC_ID AND FAS.CT_DT = EAP2.CONTACT_DATE_REAL),
FSC_PROC AS
(   select
           	MAX(CLARITY_FSC_PROC.CONTACT_DATE) CON_DT,
           	CLARITY_FSC_PROC.FEE_SCHEDULE_ID,
          	CLARITY_FSC_SA.RESTR_SERV_AREA_ID,
           	CLARITY_FSC.FEE_SCHEDULE_NAME,
           	CLARITY_FSC_PROC.PROC_ID,
           	CLARITY_FSC_PROC.PROC_CODE,
           	CLARITY_FSC_PROC.PROC_MOD_ID,
           	CLARITY_FSC_PROC.UNIT_CHARGE_AMOUNT,
           	CLARITY_FSC_PROC.UNIT_CHARGE_RBRVS,
           	CLARITY_FSC_PROC.UNIT_RVU,
           	CLARITY_FSC_PROC.BASE_CHARGE_AMOUNT,
           	CLARITY_FSC_PROC.BASE_CHARGE_RBRVS,
           	CLARITY_FSC_PROC.BASE_RVU,
           	CLARITY_FSC_PROC.ALGORITHM_C,
           	CLARITY_FSC_PROC.INTERVAL_LENGTH,
           	CLARITY_FSC_PROC.INTERVAL_METHOD_C,
           	CLARITY_FSC_PROC.ROUNDING_METHOD_C,
           	CLARITY_FSC_PROC.TYPE_OF_SERVICE_C,
           	CLARITY_FSC_PROC.FAC_PRICE_TYPE,
           	CLARITY_FSC_PROC.TIERED_PRC_METHOD_C,
           	CLARITY_FSC_PROC.TIERED_PRC_RATE_C
 
           	FROM
           	(SELECT  MAX(FSC.CONTACT_DATE_REAL) CT_DT, FSC.FEE_SCHEDULE_ID, PROC_ID 
           	FROM CLARITY_FSC_PROC FSC
          	GROUP BY FSC.FEE_SCHEDULE_ID, FSC.PROC_ID
          	) FSC
           	INNER JOIN CLARITY_FSC_PROC ON FSC.PROC_ID = CLARITY_FSC_PROC.PROC_ID AND FSC.CT_DT = CLARITY_FSC_PROC.CONTACT_DATE_REAL
           	LEFT OUTER JOIN CLARITY_FSC
    	   	ON CLARITY_FSC.FEE_SCHEDULE_ID = CLARITY_FSC_PROC.FEE_SCHEDULE_ID
           	LEFT OUTER JOIN CLARITY_FSC_SA
    	   	ON CLARITY_FSC.FEE_SCHEDULE_ID = CLARITY_FSC_SA.FEE_SCHEDULE_ID
           	GROUP BY
           	CLARITY_FSC_PROC.FEE_SCHEDULE_ID,
           	CLARITY_FSC.FEE_SCHEDULE_NAME,
           	CLARITY_FSC_PROC.PROC_ID,
           	CLARITY_FSC_PROC.PROC_CODE,
           	CLARITY_FSC_PROC.PROC_MOD_ID,
           	CLARITY_FSC_PROC.UNIT_CHARGE_AMOUNT,
           	CLARITY_FSC_PROC.UNIT_CHARGE_RBRVS,
           	CLARITY_FSC_PROC.UNIT_RVU,
           	CLARITY_FSC_PROC.BASE_CHARGE_AMOUNT,
           	CLARITY_FSC_PROC.BASE_CHARGE_RBRVS,
           	CLARITY_FSC_PROC.BASE_RVU,
           	CLARITY_FSC_PROC.ALGORITHM_C,
           	CLARITY_FSC_PROC.INTERVAL_LENGTH,
           	CLARITY_FSC_PROC.INTERVAL_METHOD_C,
           	CLARITY_FSC_PROC.ROUNDING_METHOD_C,
           	CLARITY_FSC_PROC.TYPE_OF_SERVICE_C,
           	CLARITY_FSC_PROC.FAC_PRICE_TYPE,
           	CLARITY_FSC_PROC.TIERED_PRC_METHOD_C,
           	CLARITY_FSC_PROC.TIERED_PRC_RATE_C,
           	CLARITY_FSC_SA.RESTR_SERV_AREA_ID),
    
CC AS
(SELECT EAPCC.PROC_ID,CC.COST_CENTER_CODE, CC.COST_CENTER_NAME, CC.COST_CNTR_ID
FROM
	(SELECT MAX(EAPCC.CONTACT_DATE_REAL) CT_DT, EAPCC.PROC_ID FROM EAP_ASSOC_COST_CTR EAPCC GROUP BY EAPCC.PROC_ID)EAPCC
	LEFT OUTER JOIN EAP_ASSOC_COST_CTR EAPCC2 ON EAPCC2.PROC_ID = EAPCC.PROC_ID AND EAPCC.CT_DT = EAPCC2.CONTACT_DATE_REAL
	LEFT OUTER JOIN CL_COST_CNTR cc on cc.COST_CNTR_ID = EAPCC2.ASSOC_COST_CNTR_ID)

/*
select
'FacilityCode|DepartmentNumber|DepartmentName|RevenueCode|ChargeCode|ChargeCodeName|StartDate|EndDate|GlobalPrice|InpatientPrice|OutpatientPrice|CPTCode|CPTModifier1|CPTModifier2|HCPCSCode|HCPCSModifier1|HCPCSModifier2|Active' as OptionalExtract4
from
dual
UNION
*/ 

Select
CASE WHEN FSC_proc.RESTR_SERV_AREA_ID IS NOT NULL THEN to_char(FSC_PROC.RESTR_SERV_AREA_ID) ELSE '' END as FacilityCode --- 1 (FacilityCode)
,
CASe when cc.COST_CNTR_ID IS not null then cc.COST_CENTER_CODE else '' end as DepartmentNumber --2 (DepartmentNumber)
,
Case when cc.COST_CNTR_ID IS NOT null then cc.COST_CENTER_NAME else '' end as DepartmentName --3 (DepartmentName)
,
Case when CL_UB_REV_CODE.REVENUE_CODE  is not null then CL_UB_REV_CODE.REVENUE_CODE else '' end as  RevenueCode --4 (RevenueCode)
,
CASE WHEN CLARITY_EAP.PROC_CODE  is not null then clarity_eap.PROC_CODE else '' end as  ChargeCode --5 (ChargeCode)
,
case when CLARITY_EAP.PROC_NAME  is not null then clarity_eap.PROC_NAME else '' end as ChargeCodeName --6 (ChargeCodeName)
,
Case when EAPOT.CT_DT IS NOT NULL then
	 to_char(trunc(EAPOT.CT_DT),'mm/dd/yyyy') else '' end as StartDate --7 (StartDate)
,
Case when CLARITY_EAP_2.END_CONT_DATE is not null AND CLARITY_EAP.IS_ACTIVE_YN = 'N' then
            to_char(trunc(CLARITY_EAP_2.END_CONT_DATE),'mm/dd/yyyy') else '' end as EndDate --8 (EndDate)
,
to_char(case when fsc_proc.UNIT_CHARGE_AMOUNT IS NOT NULL THEN FSC_PROC.UNIT_CHARGE_AMOUNT ELSE 0 END)  as GlobalPrice --9 (GlobalPrice)
,
'' as InpatientPrice --10 (InpatientPrice)
,
'' as OutpatientPrice --11 (OutpatientPrice)
,
Case when eap2.cpt_code IS NOT null and eap2.code_type_c =1 then eap2.cpt_code else '' end as CPTCode --12 (CPTCode)
,
Case when eap2.cpt_code is not null and eap2.code_type_c =1 and clarity_eap.modifier is not null
           	then SUBSTR(CLARITY_EAP.modifier,1,2) else '' end as CPTModifier1 --13 (CPTModifier1)
,
Case when eap2.cpt_code is not null and eap2.code_type_c =1 and clarity_eap.modifier is not null
           	then SUBSTR(CLARITY_EAP.modifier,4,5) else '' end as CPTModifier2 --14 (CPTModifier2)
,
Case when eap2.cpt_code IS NOT null and eap2.code_type_c = 2 then eap2.cpt_code else '' end as HCPCSCode --15 (HCPCSCode)
,
Case when eap2.cpt_code is not null and eap2.code_type_c = 2 and clarity_eap.modifier is not null
           	then SUBSTR(CLARITY_EAP.modifier,1,2) else '' end  as HCPCSModifier1 --16 (HCPCSModifier1)
,
Case when eap2.cpt_code is not null and eap2.code_type_c = 2 and clarity_eap.modifier is not null
           	then SUBSTR(CLARITY_EAP.modifier,4,5) else '' end as HCPCSModifier2 --17 (HCPCSModifier2)
,
Case when CLARITY_EAP.IS_ACTIVE_YN  is not null then clarity_eap.IS_ACTIVE_YN else '' end as Active --18 (Active)
 
--as OptionalExtract4
 
FROM
FSC_PROC
INNER JOIN CLARITY_EAP ON FSC_PROC.PROC_ID = CLARITY_EAP.PROC_ID 
LEFT OUTER JOIN EAP2 ON EAP2.PROC_ID = FSC_PROC.PROC_ID
LEFT OUTER JOIN CL_UB_REV_CODE ON CL_UB_REV_CODE.UB_REV_CODE_ID = CLARITY_EAP.UB_REV_CODE_ID
LEFT OUTER JOIN CC ON CC.PROC_ID = FSC_PROC.PROC_ID
LEFT OUTER JOIN CLARITY_EAP_2 ON CLARITY_EAP_2.PROC_ID = CLARITY_EAP.PROC_ID
LEFT OUTER JOIN
	(SELECT MIN(EAPOT.CONTACT_DATE) CT_DT, EAPOT.PROC_ID
 	FROM CLARITY_EAP_OT EAPOT GROUP BY PROC_ID) EAPOT ON EAPOT.PROC_ID = FSC_PROC.PROC_ID

--where eap2.code_type_c = 1 and clarity_eap.modifier is not null

where CLM_PROC_TYPE_C in ('2','3') --and IS_EC_INACTIVE_YN <> 'Y'

--ORDER BY OptionalExtract4 DESC