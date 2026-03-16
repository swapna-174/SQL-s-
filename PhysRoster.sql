/*
Optional Extract 1:  Physician Roster
File Description:  A list of active and inactive physicians that are / were employed at the hospital 
along with their corresponding hospital-specific physician codes, corresponding NPI numbers, and personal details.
*/

/*
SELECT
'PhysicianCode|PhysicianName|PhysicianNPI|PhysicianTaxonomy|PhysicianStatus' as OptionalExtract1
FROM DUAL
UNION
*/

SELECT
Case when ser.prov_id is not null then ser.prov_id else null end  as PhysicianCode -- 1. PhysicianCode
,
CASE when ser.prov_name is not Null then ser.prov_name  else Null end as PhysicianName -- 2. PhysicianName
,
CASE when ser2.npi is not Null then ser2.npi else Null end as PhysicianNPI -- 3. PhysicianNPI
,
null  as PhysicianTaxonomy -- 4. PhysicianTaxonomy
,
CASE when ACT.NAME is not Null then ACT.NAME else Null end as PhysicianStatus -- 5. PhysicianStatus

--as  OptionalExtract1

FROM
Clarity_ser ser 
LEFT OUTER JOIN Clarity_ser_2 ser2 on ser2.prov_id = ser.prov_id
LEFT OUTER JOIN ZC_ACTIVE_STATUS_2 ACT ON SER.ACTIVE_STATUS_C = ACT.ACTIVE_STATUS_2_C

WHERE
SER.PROV_ID IS NOT NULL 

--order by  OptionalExtract1 desc