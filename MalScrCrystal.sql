SELECT
pat.PAT_MRN_ID
,pat.PAT_NAME
,enc.PAT_ENC_CSN_ID
,enc.DEPARTMENT_ID
,dep.DEPARTMENT_NAME
,parloc.LOC_NAME
,empe.NAME  "ENTERED_BY"
, ip_data_row.FLO_MEAS_NAME as "Flowsheet Name - Row"
, ip_data_row.disp_name as "Question"
, COALESCE(ip_list.CUST_LIST_Value,ifm.MEAS_VALUE) as "Answer(s)"
, ifm.RECORDED_TIME
,alt.alt_id
,alt.alert_desc
,alt.bpa_locator_id
,parloc.LOC_ID
from ip_flo_gp_data ip_data_grp
inner join ip_flo_ovrtm_sngl ip_cnct on ip_data_grp.FLO_MEAS_ID = ip_cnct.ID
           and ip_cnct.contact_date_real = (Select max(ip_cnct_2.contact_date_real) from ip_flo_ovrtm_sngl ip_cnct_2 where ip_data_grp.FLO_MEAS_ID = ip_cnct_2.ID)
left outer join IP_FLO_MEASUREMNTS  ip_flo on ip_data_grp.FLO_MEAS_ID = ip_flo.ID
           and ip_flo.contact_date_real= (Select max(ip_flo2.contact_date_real) from IP_FLO_MEASUREMNTS ip_flo2 where ip_data_grp.FLO_MEAS_ID = ip_flo2.ID)
left outer join ip_flo_gp_data ip_data_row on ip_flo.MEASUREMENT_ID = ip_data_row.FLO_MEAS_ID
left outer join ip_flo_custom_list ip_list on ip_data_row.flo_meas_id = ip_list.id  
           and ip_list.contact_date_real= (Select max(ip_list2.contact_date_real) from IP_FLO_custom_list ip_list2 where ip_data_row.FLO_MEAS_ID = ip_list2.ID)
left outer join ip_flt_comps ip_comps on ip_data_grp.flo_meas_id = ip_comps.FLO_MEAS_ID
left outer join ip_flt_data ip_flt on ip_comps.template_id = ip_flt.template_id
LEFT outer JOIN IP_FLWSHT_MEAS ifm ON ifm.FLO_MEAS_ID = ip_data_row.FLO_MEAS_ID  AND (ifm.MEAS_VALUE = ip_list.CUST_LIST_MAP_VALUE OR ip_list.CUST_LIST_MAP_VALUE IS NULL)
LEFT OUTER JOIN    IP_FLWSHT_REC fr  ON fr.FSD_ID = ifm.FSD_ID
inner join patient pat on fr.PAT_ID = pat.PAT_ID
LEFT OUTER JOIN PAT_ENC enc ON fr.INPATIENT_DATA_ID = enc.INPATIENT_DATA_ID
LEFT OUTER JOIN alert alt ON enc.PAT_ENC_CSN_ID = alt.PAT_CSN AND alt.BPA_LOCATOR_ID IN (1153202,1153200)
LEFT OUTER JOIN clarity_emp empe ON ifm.ENTRY_USER_ID = empe.USER_ID
LEFT OUTER JOIN CLARITY_DEP dep ON enc.DEPARTMENT_ID = dep.DEPARTMENT_ID
LEFT OUTER JOIN clarity_loc loc ON dep.REV_LOC_ID = loc.LOC_ID
LEFT OUTER JOIN clarity_loc parloc ON loc.HOSP_PARENT_LOC_ID = parloc.LOC_ID

WHERE
 ip_flt.TEMPLATE_ID = '1153200'      -----'1150003600',
 AND enc.PAT_ENC_CSN_ID = 30145806982
-- AND enc.CONTACT_DATE >= '1-aug-2021'
 AND parloc.LOC_ID = 100000
--AND enc.CONTACT_DATE >= EPIC_UTIL.EFN_DIN('{?Begin Date}') 
--AND enc.CONTACT_DATE <= EPIC_UTIL.EFN_DIN('{?End Date}') 
ORDER BY pat.PAT_NAME


--SELECT *
--FROM ALERT alt
--WHERE
--alt.PAT_CSN = 30142783241