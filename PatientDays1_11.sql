SELECT 
fdot.PAT_ID
,fdot.TAKEN_DATE
,pat.PAT_MRN_ID
,pat.PAT_NAME
,zcps.NAME  "SERVICE"
,fdot.MEDICATION_ID
,serauth.PROV_NAME
,dep.DEPARTMENT_NAME
,parloc.LOC_NAME
,fdot.ORDER_ID
,fdot.UPDATE_DATE
,extract(month from fdot.TAKEN_DATE) "TAKEN_MONTH"

FROM F_DOT_CONTRIB_ORDS_DEPT fdot
INNER JOIN order_med om ON fdot.ORDER_ID = om.ORDER_MED_ID
LEFT OUTER JOIN IP_FREQUENCY freq ON om.HV_DISCR_FREQ_ID=freq.FREQ_ID
LEFT OUTER JOIN ZC_ADMIN_ROUTE zcar ON om.MED_ROUTE_C=zcar.MED_ROUTE_C

LEFT OUTER JOIN clarity_dep dep ON fdot.DEPARTMENT_ID = dep.DEPARTMENT_ID
LEFT OUTER JOIN clarity_loc loc ON dep.REV_LOC_ID = loc.LOC_ID
LEFT OUTER JOIN clarity_loc parloc ON loc.HOSP_PARENT_LOC_ID = parloc.LOC_ID
LEFT OUTER JOIN zc_pat_service zcps ON fdot.PAT_HOSP_SERV_C = zcps.HOSP_SERV_C
LEFT OUTER JOIN clarity_ser serauth ON fdot.AUTHG_PROV_ID = serauth.PROV_ID
LEFT OUTER JOIN CLARITY_SER seratt ON fdot.ATTEND_PROV_ID = seratt.PROV_ID
LEFT OUTER JOIN clarity_ser serord ON fdot.ORDER_PROV_ID = serord.PROV_ID
INNER JOIN patient pat ON fdot.PAT_ID = pat.PAT_ID

WHERE

 fdot.TAKEN_DATE >= '1-jan-2020'
AND fdot.TAKEN_DATE <= '31-May-2020'

