select ip_data_grp.FLO_MEAS_ID as "Flowsheet ID - Group"
    , ip_data_grp.FLO_MEAS_NAME as "Flowsheet Name - Group" 
    , ip_data_grp.DISP_NAME
    , ip_data_grp.FLO_ROW_STATUS_C
--    , ip_cnct.contact_date_real
    , ip_flo.line
    , ip_data_row.FLO_MEAS_ID as "Flowsheet ID - Row"
    , ip_data_row.FLO_MEAS_NAME as "Flowsheet Name - Row"
from ip_flo_gp_data ip_data_grp
    inner join ip_flo_ovrtm_sngl ip_cnct on ip_data_grp.FLO_MEAS_ID = ip_cnct.ID
               and ip_cnct.contact_date_real = (Select max(ip_cnct_2.contact_date_real) from ip_flo_ovrtm_sngl ip_cnct_2 where ip_data_grp.FLO_MEAS_ID = ip_cnct_2.ID)
--    inner join ip_flo_ovrtm_sngl ip_cnct on ip_data_grp.FLO_MEAS_ID = ip_cnct.ID
--            and ip_cnct.CONTACT_DATE_REAL = '63648'
    left outer join IP_FLO_MEASUREMNTS  ip_flo on ip_data_grp.FLO_MEAS_ID = ip_flo.ID
               and ip_flo.contact_date_real= (Select max(ip_flo2.contact_date_real) from IP_FLO_MEASUREMNTS ip_flo2 where ip_data_grp.FLO_MEAS_ID = ip_flo2.ID)
    left outer join ip_flo_gp_data ip_data_row on ip_flo.MEASUREMENT_ID = ip_data_row.FLO_MEAS_ID
--where ip_data_row.flo_meas_id IN ('3040102871','301370','301400','1607','9064','3044000146','3048000178')
--where ip_data_grp.flo_meas_id IN ('3042000107', '3042000088', '3040100260', '3040101320', '302700')
--where ip_data_row.FLO_MEAS_ID IN ('302700', '302680', '302690', '3040100963')
--where ip_data_row.FLO_MEAS_NAME like '%DME%'
--where ip_data_grp.FLO_MEAS_ID = '3044000075'        --  G WH CC ASSESSMENT Group
--where ip_data_grp.FLO_MEAS_ID = '3044000082'        --  R WH CC PATIENT HAS THE FOLLOWING DME
--where ip_data_grp.FLO_MEAS_NAME LIKE 'G WH CC%'
where ip_data_grp.flo_meas_id = '301320'

order by ip_data_grp.FLO_MEAS_ID asc, ip_flo.LINE asc
  

/*
select *
from ip_flo_ovrtm_sngl ip_flo
where ip_flo.id = '30450000001'
*/


/*   
select ip_data.flo_meas_id
    , ip_data.FLO_MEAS_NAME
    , ip_data.DISP_NAME
    , ip_data.FLO_ROW_STATUS_C
from ip_flo_gp_data ip_data
where ip_data.flo_meas_id = '3048005095'
*/