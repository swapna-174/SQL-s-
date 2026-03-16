select distinct
-- BDC information
hsp_bdc.bdc_id
,hsp_bdc.extl_reason_code 
,clarity_rmc.remit_code_name 
,zc_remit_code_grp.name remit_code_grp
,zc_bdc_record_sts.name bdc_record_sts
,zc_rmc_code_cat_1.name denial_category
,zc_bdc_rslv_rsn.name resolve_reason
,hsp_bdc.resolve_comments
,zc_owning_area_1.name source_area
,zc_rmc_code_cat.name code_cat
,zc_root_cause.name root_cause
,zc_owning_area.name owning_area
,hsp_bdc_2.source_dept_id
,hsp_bdc_2.source_user_id
,clarity_rmc.preventable_yn preventable
,zc_clinical_root_cause.name clinical_root_cause
,hsp_bdc.bdc_create_dt
,hsp_bdc.bdc_recd_dt
,hsp_bdc.bdc_cmplte_void_dt
,hsp_bdc.bdc_reopen_dt
,hsp_bdc.exp_allow_amt
,hsp_bdc.expected_recv_amt 
,hsp_bdc.actual_recv_amt_usr
,hsp_bdc.write_off_amt_calc
,hsp_bdc.act_rcv_amt_calc
,hsp_bdc.rpt_remit_code_id 
,hsp_bdc.days_denied 
,hsp_bdc.act_rcv_amt_sys
,hsp_bdc.write_off_amt_sys
,coalesce(hsp_bdc.bdc_cmplte_void_dt,epic_util.efn_din('t'))-hsp_bdc.bdc_create_dt days_open
-- HLB information
,hsp_bucket.bucket_id
,zc_bkt_sts_ha.name bucket_status
,zc_bkt_type_ha.name bucket_type
,zc_claim_type_ha.name bucket_claim_type
,hsp_bucket.last_clm_inv_num
,hsp_bucket.first_claim_date
,hsp_bucket.last_claim_date
,clarity_fc.financial_class_name bucket_financial_class
,cvg.subscr_num
,cvg.subscr_name
,hsp_bucket.payor_id
,clarity_epm.payor_name payor_name
,hsp_bucket.benefit_plan_id
,clarity_epp.benefit_plan_name
,hsp_bucket.current_balance bucket_balance
,hsp_bucket.charge_total bucket_charges
,(hsp_bucket.payment_total * -1) bucket_payments
,(hsp_bucket.adjustment_total * -1) bucket_adjustments
,hsp_bucket.non_covered_amt
,hsp_bucket.exp_na_woff_amt
,hsp_bucket.act_na_woff_amt
,hsp_bucket.copay_amount
,hsp_bucket.coins_amount
,hsp_bucket.deductible_amount
,v_arhb_denial_summary.billed_amount
,v_arhb_denial_summary.allowed_amount
,v_arhb_denial_summary.denied_amount
-- HAR Information
,hsp_bucket.hsp_account_id
,hsp_account.pat_name
,hsp_account.patient_mrn
,zc_acct_billsts_ha.name acct_bill_status
,zc_acct_basecls_ha.name acct_basecls
,zc_acct_class_ha.name acct_class
,hsp_account.tot_acct_bal har_bal
,hsp_account.tot_chgs har_tot_chgs
,hsp_account.tot_adj har_tot_adjs
,hsp_account.tot_pmts har_tot_pmts
,hsp_account.adm_date_time
,hsp_account.disch_date_time
,hsp_account.disch_dept_id
,disch_dep.department_name disch_dept_name
,ser_ref.prov_id
,ser_ref.prov_name
,ser_ref2.npi prov_npi
,har.hsp_account_id
,enc.pat_enc_csn_id
,har.assoc_authcert_id
,precert_cvg.carrier_auth_cmt precert_carrier_auth_cmt
,precert_cvg.eff_cvg_auth_cmt precert_eff_cvg_auth_cmt
,precert_cvg.eff_cvg_precert_num precert_eff_cvg_precert_num
,precert_emp.name precert_last_user
,enc.referral_id 
,rfl_cvg.carrier_auth_cmt referral_carrier_auth_cmt
,rfl_cvg.eff_cvg_auth_cmt referral_eff_cvg_auth_cmt
,rfl_cvg.eff_cvg_precert_num referral_eff_cvg_precert_num
,remp.NAME referral_last_user
from hsp_bdc hsp_bdc 
inner join hsp_bucket hsp_bucket on hsp_bdc.liability_bkt_id=hsp_bucket.bucket_id
inner join hsp_bdc_chng_hx hx on hsp_bdc.bdc_id=hx.bdc_id
left join hsp_account har on hsp_bucket.hsp_account_id=har.hsp_account_id
left join pat_enc enc on har.prim_enc_csn_id=enc.pat_enc_csn_id
left join hsp_bdc_2 hsp_bdc_2 on hsp_bdc.bdc_id=hsp_bdc_2.bdc_id
left join v_arhb_denial_summary v_arhb_denial_summary on hsp_bdc.bdc_id=v_arhb_denial_summary.bdc_id
left join hsp_account on hsp_bucket.hsp_account_id=hsp_account.hsp_account_id
left join coverage cvg on hsp_bucket.coverage_id=cvg.coverage_id
-- Referral Info
left join referral rfl on enc.referral_id=rfl.referral_id
left join referral_2 rfl2 on rfl.referral_id=rfl2.referral_id
left join referral_cvg rfl_cvg on rfl.referral_id=rfl_cvg.referral_id and cvg.coverage_id=rfl_cvg.cvg_id
left join referral_hist rflh on rfl2.referral_id=rflh.referral_id and rflh.line=rfl2.current_event_no
left join clarity_emp remp on rflh.change_user_id=remp.user_id
-- Precert Info
left join referral precert on har.assoc_authcert_id=precert.referral_id
left join referral_2 precert2 on precert.referral_id=precert2.referral_id
left join referral_cvg precert_cvg on precert.referral_id=precert_cvg.referral_id and cvg.coverage_id=precert_cvg.cvg_id
left join referral_hist precerth on precert2.referral_id=precerth.referral_id and precerth.line=precert2.current_event_no
left join clarity_emp precert_emp on precerth.change_user_id=precert_emp.user_id
--BDC category lists
left join clarity_rmc clarity_rmc on hsp_bdc.rmc_id=clarity_rmc.remit_code_id
left join zc_bdc_rslv_rsn on hsp_bdc.resolve_rsn_c=zc_bdc_rslv_rsn.bdc_rslv_rsn_c
left join zc_bdc_record_type  on hsp_bdc.den_rmk_corr_typ_c=zc_bdc_record_type.bdc_record_type_c
left join zc_bdc_record_src  on hsp_bdc.den_rmk_corr_src_c=zc_bdc_record_src.bdc_record_src_c
left join zc_bdc_record_sts  on hsp_bdc.den_rmk_corr_sts_c=zc_bdc_record_sts.bdc_record_sts_c
left join zc_recovery_type  on hsp_bdc.recovery_type_c=zc_recovery_type.recovery_type_c
left join zc_owning_area zc_owning_area_1 on hsp_bdc.source_area_c=zc_owning_area_1.owning_area_c
left join zc_rmc_code_cat zc_rmc_code_cat_1 on hsp_bdc.denial_type_c=zc_rmc_code_cat_1.rmc_code_cat_c
left join zc_rmc_code_type  on clarity_rmc.code_type_c=zc_rmc_code_type.rmc_code_type_c
left join zc_rmc_code_cat on clarity_rmc.code_cat_c=zc_rmc_code_cat.rmc_code_cat_c
left join zc_remit_code_grp zc_remit_code_grp_1 on clarity_rmc.remit_code_group_c=zc_remit_code_grp_1.remit_code_group_c
left join zc_remit_code_grp  on clarity_rmc.remit_code_group_c=zc_remit_code_grp.remit_code_group_c
left join zc_rpt_grp_two on clarity_rmc.rpt_grp_two_c=zc_rpt_grp_two.rpt_grp_two_c
left join zc_owning_area  on clarity_rmc.owning_area_c=zc_owning_area.owning_area_c
left join zc_root_cause on hsp_bdc_2.root_cause_c=zc_root_cause.root_cause_c
left join zc_clinical_root_cause on hsp_bdc_2.clin_root_cause_c=zc_clinical_root_cause.clinical_root_cause_c
-- HLB Category lists
left join clarity_sa  on hsp_bdc.source_area_c=clarity_sa.serv_area_id
left join clarity_dep clarity_dep on hsp_bdc_2.source_dept_id=clarity_dep.department_id
left join clarity_epm clarity_epm on hsp_bucket.payor_id=clarity_epm.payor_id
left join clarity_epp clarity_epp on hsp_bucket.benefit_plan_id=clarity_epp.benefit_plan_id
left join clarity_fc  on clarity_epm.financial_class=clarity_fc.financial_class
left join zc_bkt_sts_ha  on hsp_bucket.bkt_sts_ha_c=zc_bkt_sts_ha.bkt_sts_ha_c
left join zc_bkt_type_ha  on hsp_bucket.bkt_type_ha_c=zc_bkt_type_ha.bkt_type_ha_c
left join zc_claim_type_ha  on hsp_bucket.claim_type_ha_c=zc_claim_type_ha.claim_type_ha_c
left join zc_claim_form_type  on hsp_bucket.claim_form_type_c=zc_claim_form_type.claim_form_type_c
-- HAR Category Lists
left join clarity_ser ser_ref on hsp_account.referring_prov_id=ser_ref.prov_id
left join clarity_ser_2 ser_ref2 on ser_ref.prov_id=ser_ref2.prov_id
left join clarity_ser perf_ser  on hsp_account.attending_prov_id = perf_ser.prov_id
left join clarity_dep disch_dep on hsp_account.disch_dept_id=disch_dep.department_id 
left join zc_acct_billsts_ha on hsp_account.acct_billsts_ha_c=zc_acct_billsts_ha.acct_billsts_ha_c
left join account acc on hsp_account.guarantor_id = acc.account_id   
left join zc_account_type on acc.account_type_c = zc_account_type.account_type_c
left join zc_acct_class_ha  on hsp_account.acct_class_ha_c=zc_acct_class_ha.acct_class_ha_c
left join zc_acct_basecls_ha  on hsp_account.acct_basecls_ha_c=zc_acct_basecls_ha.acct_basecls_ha_c
where 
hsp_bdc.den_rmk_corr_typ_c=1  
--and ({?Type}=1 
--and hsp_bdc.den_rmk_corr_sts_c not in (20,90,99)  -- Open as of run date
--    or
--    {?Type}=2 
    and hsp_bdc.bdc_create_dt>=epic_util.efn_din('t-7') and hsp_bdc.bdc_create_dt<epic_util.efn_din('t-1')  -- Created previous week