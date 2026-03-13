	
SELECT distinct SurgicalCaseFact.SurgicalCaseEpicId as CaseId,
STRING_AGG (CAST(billed_Procedure.code as NVARCHAR(MAX)), '','')  WITHIN GROUP (ORDER BY billed_Procedure.code )  
	AS Code 
from CDW_Report.dbo.SurgicalCaseFact
 join CDW_Report.dbo.BillingAccountFact BillingAccountFact
 on SurgicalCaseFact.HospitalEncounterKey=BillingAccountFact.PrimaryEncounterKey and   CodingStatus in (''Completed'')
 	join CDW_Report.dbo.CodedProcedureFact CodedProcedureFact on  
	BillingAccountFact.billingaccountkey=CodedProcedureFact.billingaccountkey and CodedProcedureFact.PerformingProviderDurableKey >1
	join CDW_Report.dbo.ProcedureTerminologydim ProcedureTerminologydim
	on CodedProcedureFact.ProcedureTerminologyKey=ProcedureTerminologydim.ProcedureTerminologyKey
	join CDW_Report.dbo.ProcedureDim billed_Procedure on billed_Procedure.code=ProcedureTerminologydim.code
	JOIN CDW_Report.dbo.DateDim DateDim on SurgicalCaseFact.SurgeryDateKey = DateDim.DateKey 
AND DateDim.DateValue BETWEEN CAST(dateadd(MM, -12, getdate()) as date)  AND CAST(dateadd(DD, -8, getdate()) as date)
	---where SurgicalCaseEpicId=''1279630''
	group by SurgicalCaseFact.SurgicalCaseEpicId 