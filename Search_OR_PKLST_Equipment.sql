select orp.OR_PROC_ID
    , orp.PROC_NAME
    , orp.PICKLIST_ID
--    , orp.PROC_DESC
--    , orp.PROC_NOTES
--    , or_equip.LINE
--    , or_equip.SURG_EQUIP_REQ_C
    , or_equip.SRG_EQP_REQ_YN
    , zc_equip.name as equipment_needed
--    , LISTAGG(zc_equip.name,',') within group (order by orp.OR_PROC_ID) equip_NAME_LIST
--    , orp.REC_TYP_C
--    , or_instr.LINE
--    , or_instr.INSTR_REQ_YN
--    , zc_instr.name as instrument_required
--    , LISTAGG(zc_instr.name,',') within group (order by orp.OR_PROC_ID) instrument_NAME_LIST
--    , zc_rec.name as record_type
--    , pklst.PICK_LIST_ID
--    , pklst.PICK_LIST_NAME
--    , suplst.supply_id
--    , suplst.LINE
--    , sup.supply_name
----    , LISTAGG(sup.supply_name,',') within group (order by pklst.PICK_LIST_ID) supply_NAME_LIST
--    , suplst.NUM_NEEDED_OPEN
--    , suplst.NUM_SUPPLIES_PRN
--    , suplst.SUPPLY_INV_LOC_ID
from or_proc orp
    left outer join or_proc_equip or_equip on orp.OR_PROC_ID = or_equip.OR_PROC_ID
    left outer join ZC_OR_EQUIP_TYPE zc_equip on or_equip.SURG_EQUIP_REQ_C = zc_equip.SURG_EQUIPTYPE_C
--    left outer join or_proc_instr or_instr on orp.or_proc_id = or_instr.or_proc_id
--    left outer join ZC_OR_INSTR_TYPE zc_instr on or_instr.INSTR_REQ_C = zc_instr.INSTRUMENT_TYPE_C
--    left outer join zc_proc_rec_type zc_rec on orp.REC_TYP_C = zc_rec.proc_rec_type_c
--    left outer join or_pklst pklst on orp.PICKLIST_ID = pklst.pick_list_id
--    left outer join or_pklst_sup_list  suplst  on  suplst.pick_list_id = pklst.pick_list_id 
--    left outer join or_sply  sup on  sup.supply_id = suplst.supply_id
    
--    left outer join or_proc_mod_ser_index or_index on orp.OR_PROC_ID = or_index.or_proc_id
--where orp.or_proc_id = '1170'
--where orp.PICKLIST_ID is not null
--where orp.OR_PROC_ID IN ('M--10661-10053-7')--  'M-16491')
--where or_index.pmods_ser_index_id like 'SCOTT, AARON%'
--where orp.PICKLIST_ID = '1180363988'
    left outer join OR_PROC_MOD_SER_INDEX  orp_ser on orp.OR_PROC_ID = orp_ser.or_proc_id
--    left outer join OR_PROC_MOD_ORP_INDEX orp_proc on orp.OR_PROC_ID = orp_proc.or_proc_id 
    left outer join clarity_ser ser on orp_ser.PMODS_SER_INDEX_ID = ser.prov_id

where (regexp_like(orp.PROC_NAME, 'Langfitt','i') )
--where orp_ser.PMODS_SER_INDEX_ID = '10298'

--where orp.or_proc_id IN ('M--10298-10052-296', 'M--10387-10051-296', 'M--10709-10051-296', 'M--10709-10052-296')


--    and orp.OR_PROC_ID = 'M-21071'
--    and ( orp.OR_PROC_ID IN {?Dept_id} OR 0 IN {?Dept_ID})

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
    
order by orp.OR_PROC_ID asc, or_equip.line asc --, suplst.PICK_LIST_ID asc, suplst.LINE asc