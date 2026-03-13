select rx_med.MEDICATION_ID
	, rx_med.BILLING_CODE
	, rx_med.OVERRIDE_BILL_NAME
	, rx_med.MFG_LONG_NAME
	, rx_med.GROUPER_ID
	, med.MEDICATION_ID
	, med.NAME
	, med.GENERIC_NAME
	, med.THERA_CLASS_C
	, med.PHARM_CLASS_C
	, med.PHARM_SUBCLASS_C
	, med.STRENGTH
	, med.FORM
	, med.ROUTE
from rx_med_one rx_med
	left outer join clarity_medication med on rx_med.MEDICATION_ID = med.medication_id
--where rx_med.grouper_id IN ('133697', '129947')
--where med.FORM = 'IUD'
where med.ROUTE IN ('Intrauterine', 'Subdermal')