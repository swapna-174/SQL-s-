select distinct ndc.RAW_11_DIGIT_NDC DrugIdentifier,
	To_Char(Cast(btr.UPDATE_LOCAL_DTTM as Date), 'YYYYMMDD HH24:MI:SS') TransactionDate,
	btr.UPDATE_QTY_DIFF UnitQuantityUsed,
	odi.ACQUISITION_COST SalesPrice,
	case 
			when (odi2.MEDSYNC_SYNCFILL_YN = 'Y' or odi.FILL_SOURCE_C = 15 or om4.MEDSYNC_IS_SYNCED_YN = 'Y') then 'Y' 
			else 'N' 
		end Cyclefill,
	case 
			when odi.FILL_TYPE_C = 1 then 'N' 
			when odi.FILL_TYPE_C = 2 then 'Y' 
			else 'N' 
		end as Refill 
from bal_trail btr 
	inner join rx_ndc_status rx_ndc on btr.UPDATE_NDC_CSN = rx_ndc.CNCT_SERIAL_NUM 
	inner join rx_ndc ndc on rx_ndc.NDC_ID = ndc.NDC_ID 
	inner join BAL_PRD_BALANCE bal_prd on bal_prd.BAL_ID = btr.BAL_ID 
	left outer join ZC_UPDATE_REASON_3 zcur on btr.UPDATE_REASON_C = zcur.UPDATE_REASON_3_C 
	left outer join order_disp_info_2 odi2 on btr.UPDATE_ORDER_ID = odi2.ORDER_ID and btr.UPDATE_ORDER_DATE_REAL = odi2.CONTACT_DATE_REAL 
	left outer join order_disp_info odi on btr.UPDATE_ORDER_ID = odi.ORDER_MED_ID and btr.UPDATE_ORDER_DATE_REAL = odi.CONTACT_DATE_REAL 
	left outer join order_med_4 om4 on odi2.ORDER_ID = om4.ORDER_ID 
	left outer join ZC_CONTRACT_TYPE_2 zcct on odi2.CALC_ACCUM_C = zcct.CONTRACT_TYPE_2_C 
	left outer join rx_med_two rx2 on rx_ndc.MEDICATION_ID = rx2.MEDICATION_ID 
	left outer join RX_INVENTORY_LOC loc on bal_prd.INV_MASTER_LOC_ID = loc.INVENTORY_LOC_ID 
	left outer join RX_PHR phr on loc.PHR_ID = phr.PHARMACY_ID 
where btr.UPDATE_REASON_C = 1 
	and phr.NPI = 1073732376 
	and Trunc(btr.UPDATE_LOCAL_DTTM) >= Trunc(SysDate) - 3