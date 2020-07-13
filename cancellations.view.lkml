view: cancellations {
  derived_table: { sql:
    SELECT scheme,
       date_trunc('month',to_date (term_inception_date)) AS incep_month,
       CASE
         WHEN policy_transaction_type = 'CANCELLATION' THEN date_trunc ('month',to_date (transaction_period_start_date))
         ELSE  date_trunc ('month',to_date (transaction_period_end_date))
       END AS canc_month,
       CASE
         WHEN policy_transaction_type IN ('NEW_BUSINESS','RENEWAL_ACCEPT') THEN 1
         ELSE 0
       END AS sale,
       CASE
         WHEN policy_transaction_type = 'CANCELLATION' THEN 1
         ELSE 0
       END AS canc,
       CASE
         WHEN policy_transaction_type = 'CANCELLATION' AND to_date (transaction_period_start_date) = to_date (term_inception_date) THEN 1
         ELSE 0
       END AS cfi,
       act_gross_premium_net_commission_txd_amt AS net_prem,
       CASE
         WHEN to_date (inception_date) = to_date (term_inception_date) THEN 'NB'
         ELSE 'RN'
       END AS trans_type,
       policy_reference_number
FROM ice_aa_policy_summary
WHERE policy_transaction_type IN ('NEW_BUSINESS','RENEWAL_ACCEPT','CANCELLATION')
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

  measure: sales {
    type: number
    sql: sum(${TABLE}.sale) ;;
  }
  measure: cancellations {
    type: number
    sql: sum(${TABLE}.canc) ;;
  }

  measure: CFIs {
    type: number
    sql: sum(${TABLE}.cfi) ;;
  }

  measure: CFI_rate {
    type: number
    sql: 1.0*sum(${TABLE}.cfi)/greatest(sum(${TABLE}.sale),1) ;;
    value_format: "0.00%"
  }

  measure: MTC_rate {
    type: number
    sql: 1.0*(sum(${TABLE}.canc)-sum(${TABLE}.cfi))/greatest(sum(${TABLE}.sale),1) ;;
    value_format: "0.00%"
  }
  }
