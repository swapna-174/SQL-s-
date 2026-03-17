with orp_equipment
as 
      ( select orp.OR_PROC_ID
            , orp.PROC_NAME
            , orp.PICKLIST_ID
            , LISTAGG(zc_equip.name,';') within group (order by or_equip.line) equipment_list
        from or_proc orp
            left outer join or_proc_equip or_equip on orp.OR_PROC_ID = or_equip.OR_PROC_ID
            left outer join ZC_OR_EQUIP_TYPE zc_equip on or_equip.SURG_EQUIP_REQ_C = zc_equip.SURG_EQUIPTYPE_C
--        where orp.OR_PROC_ID IN ('M--10661-10053-7', 'M-16491')
--        where orp.OR_PROC_ID IN ('M--10001-10051-256')
--            where orp.OR_PROC_ID in ('M-16489')
--           where orp.OR_PROC_ID IN ('M--10650-10052-413')
--        where orp.OR_PROC_ID in ('M-24399')
--        where orp.OR_PROC_ID in ('M--10181-10051-1160')
--        where orp.OR_PROC_ID in ('M-21143')
        where (regexp_like(orp.PROC_NAME, 'Langfitt','i') )
        group by orp.OR_PROC_ID
            , orp.PROC_NAME
            , orp.PICKLIST_ID
      )
, orp_instruments as 
      ( select orp.OR_PROC_ID
            , orp.PROC_NAME
            , orp.PICKLIST_ID
            , LISTAGG(zc_instr.name,';') within group (order by or_instr.line) instrument_list
        from or_proc orp
               left outer join or_proc_instr or_instr on orp.or_proc_id = or_instr.or_proc_id
               left outer join ZC_OR_INSTR_TYPE zc_instr on or_instr.INSTR_REQ_C = zc_instr.INSTRUMENT_TYPE_C
--        where orp.OR_PROC_ID IN ('M--10661-10053-7', 'M-16491')
--        where orp.OR_PROC_ID IN ('M--10001-10051-256')
--            where orp.OR_PROC_ID in ('M-16489')
--            where orp.OR_PROC_ID IN ('M--10650-10052-413')
--        where orp.OR_PROC_ID in ('M-24399')
--        where orp.OR_PROC_ID in ('M--10181-10051-1160')
--        where orp.OR_PROC_ID in ('M-21143')
        where (regexp_like(orp.PROC_NAME, 'Langfitt','i') )
        group by orp.OR_PROC_ID
            , orp.PROC_NAME
            , orp.PICKLIST_ID
      )

, orp_picklist as
          ( select orp.OR_PROC_ID
            , orp.PROC_NAME
            , orp.PICKLIST_ID
            , LISTAGG(sup.supply_name,';') within group (order by pklst.PICK_LIST_ID) supply_list
            from or_proc orp
                left outer join or_pklst pklst on orp.PICKLIST_ID = pklst.pick_list_id
                left outer join or_pklst_sup_list  suplst  on  suplst.pick_list_id = pklst.pick_list_id 
                left outer join or_sply  sup on  sup.supply_id = suplst.supply_id
--            where orp.OR_PROC_ID IN ('M--10661-10053-7', 'M-16491')
--            where orp.OR_PROC_ID IN ('M--10001-10051-256')
--            where orp.OR_PROC_ID in ('M-16489')
--            where orp.OR_PROC_ID IN ('M--10650-10052-413')
--            where orp.OR_PROC_ID in ('M-24399')
--            where orp.OR_PROC_ID in ('M--10181-10051-1160')
--            where orp.OR_PROC_ID in ('M-21143')
            where (regexp_like(orp.PROC_NAME, 'Langfitt','i') )
            group by orp.OR_PROC_ID
                , orp.PROC_NAME
                , orp.PICKLIST_ID
       )
       
select orp.OR_PROC_ID
    , orp.PROC_NAME
    , orp.PICKLIST_ID
    , orp_eq.equipment_list
    , orp_instr.instrument_list
    , orp_pklst.supply_list
 from or_proc orp
     inner join orp_equipment orp_eq on orp.or_proc_id = orp_eq.or_proc_id
    inner join orp_instruments orp_instr on orp.or_proc_id = orp_instr.or_proc_id
    inner join orp_picklist orp_pklst on orp.or_proc_id = orp_pklst.or_proc_id
--where orp.OR_PROC_ID in ('M-16489')
--where orp.OR_PROC_ID IN ('M--10650-10052-413')
--where orp.OR_PROC_ID in ('M-24399')
--where orp.OR_PROC_ID in ('M-21143')
where (regexp_like(orp.PROC_NAME, 'Langfitt','i') )
order by orp.OR_PROC_ID asc


