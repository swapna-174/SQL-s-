SELECT 
    pat.PAT_MRN_ID "Patient MRN"
    , trn.TRANSFER_DATE "Transfer Date"
    , dep_from.DEPARTMENT_NAME "From Dept"
    , dep_from.DEPARTMENT_ID
    , pnd.REQUEST_TIME "Request Time"
    , pnd.ASSIGNED_TIME "Assigned Time"
    , adt.EFFECTIVE_TIME "Transfer Arrival Time"
    ,  ROUND((pnd.ASSIGNED_TIME - pnd.REQUEST_TIME) * 24 * 60) "Request to Assigned Minutes"
FROM PATIENT pat
        LEFT OUTER JOIN F_IP_HSP_TRANSFER trn ON pat.PAT_ID = trn.PAT_ID
        LEFT OUTER JOIN CLARITY_DEP dep_from ON dep_from.DEPARTMENT_ID = trn.FROM_DEPT_ID
        LEFT OUTER JOIN CLARITY_ADT adt ON trn.EVENT_ID = adt.EVENT_ID
        LEFT OUTER JOIN PEND_ACTION pnd ON adt.XFER_IN_EVENT_ID = pnd.LINKED_EVENT_ID
WHERE 
        adt.EVENT_TYPE_C = 4
--        AND dep_from.DEPARTMENT_ID IN ('1005001021', '1000108017', '1000104047', '1000105016')
        AND dep_from.REV_LOC_ID = 10001
        AND trn.TRANSFER_DATE >= to_date('08/15/2016', 'MM-DD-YYYY')
ORDER BY pat.PAT_MRN_ID, trn.TRANSFER_DATE



SELECT *
FROM CLARITY_DEP dep
WHERE dep.DEPARTMENT_NAME LIKE '%DAY HOSPITAL%'

SELECT *
FROM ZC_PEND_EVENT_TYPE

select *
from zc_pat_class






