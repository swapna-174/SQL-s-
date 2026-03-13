with BALREC as 
	(
	select distinct ndc.RAW_11_DIGIT_NDC DrugIdentifier,
		cm.NAME DrugName,
		To_Char(cm.GPI) GenericEquivalencyCode,
		NVL(bal_ndc.NDC_DEFAULT_DISP_YN, 'N') PreferredDrug,
		ndc.MFG_LONG_NAME Manufacturer,
		cm.STRENGTH Strength,
		cm.DEA_CLASS_CODE_C DEAClass,
		case 
				when rx1.DISP_PRODUCT is NULL then 'Y' 
				else 'N' 
			end GenericIndicator,
		case 
				when ndc.LEGEND_INDICATOR_C = 2 then 'Y' 
				else 'N' 
			end OTC,
		Round(ndc.PACKAGE_SIZE, 2) * Round(ndc.PACKAGE_QUANTITY, 2) UnitCount,
		zcmu.NAME UnitType,
		NVL(bal_ndc.NDC_DISP_PKG_YN, 'N') UnitDose,
		NVL(bal_ndc.NDC_NOT_ORDERABLE_YN, 'N') Inactive,
		case 
				when prd_info.USE_SPEC_MEDS_YN = 'Y' then 1 
				when prd_info.USE_SPEC_MEDS_YN = 'N' and pac_sz.MED_PACKAGE_SIZE is NULL then 2 
				when prd_info.USE_SPEC_MEDS_YN = 'N' and pac_sz.MED_PACKAGE_SIZE > 0 then 3 
			end as EquivalentType,
		prd_info.RECORD_ID PRD,
		bal_ndc.BAL_ID 
	from bal_ndc_balance bal_ndc 
		left outer join 
		(
		select * 
		from 
			(
			select rxstat.MEDICATION_ID,
				rxstat.CNCT_SERIAL_NUM LVCDR,
				rxstat.NDC_ID,
				Row_Number() 
			over 
				(
				partition by rxstat.NDC_ID 
				order by rxstat.CNCT_SERIAL_NUM Desc
				) SEQ_NUM 
			from RX_NDC_STATUS rxstat 
			where rxstat.CNCT_STAT_NAME is Null
			) 
		where SEQ_NUM = 1
		) RXS on bal_ndc.NDC_ID = RXS.NDC_ID 
		inner join RX_NDC ndc on ndc.NDC_ID = bal_ndc.NDC_ID 
		inner join BAL_PRD_BALANCE bal_prd on bal_ndc.BAL_ID = bal_prd.BAL_ID 
		inner join PRD_WIDGET_INFO prd_info on bal_prd.LINKED_WIDGET_ID = prd_info.RECORD_ID 
		inner join PRD_MEDICATIONS prd_med on prd_info.RECORD_ID = prd_med.RECORD_ID 
		left outer join rx_med_one rx1 on prd_med.MEDICATION_ID = rx1.MEDICATION_ID 
		left outer join clarity_medication cm on prd_med.MEDICATION_ID = cm.MEDICATION_ID 
		left outer join prd_package_sizes pac_sz on prd_info.RECORD_ID = pac_sz.RECORD_ID 
		left outer join zc_med_unit zcmu on ndc.MED_UNIT_C = zcmu.DISP_QTYUNIT_C 
		left outer join RX_INVENTORY_LOC loc on bal_prd.INV_MASTER_LOC_ID = loc.INVENTORY_LOC_ID 
		left outer join RX_PHR phr on loc.PHR_ID = phr.PHARMACY_ID 
	where bal_ndc.NDC_BALANCE > 0 
		and phr.NPI = 1386891141 

	union

	select distinct ndc.RAW_11_DIGIT_NDC DrugIdentifier,
		cm.NAME DrugName,
		To_Char(cm.GPI) GenericEquivalencyCode,
		NVL(bal_ndc.NDC_DEFAULT_DISP_YN, 'N') PreferredDrug,
		ndc.MFG_LONG_NAME Manufacturer,
		cm.STRENGTH Strength,
		cm.DEA_CLASS_CODE_C DEAClass,
		case 
				when rx1.DISP_PRODUCT is NULL then 'Y' 
				else 'N' 
			end GenericIndicator,
		case 
				when ndc.LEGEND_INDICATOR_C = 2 then 'Y' 
				else 'N' 
			end OTC,
		Round(ndc.PACKAGE_SIZE, 2) * Round(ndc.PACKAGE_QUANTITY, 2) UnitCount,
		zcmu.NAME UnitType,
		NVL(bal_ndc.NDC_DISP_PKG_YN, 'N') UnitDose,
		NVL(bal_ndc.NDC_NOT_ORDERABLE_YN, 'N') Inactive,
		case 
				when prd_info.USE_SPEC_MEDS_YN = 'Y' then 1 
				when prd_info.USE_SPEC_MEDS_YN = 'N' and pac_sz.MED_PACKAGE_SIZE is NULL then 2 
				when prd_info.USE_SPEC_MEDS_YN = 'N' and pac_sz.MED_PACKAGE_SIZE > 0 then 3 
			end as EquivalentType,
		prd_info.RECORD_ID PRD,
		bal_ndc.BAL_ID 
	from bal_ndc_balance bal_ndc 
		inner join 
		(
		select * 
		from 
			(
			select rxstat.MEDICATION_ID,
				rxstat.CNCT_SERIAL_NUM LVCDR,
				rxstat.NDC_ID,
				Row_Number() 
			over 
				(
				partition by rxstat.NDC_ID 
				order by rxstat.CNCT_SERIAL_NUM Desc
				) SEQ_NUM 
			from RX_NDC_STATUS rxstat 
			where rxstat.CNCT_STAT_NAME is Null
			) 
		where SEQ_NUM = 1
		) RXS on bal_ndc.NDC_ID = RXS.NDC_ID 
		inner join RX_NDC ndc on ndc.NDC_ID = bal_ndc.NDC_ID 
		inner join BAL_PRD_BALANCE bal_prd on bal_ndc.BAL_ID = bal_prd.BAL_ID 
		inner join PRD_WIDGET_INFO prd_info on bal_prd.LINKED_WIDGET_ID = prd_info.RECORD_ID 
		inner join PRD_MEDICATIONS prd_med on prd_info.RECORD_ID = prd_med.RECORD_ID 
		left outer join rx_med_one rx1 on prd_med.MEDICATION_ID = rx1.MEDICATION_ID 
		left outer join clarity_medication cm on prd_med.MEDICATION_ID = cm.MEDICATION_ID 
		left outer join prd_package_sizes pac_sz on prd_info.RECORD_ID = pac_sz.RECORD_ID 
		left outer join zc_med_unit zcmu on ndc.MED_UNIT_C = zcmu.DISP_QTYUNIT_C 
		left outer join RX_INVENTORY_LOC loc on bal_prd.INV_MASTER_LOC_ID = loc.INVENTORY_LOC_ID 
		left outer join RX_PHR phr on loc.PHR_ID = phr.PHARMACY_ID 
	where (bal_ndc.NDC_BALANCE = 0 or bal_ndc.NDC_BALANCE is Null) 
		and bal_ndc.NDC_DEFAULT_DISP_YN = 'Y' 
		and phr.NPI = 1386891141
	), BALUPD as 
	(
	select distinct ndc.RAW_11_DIGIT_NDC DrugIdentifier,
		cm.NAME DrugName,
		To_Char(cm.GPI) GenericEquivalencyCode,
		NVL(BALNDC.NDC_DEFAULT_DISP_YN, 'N') PreferredDrug,
		ndc.MFG_LONG_NAME Manufacturer,
		cm.STRENGTH Strength,
		cm.DEA_CLASS_CODE_C DEAClass,
		case 
				when rx1.DISP_PRODUCT is NULL then 'Y' 
				else 'N' 
			end GenericIndicator,
		case 
				when ndc.LEGEND_INDICATOR_C = 2 then 'Y' 
				else 'N' 
			end OTC,
		Round(ndc.PACKAGE_SIZE, 2) * Round(ndc.PACKAGE_QUANTITY, 2) UnitCount,
		zcmu.NAME UnitType,
		NVL(BALNDC.NDC_DISP_PKG_YN, 'N') UnitDose,
		NVL(BALNDC.NDC_NOT_ORDERABLE_YN, 'N') Inactive,
		case 
				when prd_info.USE_SPEC_MEDS_YN = 'Y' then 1 
				when prd_info.USE_SPEC_MEDS_YN = 'N' and pac_sz.MED_PACKAGE_SIZE is NULL then 2 
				when prd_info.USE_SPEC_MEDS_YN = 'N' and pac_sz.MED_PACKAGE_SIZE > 0 then 3 
			end as EquivalentType,
		prd_info.RECORD_ID PRD,
		bal_trl.BAL_ID 
	from bal_trail bal_trl 
		inner join 
		(
		select * 
		from 
			(
			select bal_ndc.NDC_DEFAULT_DISP_YN,
				bal_ndc.NDC_ID,
				bal_ndc.NDC_BALANCE,
				bal_ndc.BAL_ID,
				bal_ndc.NDC_NOT_ORDERABLE_YN,
				bal_ndc.NDC_DISP_PKG_YN,
				phr.NPI,
				bal_prd.INV_MASTER_LOC_ID,
				Row_Number() 
			over 
				(
				partition by bal_ndc.BAL_ID 
				order by bal_ndc.BAL_ID, bal_ndc.NDC_DEFAULT_DISP_YN, bal_ndc.LINE, bal_ndc.NDC_ID
				) as DocsRow 
			from bal_ndc_balance bal_ndc 
				inner join BAL_PRD_BALANCE bal_prd on bal_ndc.BAL_ID = bal_prd.BAL_ID 
				inner join RX_INVENTORY_LOC loc on bal_prd.INV_MASTER_LOC_ID = loc.INVENTORY_LOC_ID 
				inner join RX_PHR phr on loc.PHR_ID = phr.PHARMACY_ID and phr.npi = 1386891141
			) 
		where DocsRow = 1
		) BALNDC on bal_trl.BAL_ID = BALNDC.BAL_ID 
		inner join RX_NDC ndc on ndc.NDC_ID = BALNDC.NDC_ID 
		inner join BAL_PRD_BALANCE bal_prd on bal_trl.BAL_ID = bal_prd.BAL_ID 
		inner join PRD_WIDGET_INFO prd_info on bal_prd.LINKED_WIDGET_ID = prd_info.RECORD_ID 
		inner join PRD_MEDICATIONS prd_med on prd_info.RECORD_ID = prd_med.RECORD_ID 
		left outer join prd_package_sizes pac_sz on prd_info.RECORD_ID = pac_sz.RECORD_ID 
		left outer join rx_med_one rx1 on prd_med.MEDICATION_ID = rx1.MEDICATION_ID 
		left outer join clarity_medication cm on prd_med.MEDICATION_ID = cm.MEDICATION_ID 
		left outer join zc_med_unit zcmu on ndc.MED_UNIT_C = zcmu.DISP_QTYUNIT_C 
	where bal_trl.UPDATE_DATETIME >= Trunc(Add_Months(epic_util.efn_din(SysDate), -24), 'MM') 
		and bal_trl.UPDATE_REASON_C = 1 
		and not exists 
		(
		select blr.BAL_ID 
		from BALREC blr 
		where bal_trl.BAL_ID = blr.BAL_ID
		
	)) 
select * 
from BALREC 

union

select * 
from BALUPD