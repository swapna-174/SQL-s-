SELECT
    loc.OR_DEPARTMENT_ID "Department ID"
    , dep.DEPARTMENT_NAME "Department Name"
    , svc.SERVICE_C "Service ID"
    , zc_os.NAME "Service Name"
    , orp.OR_PROC_ID "Procedure ID"
    , orp.PROC_NAME "Procedure Name"
    , orp.INACTIVE_YN "Inactive?"

FROM OR_PROC orp
    LEFT OUTER JOIN OR_PROC_AUTHLOC ath ON orp.OR_PROC_ID = ath.OR_PROC_ID
    LEFT OUTER JOIN OR_LOC loc ON ath.AUTH_LOCATIONS_ID = loc.LOC_ID
    LEFT OUTER JOIN CLARITY_DEP dep ON loc.OR_DEPARTMENT_ID = dep.DEPARTMENT_ID
    LEFT OUTER JOIN OR_PROC_SERVICE svc ON orp.OR_PROC_ID = svc.OR_PROC_ID
    LEFT OUTER JOIN ZC_OR_SERVICE zc_os ON svc.SERVICE_C = zc_os.SERVICE_C
    
ORDER BY
    dep.DEPARTMENT_NAME
    , zc_os.NAME
    , orp.PROC_NAME