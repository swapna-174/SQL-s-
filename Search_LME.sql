select *
from med_cvg_info mci
	left outer join med_cvg_details mcvg on mci.MED_ESTIMATE_ID = mcvg.med_estimate_id
	left outer join med_cvg_status_details mcvg_stat on mci.MED_ESTIMATE_ID = mcvg_stat.med_estimate_id
	left outer join MED_CVG_ESTIMATE_VALS mci_e on mci.MED_ESTIMATE_ID = mci_e.med_estimate_id
--where mci.med_estimate_id = '240'

--where mci.MED_ESTIMATE_ID = '227225'

where trunc(mci.RECORD_CREATION_DATE) >= '15-JUL-2021'
	and mci.EPRESCRIBING_NET_ID = '1100101'
--	and mci.CNCT_TYPE_C = '2'



--				227225