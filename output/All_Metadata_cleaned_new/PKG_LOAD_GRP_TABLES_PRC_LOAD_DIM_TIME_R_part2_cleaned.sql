-- Cleaned for lineage: PKG_LOAD_GRP_TABLES_PRC_LOAD_DIM_TIME_R (part 2/2)

merge into DIM_TIME_R TARGET using
		(SELECT MIN(D_CALENDAR_DATE_R)
				as D_CALENDAR_DATE_R, n_year_r, n_month_r
				FROM DIM_TIME_R
			   WHERE TO_CHAR(D_CALENDAR_DATE_R, 'DD') >= '15'
				 AND V_BUSINESS_DAY_IND_R='Y'
				 group by n_year_r, n_month_r) SOURCE
		on (source.n_year_r = target.n_year_r
				 AND source.n_month_r = target.n_month_r)
		when matched then update set TARGET.V_MID_MONTH_IND_R =
		(case when TO_CHAR(TARGET.D_CALENDAR_DATE_R, 'DD') >= 15 and TO_CHAR(TARGET.D_CALENDAR_DATE_R, 'DD') < 20 and SOURCE.D_CALENDAR_DATE_R = TARGET.D_CALENDAR_DATE_R then 'Y' else 'N' end)
			WHERE SOURCE.N_YEAR_R = TARGET.N_YEAR_R AND SOURCE.N_MONTH_R = TARGET.N_MONTH_R
			and target.N_YEAR_R>=NVL(IN_NEW_YEAR_R, target.N_YEAR_R);

merge into DIM_TIME_R TARGET using
				(SELECT count(1) as l_b_days_count_004, N_YEAR_R, N_MONTH_R
						FROM DIM_TIME_R SOURCE
						WHERE (case when SOURCE.N_DAY_OF_WEEK_R in (2,3,4,5,6) and  SOURCE.V_HOLIDAY_IND_R = 'N' THEN 'Y' else 'N' end)= 'Y'
						group by N_YEAR_R, N_MONTH_R) SOURCE
				on ( SOURCE.N_YEAR_R = TARGET.N_YEAR_R AND SOURCE.N_MONTH_R = TARGET.N_MONTH_R)
				when matched then
                    update set TARGET.N_BUSINESS_DAYS_IN_MONTH_R = SOURCE.l_b_days_count_004
                        WHERE SOURCE.N_YEAR_R = TARGET.N_YEAR_R AND SOURCE.N_MONTH_R = TARGET.N_MONTH_R
                            and target.N_YEAR_R>=NVL(IN_NEW_YEAR_R, target.N_YEAR_R);

merge into DIM_TIME_R TARGET using
				(SELECT count(1) as l_b_days_count_005, N_FISCAL_YEAR_R, N_FISCAL_MONTH_R
					 FROM ATOMIC.DIM_TIME_R SOURCE
					WHERE SOURCE.V_BUSINESS_DAY_IND_R= 'Y'
					  group by N_FISCAL_YEAR_R, N_FISCAL_MONTH_R) SOURCE
				on ( SOURCE.N_FISCAL_YEAR_R = TARGET.N_FISCAL_YEAR_R AND SOURCE.N_FISCAL_MONTH_R = TARGET.N_FISCAL_MONTH_R)
				when matched then update set TARGET.N_BUSINESS_DAYS_IN_FISCALMTH_R = SOURCE.l_b_days_count_005
                        WHERE SOURCE.N_FISCAL_YEAR_R = TARGET.N_FISCAL_YEAR_R AND SOURCE.N_FISCAL_MONTH_R = TARGET.N_FISCAL_MONTH_R
                            and target.N_YEAR_R>=NVL(IN_NEW_YEAR_R, target.N_YEAR_R);

merge into DIM_TIME_R a using
				(select d_calendar_date_r, n_year_r, n_month_r
				from DIM_TIME_R
			   where v_end_of_fiscal_month_ind_r = 'Y') td1
				on (td1.n_month_r = a.n_month_r and td1.n_year_r = a.n_year_r and a.V_BUSINESS_DAY_IND_R = 'Y' and a.D_CALENDAR_DATE_r > td1.D_CALENDAR_DATE_r)
			when matched then update set V_PREMIUM_DEAD_DAY_IND_R = 'Y'
                        WHERE td1.N_YEAR_R = a.N_YEAR_R AND td1.N_MONTH_R = a.N_MONTH_R
                            and a.N_YEAR_R>=NVL(IN_NEW_YEAR_R, a.N_YEAR_R);

-- Lineage: Cursor C1 (target inferred from procedure)
select * from ATOMIC.DIM_DATES
        where N_DATE_SKEY not in (-1,0,19000101,99991231)                   
                AND  N_YEAR_CALENDAR>= NVL(IN_NEW_YEAR_R, N_YEAR_CALENDAR);