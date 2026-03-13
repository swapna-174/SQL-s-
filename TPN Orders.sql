select *
from clarity_medication meds
   left outer join RX_MED_MIX_COMPON med_mix  on meds.medication_id = med_mix.medication_id
   left outer join clarity_medication meds_compon on med_mix.DRUG_ID = meds_compon.MEDICATION_ID
    left outer join RX_MED_AHFS rx_med_compon  on med_mix.DRUG_ID = rx_med_compon.MEDICATION_ID

--where meds.name like '%TPN%'
--where meds.name like '%SELENIUM%'
where meds.MEDICATION_ID IN ('432369', '432398', '433076', '432383', '432236', '433074') 