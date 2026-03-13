select *from  patientdim where primarymrn='2026394'


select *from MedicationDispenseFact  where patientdurablekey=32843916
and medicationkey in (122827,
122983,
123096,
126793,
128007,
128025,
128200,
128206,
138549,
138551)
and EncounterKey=229104518

select *from medicationdim where  Name like LOWER('%CANNABIDIOL%')


select distinct  patientdim.primarymrn,
patientdim.Name,
CAST(MedicationOrderFact.OrderedInstant  as date) OrderDate,
OrderName---MedOrderName
from MedicationOrderFact
Join  patientdim 
on MedicationOrderFact.PatientDurableKey=patientdim.DurableKey
where CAST(MedicationOrderFact.OrderedInstant as date ) between CAST('4-26-2022' as date)  and 
CAST('4-26-2023' as date)
and (MedicationOrderFact.AuthorizedByProviderDurableKey=2813 or 
MedicationOrderFact.OrderedByProviderDurableKey=2813) 
and  OrderName like '%cannabidioL%'  
order by CAST(MedicationOrderFact.OrderedInstant  as date)  desc



select *from medicationorderfact where patientdurablekey = 33052779
 and   OrderName like '%cannabidioL%' and 
 CAST(MedicationOrderFact.OrderedInstant as date )=CAST('2022-05-31'




select CAST('4-26-2022' as date)
select *from MedicationOrderFact where MedicationOrderEpicId =701852532
select *from encounterfact where EncounterEpicCsn=30177258698

select *from providerdim where providerkey=439775