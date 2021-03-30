view: cancellations {
  derived_table: { sql:
SELECT a.scheme,
       a.trans_type,
       a.incep_month,
       a.canc_date,
       timestampdiff(month,a.incep_month,a.canc_date) AS dev_month,
       SUM(all_cancelled) OVER (PARTITION BY a.scheme,a.trans_type,a.incep_month ORDER BY a.canc_date rows BETWEEN unbounded preceding AND CURRENT row) AS all_cancelled,
       SUM(CFI) OVER (PARTITION BY a.scheme,a.trans_type,a.incep_month ORDER BY a.canc_date rows BETWEEN unbounded preceding AND CURRENT row) AS CFI,
       SUM(all_cancelled_net_prem) OVER (PARTITION BY a.scheme,a.trans_type,a.incep_month ORDER BY a.canc_date rows BETWEEN unbounded preceding AND CURRENT row) AS all_cancelled_net_prem,
       SUM(cfi_cancelled_net_prem) OVER (PARTITION BY a.scheme,a.trans_type,a.incep_month ORDER BY a.canc_date rows BETWEEN unbounded preceding AND CURRENT row) AS cfi_cancelled_net_prem,
       b.sale,
       b.sold_net_prem
FROM (SELECT scheme,
             CASE
               WHEN to_date (inception_date) = to_date (term_inception_date) THEN 'NB'
               ELSE 'RN'
             END AS trans_type,
             date_trunc('month',to_date (term_inception_date)) AS incep_month,
             date_trunc('month',to_date (transaction_period_start_date)) AS canc_date,
             SUM(1) AS all_cancelled,
             SUM(CASE WHEN to_date (transaction_period_start_date) = to_date (term_inception_date) THEN 1 ELSE 0 END) AS CFI,
             SUM(act_gross_premium_net_commission_txd_amt) AS all_cancelled_net_prem,
             SUM(CASE WHEN to_date (transaction_period_start_date) = to_date (term_inception_date) THEN act_gross_premium_net_commission_txd_amt ELSE 0 END) AS cfi_cancelled_net_prem
      FROM ice_aa_policy_summary
      WHERE policy_transaction_type IN ('CANCELLATION')
      GROUP BY scheme,
               CASE
                       WHEN to_date (inception_date) = to_date (term_inception_date) THEN 'NB'
                       ELSE 'RN'
                     END
      ,
               date_trunc('month',to_date (term_inception_date)),
               date_trunc('month',to_date (transaction_period_start_date))) a
  LEFT JOIN (SELECT scheme,
                    CASE
                      WHEN to_date (inception_date) = to_date (term_inception_date) THEN 'NB'
                      ELSE 'RN'
                    END AS trans_type,
                    date_trunc('month',to_date (term_inception_date)) AS incep_month,
                    SUM(1) AS sale,
                    SUM(act_gross_premium_net_commission_txd_amt) AS sold_net_prem
             FROM ice_aa_policy_summary
             WHERE policy_transaction_type IN ('NEW_BUSINESS','RENEWAL_ACCEPT')
             GROUP BY scheme,
                      CASE
                                     WHEN to_date (inception_date) = to_date (term_inception_date) THEN 'NB'
                                     ELSE 'RN'
                                   END
             ,
                      date_trunc('month',to_date (term_inception_date))) b
         ON a.scheme = b.scheme
        AND a.trans_type = b.trans_type
        AND a.incep_month = b.incep_month
;;
}
  dimension: Scheme {
    type:  string
    sql: ${TABLE}.scheme ;;
    }

  dimension_group: Inception_Month {
    type: time
    timeframes: [month]
    sql: to_timestamp(${TABLE}.incep_month) ;;
  }

  dimension_group: Cancellation_Month {
    type: time
    timeframes: [month]
    sql: to_timestamp(${TABLE}.canc_month) ;;
  }

  dimension: Development_Month{
    type: number
    sql: ${TABLE}.dev_month ;;
  }

  dimension: Latest_flag{
    type: number
    sql: case when ${TABLE}.dev_month = 12 then 1 when canc_date =  date_trunc('month',to_date (sysdate)) then 1 else 0 end;;
  }

  measure: sales {
    type: number
    sql: sum(${TABLE}.sale) ;;
  }

  measure: cancellations {
    type: number
    sql: sum(${TABLE}.all_cancelled) ;;
  }

  measure: CFIs {
    type: number
    sql: sum(${TABLE}.cfi) ;;
  }

  measure: mtcs {
    type: number
    sql: sum(${TABLE}.all_cancelled)-sum(${TABLE}.cfi) ;;
  }

  measure: CFI_rate {
    type: number
    sql: 1.0*sum(${TABLE}.cfi)/greatest(sum(${TABLE}.sale),1) ;;
    value_format: "0.00%"
  }

  measure: MTC_rate {
    type: number
    sql: 1.0*(sum(${TABLE}.all_cancelled)-sum(${TABLE}.cfi))/greatest(sum(${TABLE}.sale),1) ;;
    value_format: "0.00%"
  }

  measure: total_cancellation_rate {
    type: number
    sql: 1.0*(sum(${TABLE}.all_cancelled))/greatest(sum(${TABLE}.sale),1) ;;
    value_format: "0.00%"
  }
  }
