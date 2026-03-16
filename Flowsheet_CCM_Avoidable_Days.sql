select flw.FlowsheetRowKey
    , flw.IdType
    , flw.Id
    , flw.FlowsheetRowEpicId
    , flw.Name
    , flw.DisplayName
    , pat.Name
    , pat.PrimaryMrn
    , pat.PatientKey
    , flw_fact.*
from flowsheetrowdim flw
    inner join flowsheetvaluefact flw_fact on flw.FlowsheetRowKey = flw_fact.FlowsheetRowKey
--    left outer join DateDim ddDOS on ddDOS.DateKey = billmed.ServiceDateKey
    inner join patientdim pat on flw_fact.PatientDurableKey = pat.DurableKey 
where flw.FlowsheetRowEpicId = '3042001573'
--    and DatePart("m", ddDOS.DateValue) = DatePart("m", DateAdd("m", -1, getdate())) AND DatePart("yyyy", ddDOS.DateValue) = DatePart("yyyy", DateAdd("m", -12, getdate()))
--    and flw_fact.LinkedToPatientEnteredFlowsheetEpisode = '33566975'
    and flw_fact.FirstDocumentedInstant 
            between '20181101'
                        and '20181119'

--    and flw_fact.PatientKey = 'Z3547271'

--select *
--from FlowsheetValueFact flw_fact
----where flw_fact.FlowsheetValueKey = '3042001573'
----where flw_fact.PatientDurableKey = 'Z3547271'
--where flw_fact.PatientDurableKey = '13447785'
--
--
--select *
--from patientdim pat 
--where pat.Name like 'BAILEY,JOSHUA MAURICE'


select *
from patientdim pat
where pat.PrimaryMrn = '1462514'