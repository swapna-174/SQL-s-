select dep.DEPARTMENT_ID
	, dep.DEPARTMENT_NAME
	, dep.DEPT_ABBREVIATION
	, dep.REV_LOC_ID
	, dep.EXTERNAL_NAME
from clarity_dep dep
where dep.DEPARTMENT_ID = '1024201007'
