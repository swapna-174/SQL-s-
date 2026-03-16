select dep.department_id as "ID"
	, dep.record_status
	, dep.department_name as "NAME"
	, dep.dept_abbreviation as "ABBR"
	, dep.rpt_grp_three as "VTRCKS"
	, dep.SPECIALTY_DEP_C as "SPEC"
	, dep.EXTERNAL_NAME as "EX_NAME"
	, dep.rev_loc_id as "REV_LOC_ID"
	, cloc.LOC_ID as "LOC_ID"
	, cloc.LOC_NAME as "LOC_NAME"
	, cloc.HOSP_PARENT_LOC_ID as "HOSP_PARENT_ID"
	, loc_hsp.loc_name as "PARENT_HOSP"
from clarity_dep dep
	left outer join CLARITY_LOC cloc on dep.REV_LOC_ID= cloc.LOC_ID
	left outer join clarity_loc loc_hsp on cloc.HOSP_PARENT_LOC_ID = loc_hsp.loc_id
where dep.record_status is null
