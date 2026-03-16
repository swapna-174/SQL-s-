select pat.Name
    , enc.Type
    , enc.EncounterEpicCsn
    , dd.DisplayString
    , dd.DateValue
    , dd.DayOfWeek
    , prov.ProviderEpicId
    , prov.Name as provider_name
--    , prov.ClinicianTitle
--    , prov.PrimaryLocation
--    , prov.PrimaryDepartment
    , prov.Type
--    , prc_dim.ProcedureEpicId
    , prc_dim.Name
    , prc_dim.code
    , prc_dim.Category
    , flo.TimeOfDayKey
    , flo_row.FlowsheetRowEpicId
    , flo_row.Name
    , flo_row.DisplayName
    , flo.Value
    , flo.Comment
--    , flo.TakenByEmployeeKey
    , emp.Name as taken_by
    , emp.EmployeeEpicId
    , emp_prov.Type
    , emp_prov.ClinicianTitle
    , dep.DepartmentName
    , prc.Source
from fullaccess.ProcedureOrderFact prc
    inner join fullaccess.ProcedureDim prc_dim on prc.ProcedureKey = prc_dim.ProcedureKey
    inner join fullaccess.encounterfact enc on prc.EncounterKey = enc.EncounterKey
    inner join fullaccess.patientdim pat on prc.PatientKey = pat.PatientKey
    inner join departmentdim dep on enc.DepartmentKey = dep.DepartmentKey
    inner join fullaccess.datedim dd on enc.DateKey = dd.DateKey
    inner join providerdim prov on prc.AuthorizedByProviderKey = prov.ProviderKey
    inner join flowsheetvaluefact flo on pat.PatientKey = flo.PatientKey
    inner join Flowsheetrowdim flo_row on flo.FlowsheetRowKey = flo_row.FlowsheetRowKey
    inner join employeedim emp on flo.TakenByEmployeeKey = emp.EmployeeKey
    inner join providerdim emp_prov on emp.name = emp_prov.name
where prov.ProviderKey > 1
--    and prc.Status <> 'Canceled'
--    and dd.year = '2017'
    and dd.datevalue >= '10/01/2017'
--    and prov.ProviderEpicId = '10407'
--    and prc.status = 'Completed'
    and prc_dim.code IN ('REF92A', 'REF98', 'REF91', 'REF8', 'REF33A', 'REF35', 'REF34', 'REF98', 'REF107', 'REF207', 'REF150', 'REF107A', 'REF208','REF26', 'NUR2306B')  
    and flo_row.FlowsheetRowEpicId = '1150003036'

/*
group by  pat.Name
    , enc.Type
    , enc.EncounterEpicCsn
    , dd.DisplayString
    , dd.DateValue
    , dd.DayOfWeek
    , prov.ProviderEpicId
    , prov.Name 
--    , prov.ClinicianTitle
--    , prov.PrimaryLocation
--    , prov.PrimaryDepartment
    , prov.Type
--    , prc_dim.ProcedureEpicId
    , prc_dim.Name
    , prc_dim.code
    , prc_dim.Category
    , flo_row.FlowsheetRowEpicId
    , flo_row.Name
    , flo_row.DisplayName
    , flo.Value
    , flo.Comment
--    , flo.TakenByEmployeeKey
    , emp.Name
    , emp.EmployeeEpicId
    , emp_prov.Type
    , emp_prov.ClinicianTitle
    , dep.DepartmentName
    , prc.Source
*/
 
 order by pat.Name asc