-- Source-concept branch: PACS_EXPENSE (part 3/3)

INSERT  INTO fct_claim_payment_detail_expense_r_chkdt_gtt
            SELECT MIN(fcpder.d_check_date_r) min_d_check_date_r
            	   ,fcpder.n_claim_sk_r
                   ,fcpder.n_source_system_key_r
            	   ,fcpder.v_check_number_r
              FROM fct_claim_payment_detail_expense_r fcpder
             WHERE UPPER(fcpder.v_payment_status_r) ='PAID'
               AND EXISTS(SELECT 1 
                            FROM fct_claim_payment_detail_expense_r fcpder1
                           WHERE fcpder1.n_claim_sk_r                 = fcpder.n_claim_sk_r
            				 AND fcpder1.n_source_system_key_r        = fcpder.n_source_system_key_r
            				 AND fcpder1.v_check_number_r             = fcpder.v_check_number_r
            				 AND UPPER(fcpder1.v_payment_status_r)    ='VOID'
            				 AND UPPER(fcpder1.v_source_system_name_r)='PACS'
            				 AND UPPER(fcpder.v_source_system_name_r )='PACS'
                         )	
            GROUP BY 
                    fcpder.n_claim_sk_r
                   ,fcpder.n_source_system_key_r
            	   ,fcpder.v_check_number_r;

UPDATE fct_claim_payment_detail_expense_r
				SET d_check_date_r  = lt_var_upd_tbl_chkdt_typ(X).d_min_check_date_r  
					,t_last_modified_date_r=sysdate
					,v_last_modified_by_r  ='PKG_GRP_FULLLOAD_FCT_CLAIM_PAYMENT_DETAIL_R_PACS_EXPENSE_UPD'
			  WHERE n_claim_sk_r                  = lt_var_upd_tbl_chkdt_typ(X).n_claim_sk_r
				AND n_source_system_key_r         = lt_var_upd_tbl_chkdt_typ(X).n_source_system_key_r
				AND v_check_number_r              = lt_var_upd_tbl_chkdt_typ(X).v_check_number_r
				AND UPPER(v_payment_status_r)     ='VOID'
				AND UPPER(v_source_system_name_r) ='PACS';