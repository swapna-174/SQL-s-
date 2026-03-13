
SELECT distinct 
SurgicalCaseFact.SurgicalCaseEpicId,
 SurgicalCaseFact.ImplantableSupplyUsedCharge,
 SurgicalCaseFact. ImplantableSupplyWastedCharge,
 SurgicalCaseFact.NonImplantableSupplyUsedCharge,
 SurgicalCaseFact.NonImplantableSupplyWastedCharge,
 SurgicalCaseFact.ImplantableSupplyUsedCost,
 SurgicalCaseFact. ImplantableSupplyWastedCost,
 SurgicalCaseFact.NonImplantableSupplyUsedCost,
 SurgicalCaseFact.NonImplantableSupplyWastedCost,
 BillingAccountFact.AccountEpicId as HAR ,
 SurgicalCaseFact.SuppliesUsedCost,
 SurgicalCaseFact.SuppliesWastedCost,
    EncounterFact.PatientKey,
    EncounterFact.AgeKey,
    EncounterFact.primarydiagnosiskey,
    EncounterFact.primarycoveragekey,
    EncounterFact.ReferringProviderKey,
    EncounterFact.PatientClass,
    EncounterFact.count,
    SurgicalCaseFact.PrimarySurgeonKey,
    Providerdim.Name as ProviderName,
    SurgicalCaseFact.PrimaryProcedureKey,
    SurgicalCaseFact.SurgeryDateKey,
	SurgicalCaseFact.TotalCost,
    DateDim.DateValue,
    SurgicalCaseFact.OperatingRoomKey,
    SurgicalCaseFact.PatientInRoomInstant,
    SurgicalCaseFact.PatientOutOfRoomInstant,
    SurgicalCaseFact.SurgeryPatientClass,
    SurgicalCaseFact.AdmissionPatientClass,
    SurgicalCaseFact.PrimaryService,
    SurgicalCaseFact.count as SurgicalCaseCount,
    SurgicalSupplyUseFact.SurgicalSupplyKey,
    SurgicalSupplyDim.Name as SurgicalSupplyName,
	SurgicalSupplyDim.Type  ,
	SurgicalSupplyDim.PrimaryManufacturer,
	SurgicalSupplyDim.PrimaryManufacturerId,
	SurgicalSupplyDim.PrimaryManufacturerCatalogNumber,
	SurgicalSupplyDim.PrimaryVendorCatalogNumber,
	SurgicalSupplyDim.Implant,
	SurgicalSupplyDim.PrimaryExternalId,
	SurgicalSupplyDim.SurgicalSupplyEpicId,
	SurgicalCaseFact.SurgeonTotalDurationInMinutes,
	SurgicalCaseFact.AnesthesiaProviderTotalDurationInMinutes,
    SurgicalSupplyUseFact.InventoryLocationKey,
    SurgicalSupplyUseFact.NumberUsed,
    SurgicalSupplyUseFact.NumberWasted,
    SurgicalSupplyUseFact.NumberOpen,
    SurgicalSupplyUseFact.NumberPrn,
    SurgicalSupplyUseFact.UnitCost,
    SurgicalSupplyUseFact.Chargeable,
    SurgicalSupplyUseFact.Count  as SurgicalSupplyCount,
	patientdim.PrimaryMrn,
	DepartmentDim.RoomGroupName,
DepartmentDim.RoomName,
ProcedureDim.Name,
billed_Procedure.Name as Billed_ProcedureName,
PlaceOfServiceDim.Name Facility_name,
AnesthesiaStopTimeOfDayKey,
AnesthesiaStartTimeOfDayKey,
ScheduledOutOfRoomInstant,
ScheduledInRoomInstant,
DATEDIFF(MINUTE, SurgicalCaseFact.PatientInRoomInstant, SurgicalCaseFact.PatientOutOfRoomInstant   ) Total_Duration,
DATEDIFF(MINUTE,AnesthesiaStartInstant,AnesthesiaStopInstant  ) as Anesthesia_Duration,
billed_Procedure.code as code,
billed_Procedure.codeset as codeset
,Case when SurgicalSupplyDim.Implant =1 then 'Yes' Else 'No' End  as impant_flg
,ProviderDim.AcademicDepartment_X as AcademicDepartment_X
,ProviderDim.SurgicalDepartment_X as SurgicalDepartment_X
,CAST(NULL as NVARCHAR(MAX) )as Billedproc_code
FROM
CDW_Report.dbo.SurgicalSupplyUseFact SurgicalSupplyUseFact
        JOIN CDW_Report.dbo.SurgicalCaseFact SurgicalCaseFact 
        ON SurgicalSupplyUseFact.SurgicalCaseKey = SurgicalCaseFact.SurgicalCaseKey 
		 join CDW_Report.dbo.BillingAccountFact BillingAccountFact on SurgicalCaseFact.HospitalEncounterKey=BillingAccountFact.PrimaryEncounterKey and   CodingStatus in (''Completed'')
	join CDW_Report.dbo.CodedProcedureFact CodedProcedureFact on  BillingAccountFact.billingaccountkey=CodedProcedureFact.billingaccountkey and CodedProcedureFact.PerformingProviderDurableKey >1
	join CDW_Report.dbo.ProcedureTerminologydim ProcedureTerminologydim on CodedProcedureFact.ProcedureTerminologyKey=ProcedureTerminologydim.ProcedureTerminologyKey
	join CDW_Report.dbo.ProcedureDim billed_Procedure on billed_Procedure.code=ProcedureTerminologydim.code
        JOIN CDW_Report.dbo.EncounterFact EncounterFact 
        ON SurgicalCaseFact.HospitalEncounterKey = EncounterFact.EncounterKey 
        JOIN CDW_Report.dbo.EncounterFact EncounterFactSurg
        ON SurgicalCaseFact.SurgeryEncounterKey = EncounterFactSurg.EncounterKey
			join CDW_Report.dbo.PlaceOfServiceDim PlaceOfServiceDim on EncounterFactSurg.PlaceOfServiceKey=PlaceOfServiceDim.PlaceOfServiceKey
        LEFT JOIN CDW_Report.dbo.drgeventfact drgeventfact 
        ON SurgicalCaseFact.HospitalEncounterKey = drgeventfact.encounterkey AND drgeventfact.DrgType = ''MS-DRG''
	join CDW_Report.dbo.patientdim  patientdim  on SurgicalCaseFact.PatientDurableKey=patientdim.DurableKey
JOIN CDW_Report.dbo.ProviderDim ProviderDim on SurgicalCaseFact.PrimarySurgeonKey = ProviderDim.ProviderKey
join CDW_Report.dbo.DepartmentDim DepartmentDim on SurgicalCaseFact.OperatingRoomKey =DepartmentDim.DepartmentKey 
        JOIN CDW_Report.dbo.DateDim DateDim on SurgicalCaseFact.SurgeryDateKey = DateDim.DateKey 
		join CDW_Report.dbo.ProcedureDim ProcedureDim on SurgicalCaseFact.PrimaryProcedureKey=ProcedureDim.DurableKey and ProcedureDim.IScurrent=1 and ProcedureDim.code <> ''*Unspecified''--134982
        Join CDW_Report.dbo.SurgicalSupplyDim SurgicalSupplyDim on SurgicalSupplyUseFact.SurgicalSupplyKey = SurgicalSupplyDim.SurgicalSupplyKey
		              
WHERE 
 DateDim.DateValue BETWEEN CAST(dateadd(MM, -12, getdate()) as date)  AND CAST(dateadd(DD, -8, getdate()) as date)