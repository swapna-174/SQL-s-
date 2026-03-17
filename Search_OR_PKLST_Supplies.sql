select orp.OR_PROC_ID
    , orp.PROC_NAME
    , orp.PICKLIST_ID
    , ser.prov_id
    , ser.prov_name
--    , orp_ser.*
--    , orp.PROC_DESC
--    , orp.PROC_NOTES
--    , or_equip.LINE
--    , or_equip.SURG_EQUIP_REQ_C
--    , or_equip.SRG_EQP_REQ_YN
--    , zc_equip.name as equipment_needed
--    , LISTAGG(zc_equip.name,',') within group (order by orp.OR_PROC_ID) equip_NAME_LIST
--    , orp.REC_TYP_C
--    , or_instr.LINE
--    , or_instr.INSTR_REQ_YN
--    , zc_instr.name as instrument_required
--    , LISTAGG(zc_instr.name,',') within group (order by orp.OR_PROC_ID) instrument_NAME_LIST
--    , zc_rec.name as record_type
--    , pklst.PICK_LIST_ID
--    , pklst.PICK_LIST_NAME
    , suplst.supply_id
--    , sup.TYPE_OF_ITEM_C
--    , suplst.LINE
    , sup.ABBR
    , zc_sup.name as supplier
    , suppl.supplier_ctlg_num
    , zc_manf.name as manufacturer
    , manf.man_ctlg_num
    , zc_item.name as type_of_item
    , sup.supply_name
----    , LISTAGG(sup.supply_name,',') within group (order by pklst.PICK_LIST_ID) supply_NAME_LIST
    , suplst.NUM_NEEDED_OPEN
    , suplst.NUM_SUPPLIES_PRN
from or_proc orp
    left outer join or_pklst pklst on orp.PICKLIST_ID = pklst.pick_list_id
    left outer join or_pklst_sup_list  suplst  on  suplst.pick_list_id = pklst.pick_list_id 
    left outer join or_sply  sup on  sup.supply_id = suplst.supply_id
    left outer join or_sply_supplier suppl on sup.supply_id = suppl.item_id
    left outer join OR_SPLY_MANFACTR manf on sup.SUPPLY_ID = manf.item_id
    left outer join zc_or_supplier zc_sup on suppl.SUPPLIER_C = zc_sup.supplier_c
    left outer join ZC_OR_MANUFACTURER zc_manf on manf.MANUFACTURER_C = zc_manf.manufacturer_c
    left outer join ZC_OR_TYPE_OF_ITEM zc_item on sup.TYPE_OF_ITEM_C = zc_item.type_of_item_c
    left outer join OR_PROC_MOD_SER_INDEX  orp_ser on orp.OR_PROC_ID = orp_ser.or_proc_id
--    left outer join OR_PROC_MOD_ORP_INDEX orp_proc on orp.OR_PROC_ID = orp_proc.or_proc_id 
    left outer join clarity_ser ser on orp_ser.PMODS_SER_INDEX_ID = ser.prov_id
where (regexp_like(orp.PROC_NAME, 'Langfitt','i')) 
--where orp_ser.PMODS_SER_INDEX_ID = '10298'

--where orp.picklist_id = '1180290809'


--where pklst.PICK_LIST_NAME = 'ABLATION A FLUTTER RIGHT - EP'
--where orp.PICKLIST_ID = '1181026795'
--group by orp.OR_PROC_ID
--    , orp.PROC_NAME
--    , orp.PICKLIST_ID
--    , orp.PROC_DESC
--    , orp.PROC_NOTES
--    , or_equip.LINE
--    , zc_equip.name
--    , or_instr.LINE
--    , zc_instr.name
----    , zc_rec.name
--    , pklst.PICK_LIST_NAME
--    , suplst.supply_id
--    , suplst.LINE
--    , sup.supply_name
--    , suplst.NUM_NEEDED_OPEN
--    , suplst.NUM_SUPPLIES_PRN
--    , suplst.SUPPLY_INV_LOC_ID
    
order by orp.OR_PROC_ID asc, suplst.PICK_LIST_ID asc, suplst.LINE asc