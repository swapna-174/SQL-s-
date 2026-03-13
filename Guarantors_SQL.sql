/*Patient above  18 of age and  listed as their own GUARANTOR but Assocaiated Pt is incorrect*/
select distinct b.ACCOUNT_ID , hsp.HSP_ACCOUNT_ID, TRUNC( MONTHS_BETWEEN( hsp.DISCH_DATE_TIME, hsp.PAT_DOB ) /12 ) as AGE,hsp.PRIMARY_PLAN_ID, pt.PAT_MRN_ID,pt.PAT_NAME, 
hsp.GUARANTOR_ID,b.ACCOUNT_NAME  as GUARANTOR_NAME,
PAT_REC_OF_GUAR_ID,p.PAT_NAME PAT_ASSOC_PT,ZC_Type.NAME as ACCOUNT_TYPE,dep.DEPT_ABBREVIATION DEPT,dep.DEPARTMENT_NAME
from
clarity.HSP_ACCOUNT hsp 
left  join clarity.ACCOUNT b on hsp.GUARANTOR_ID = b.ACCOUNT_ID
join clarity.ACCT_GUAR_PAT_INFO a on b.ACCOUNT_ID = a.ACCOUNT_ID 
left JOIN HSP_ACCT_SBO  SBO on SBO.HSP_ACCOUNT_ID=HSP.HSP_ACCOUNT_ID
left Join Patient pt on hsp.PAT_ID=pt.Pat_id 
left Join Patient p on b.PAT_REC_OF_GUAR_ID=p.PAT_ID
join clarity.ACCT_GUAR_PAT_INFO PAT_INFO on b.ACCOUNT_ID = a.ACCOUNT_ID 
left join ZC_GUAR_REL_TO_PAT REL on   PAT_INFO.GUAR_REL_TO_PAT_C = Rel.GUAR_REL_TO_PAT_C
left join ZC_ACCOUNT_TYPE ZC_Type  on b.ACCOUNT_TYPE_C =ZC_Type.ACCOUNT_TYPE_C
join PAT_ENC ENC on hsp.PRIM_ENC_CSN_ID=ENC.PAT_ENC_CSN_ID
join Clarity_dep dep on ENC.EFFECTIVE_DEPT_ID=dep.department_id
where 
pt.PAT_NAME =b.ACCOUNT_NAME and b.ACCOUNT_NAME<>p.PAT_NAME 
AND TRUNC( MONTHS_BETWEEN( sysdate, hsp.PAT_DOB ) /12 )>=18
and SBO_TOT_BALANCE >0

/*Patient below   18 of age who are listed as own Gurantor */
select distinct b.ACCOUNT_ID , hsp.HSP_ACCOUNT_ID, TRUNC( MONTHS_BETWEEN( hsp.DISCH_DATE_TIME, hsp.PAT_DOB ) /12 ) as AGE,hsp.PRIMARY_PLAN_ID, pt.PAT_MRN_ID,pt.PAT_NAME, 
hsp.GUARANTOR_ID,b.ACCOUNT_NAME  as GUARANTOR_NAME,
PAT_REC_OF_GUAR_ID,p.PAT_NAME PAT_ASSOC_PT,ZC_Type.NAME as ACCOUNT_TYPE,dep.DEPT_ABBREVIATION DEPT,dep.DEPARTMENT_NAME
from
clarity.HSP_ACCOUNT hsp 
left  join clarity.ACCOUNT b on hsp.GUARANTOR_ID = b.ACCOUNT_ID
join clarity.ACCT_GUAR_PAT_INFO a on b.ACCOUNT_ID = a.ACCOUNT_ID 
left JOIN HSP_ACCT_SBO  SBO on SBO.HSP_ACCOUNT_ID=HSP.HSP_ACCOUNT_ID
left Join Patient pt on hsp.PAT_ID=pt.Pat_id 
left Join Patient p on b.PAT_REC_OF_GUAR_ID=p.PAT_ID
join clarity.ACCT_GUAR_PAT_INFO PAT_INFO on b.ACCOUNT_ID = a.ACCOUNT_ID 
left join ZC_GUAR_REL_TO_PAT REL on   PAT_INFO.GUAR_REL_TO_PAT_C = Rel.GUAR_REL_TO_PAT_C
left join ZC_ACCOUNT_TYPE ZC_Type  on b.ACCOUNT_TYPE_C =ZC_Type.ACCOUNT_TYPE_C
join PAT_ENC ENC on hsp.PRIM_ENC_CSN_ID=ENC.PAT_ENC_CSN_ID
join Clarity_dep dep on ENC.EFFECTIVE_DEPT_ID=dep.department_id
where 
pt.PAT_NAME =b.ACCOUNT_NAME 
AND (TRUNC( MONTHS_BETWEEN( sysdate, hsp.PAT_DOB ) /12 )<=18 OR   TRUNC( MONTHS_BETWEEN( hsp.DISCH_DATE_TIME,  pt.BIRTH_DATE ) /12 ) is null)
and SBO_TOT_BALANCE >0

/*Patient below   18 of age Gurantor is different but Assocatied is also different */
/*select distinct b.ACCOUNT_ID , hsp.HSP_ACCOUNT_ID, TRUNC( MONTHS_BETWEEN( hsp.DISCH_DATE_TIME,  pt.BIRTH_DATE ) /12 ) as  AGE,hsp.PRIMARY_PLAN_ID, pt.PAT_NAME, 
hsp.GUARANTOR_ID,b.ACCOUNT_NAME  as GUARANTOR_NAME,
b.PAT_REC_OF_GUAR_ID,p.PAT_NAME PAT_ASSOC_PT,SBO_TOT_BALANCE,ZC_Type.NAME as ACCOUNT_TYPE
from
clarity.HSP_ACCOUNT hsp 
left  join clarity.ACCOUNT b on hsp.GUARANTOR_ID = b.ACCOUNT_ID
left  join clarity.ACCOUNT ba on hsp.GUARANTOR_ID = ba.ACCOUNT_ID
join clarity.ACCT_GUAR_PAT_INFO a on b.ACCOUNT_ID = a.ACCOUNT_ID 
left JOIN HSP_ACCT_SBO  SBO on SBO.HSP_ACCOUNT_ID=HSP.HSP_ACCOUNT_ID
left Join Patient pt on hsp.PAT_ID=pt.Pat_id 
left Join Patient p on b.PAT_REC_OF_GUAR_ID=p.PAT_ID
join clarity.ACCT_GUAR_PAT_INFO PAT_INFO on b.ACCOUNT_ID = a.ACCOUNT_ID 
left join ZC_GUAR_REL_TO_PAT REL on   PAT_INFO.GUAR_REL_TO_PAT_C = Rel.GUAR_REL_TO_PAT_C
left join ZC_ACCOUNT_TYPE ZC_Type  on b.ACCOUNT_TYPE_C =ZC_Type.ACCOUNT_TYPE_C
where ---- hsp.HSP_ACCOUNT_ID =414837695 and 
pt.PAT_NAME <> b.ACCOUNT_NAME and   p.PAT_NAME <> b.ACCOUNT_NAME   
AND ( TRUNC(MONTHS_BETWEEN( hsp.DISCH_DATE_TIME,  pt.BIRTH_DATE ) /12) <18 OR   TRUNC( MONTHS_BETWEEN( hsp.DISCH_DATE_TIME,  pt.BIRTH_DATE ) /12 ) is null)
and SBO_TOT_BALANCE >0 */





select * from (select distinct hsp.GUAR_SSN as  GUAR_SSN ,pt.SSN as PAT_SSN , p.SSN as ASSOC_SSN,hsp.HSP_ACCOUNT_ID,hsp.HSP_ACCOUNT_NAME ,hsp.Guar_name,pt.PAT_MRN_ID,pt.PAT_NAME,p.PAT_NAME  as ASSOCIATED_PT,
ZC_Type.NAME as ACCOUNT_TYPE,dep.DEPT_ABBREVIATION DEPT,dep.DEPARTMENT_NAME
,CASE WHEN hsp.GUAR_SSN <> p.SSN    AND   hsp.GUAR_DOB  <> p.BIRTH_DATE  THEN   1 WHEN  hsp.GUAR_SSN <> p.SSN    AND   hsp.GUAR_DOB =  p.BIRTH_DATE THEN 2 ELSE 0 end Flag
from HSP_ACCOUNT  hsp join account  acc on hsp.GUARANTOR_ID=acc.ACCOUNT_ID 
left join ACCT_GUAR_PAT_INFO  info on acc.ACCOUNT_ID =info.ACCOUNT_ID
left JOIN HSP_ACCT_SBO  SBO on SBO.HSP_ACCOUNT_ID=HSP.HSP_ACCOUNT_ID
left join patient pt on info.PAT_ID=pt.PAT_ID
left Join Patient p on acc.PAT_REC_OF_GUAR_ID=p.PAT_ID
left join ZC_ACCOUNT_TYPE ZC_Type  on acc.ACCOUNT_TYPE_C =ZC_Type.ACCOUNT_TYPE_C
join PAT_ENC ENC on hsp.PRIM_ENC_CSN_ID=ENC.PAT_ENC_CSN_ID
join Clarity_dep dep on ENC.EFFECTIVE_DEPT_ID=dep.department_id
where hsp.GUAR_SSN <> p.SSN 
and (TRUNC( MONTHS_BETWEEN( sysdate, hsp.PAT_DOB ) /12 )<18 OR   TRUNC( MONTHS_BETWEEN( hsp.DISCH_DATE_TIME,  pt.BIRTH_DATE ) /12 ) is null)
and SBO_TOT_BALANCE >0) where  Flag=1



