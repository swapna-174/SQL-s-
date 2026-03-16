/*
Required Extract 7:  Insurance Master
File Description:  All the hospital’s Insurance Plan codes, and their associated Contract identification information
*/

/*
SELECT
'InsurancePlanCode|InsurancePlanName|PayorCode|PayorName|FacilityCode|ContractCode|ContractName|Active'
as RequiredExtract7
 from dual
UNION
*/  

SELECT
to_char(Epp.Benefit_Plan_Id) as InsurancePlanCode -- 1.  InsurancePlanCode
,
CASE when Epp.Benefit_Plan_Name is not Null then Epp.Benefit_Plan_Name else '' end as InsurancePlanName -- 2. InsurancePlanName
,
to_char(Epm.payor_id) as PayerCode -- 3. PayerCode
,
CASE when epm.payor_name is not Null then epm.payor_name else '' end as PayerName -- 4. PayerName
,
'' as FacilityCode -- 5. FacilityCode
,
'' AS ContractCode -- 6. ContractCode
,
'' as ContractName -- 7. ContractName
,
to_char(CASE when EPPRS.NAME is not Null then EPPRS.NAME else '' end) as Active -- 8. Active

--as  RequiredExtract7
 
FROM
Clarity_Epp Epp 
left outer join clarity_epm epm on epm.payor_id = epp.PAYOR_ID
left outer join ZC_RECORD_STAT_EPP EPPRS on Epp.RECORD_STAT_EPP_C = EPPRS.RECORD_STAT_EPP_C  


--order by  RequiredExtract7 desc