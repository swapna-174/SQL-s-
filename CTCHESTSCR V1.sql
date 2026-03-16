SELECT
	ordprc.ORDER_PROC_ID "Order ID"
	,ordstatus.NAME "Order Status"
	,ordprc.ORDER_INST "Order Date"
	,ordprc.PROC_CODE "Procedure Code"
	,ordprc.DESCRIPTION "Procedure Description"
	,pat.PAT_MRN_ID "MRN"
	,pat.PAT_NAME "Patient Name"
	,ser.PROV_NAME "Authorizing Provider"

FROM
	ORDER_PROC ordprc
	INNER JOIN PATIENT pat ON ordprc.PAT_ID = pat.PAT_ID
	INNER JOIN CLARITY_SER ser ON ser.PROV_ID = ordprc.AUTHRZING_PROV_ID
		LEFT JOIN ZC_ORDER_STATUS ordstatus ON ordprc.ORDER_STATUS_C = ordstatus.ORDER_STATUS_C

WHERE
	ordprc.PROC_ID = 103599
	AND ordprc.ORDER_INST BETWEEN to_date('2013-07-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss') AND to_date('2015-02-26 23:59:59', 'yyyy-mm-dd hh24:mi:ss')

ORDER BY
	"Patient Name"
	,"Order Date"
	