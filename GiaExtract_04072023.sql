
select distinct patientdim.PrimaryMrn Mrn,
patientdim.FirstName,
patientdim.LastName,
COALESCE(patientdim.HomePhoneNumber,patientdim.WorkPhoneNumber) as [Mobile Phone Number],
patientdim.BirthDate DOB,
ScheduledExamInstant [Appointment Date],
DepartmentDim.DepartmentExternalName [Site Location],
patientdim.EmailAddress,
ImagingFact.PatientClass [Appointment Type ]
from ImagingFact join  
patientdim  on ImagingFact.patientdurablekey=patientdim.DurableKey and Patientdim.Test=0 and Patientdim.Status='Alive'
and patientdim.IsCurrent=1  and CAST(ImagingFact.ScheduledExamInstant as date) > CAST(getdate()  as date)

and ImagingFact.PerformingDepartmentKey in (11887,2609) -----WD181 02 MAMMOGRAPHY IMAGING CORNERSTONE---PD515 MAMMOGRAPHY--Westchester Medical Plaza and HIGH POINT - 4515 PREMIER DR 
join ProcedureDim OrginalProc on ImagingFact.OriginalProcedureDurableKey=OrginalProc.DurableKey 
join DepartmentDim on ImagingFact.PerformingDepartmentKey=DepartmentDim.DepartmentKey
join ProcedureDim on ImagingFact.FirstProcedureDurableKey=ProcedureDim.DurableKey
join datedim on ScheduledExamDateKey=DateDim.DateKey
where proceduredim.Name like '%MAMMOGRAM%' or OrginalProc.Name like '%MAMMOGRAM%'
order by ScheduledExamInstant asc




