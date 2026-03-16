SELECT 
    pat.PAT_MRN_ID "Patient MRN"
    , trn.TRANSFER_DATE "Transfer Date"
    , dep_from.DEPARTMENT_NAME "From Dept"
    , dep_to.DEPARTMENT_NAME "To Dept"
--    , adt.EVENT_ID
--    , adt.EVENT_TYPE_C
    , pnd.REQUEST_TIME "Request Time"
--    , pnd.REQ_BY_USR_ID "Requested By"
    , pnd.ASSIGNED_TIME "Assigned Time"
    , adt.EFFECTIVE_TIME "Transfer Arrival Time"
--    , adt.XFER_EVENT_ID
--    , adt.XFER_IN_EVENT_ID
--    , adt.PREV_EVENT_ID
    ,  ROUND((pnd.ASSIGNED_TIME - pnd.REQUEST_TIME) * 24 * 60) "Request to Assigned Minutes"
    ,  ROUND((adt.EFFECTIVE_TIME - pnd.ASSIGNED_TIME) * 24 * 60) "Assigned to Arrived Minutes"
    ,  ROUND((adt.EFFECTIVE_TIME - pnd.REQUEST_TIME) * 24 * 60) "Request to Arrived Minutes"
FROM PATIENT pat
        LEFT OUTER JOIN F_IP_HSP_TRANSFER trn ON pat.PAT_ID = trn.PAT_ID
        LEFT OUTER JOIN CLARITY_DEP dep_from ON dep_from.DEPARTMENT_ID = trn.FROM_DEPT_ID
        LEFT OUTER JOIN CLARITY_DEP dep_to ON dep_to.DEPARTMENT_ID = trn.TO_DEPT_ID
        LEFT OUTER JOIN CLARITY_ADT adt ON trn.EVENT_ID = adt.EVENT_ID
        LEFT OUTER JOIN PEND_ACTION pnd ON adt.XFER_IN_EVENT_ID = pnd.LINKED_EVENT_ID
WHERE adt.EVENT_TYPE_C IN ('3','4')
        AND dep_from.RPT_GRP_EIGHT IN ('3','4','5','11')
        AND dep_from.REV_LOC_ID = 10001
        AND trn.TRANSFER_DATE >= to_date('10/01/2015', 'MM-DD-YYYY')
ORDER BY pat.PAT_MRN_ID, trn.TRANSFER_DATE





