view: cancellations {
  derived_table: { sql:
    SELECT scheme,
           trans_type,
           aauicl_tenure,
           channel,
           origin,
           payment_method,
           incep_month,
           canc_date,
           dev_month,
           SUM(COALESCE(all_cancelled,0)) OVER (PARTITION BY scheme,trans_type,aauicl_tenure,channel,origin,payment_method,incep_month ORDER BY canc_date rows BETWEEN unbounded preceding AND CURRENT row) AS all_cancelled,
           SUM(COALESCE(CFI,0)) OVER (PARTITION BY scheme,trans_type,aauicl_tenure,channel,origin,payment_method,incep_month ORDER BY canc_date rows BETWEEN unbounded preceding AND CURRENT row) AS CFI,
           SUM(COALESCE(all_cancelled_net_prem,0)) OVER (PARTITION BY scheme,trans_type,aauicl_tenure,channel,origin,payment_method,incep_month ORDER BY canc_date rows BETWEEN unbounded preceding AND CURRENT row) AS all_cancelled_net_prem,
           SUM(COALESCE(cfi_cancelled_net_prem,0)) OVER (PARTITION BY scheme,trans_type,aauicl_tenure,channel,origin,payment_method,incep_month ORDER BY canc_date rows BETWEEN unbounded preceding AND CURRENT row) AS cfi_cancelled_net_prem,
           sale,
           sold_net_prem
    FROM (SELECT c.scheme,
                 c.trans_type,
                 c.incep_month,
                 c.canc_date,
                 c.aauicl_tenure,
                 c.channel,
                 c.origin,
                 c.payment_method,
                 timestampdiff(MONTH,c.incep_month,c.canc_date) AS dev_month,
                 COALESCE(all_cancelled,0) AS all_cancelled,
                 COALESCE(CFI,0) AS CFI,
                 COALESCE(all_cancelled_net_prem,0) AS all_cancelled_net_prem,
                 COALESCE(cfi_cancelled_net_prem,0) AS cfi_cancelled_net_prem,
                 b.sale,
                 b.sold_net_prem
          FROM (SELECT DISTINCT ps.scheme,
                       CASE
                         WHEN to_date (inception_date) = to_date (term_inception_date) THEN 'NB'
                         ELSE 'RN'
                       END AS trans_type,
                       timestampdiff(YEAR,inception_date,term_inception_date) AS aauicl_tenure,
                       CASE
                         WHEN channel IS NULL THEN 'Unknown'
                         ELSE channel
                       END AS channel,
                       origin,
                       CASE
                         WHEN noofinstalments = 12 THEN 'Instalments'
                         ELSE 'Annual'
                       END AS payment_method,
                       date_trunc('month',to_date (ps.term_inception_date)) AS incep_month,
                       start_date AS canc_date
                FROM ice_aa_policy_summary ps
                  LEFT JOIN aauser.calendar c
                         ON date_trunc ('month',to_date (ps.term_inception_date)) <= c.start_date
                        AND c.start_date <= to_date (SYSDATE)
                        AND timestampdiff (MONTH,date_trunc ('month',to_date (ps.term_inception_date)),c.start_date) <= 12
                  LEFT JOIN v_ice_policy_origin v ON v.policy_reference_number = ps.policy_reference_number
                  LEFT JOIN ice_dim_question_answer qa ON ps.policy_transaction_key = qa.policy_transaction_key
                WHERE ps.policy_transaction_type IN ('NEW_BUSINESS','RENEWAL_ACCEPT')
                AND   date_trunc('month',to_date(ps.term_inception_date)) <= to_date(SYSDATE)) c
            LEFT JOIN (SELECT scheme,
                              CASE
                                WHEN to_date (inception_date) = to_date (term_inception_date) THEN 'NB'
                                ELSE 'RN'
                              END AS trans_type,
                              timestampdiff(YEAR,inception_date,term_inception_date) AS aauicl_tenure,
                              CASE
                                WHEN channel IS NULL THEN 'Unknown'
                                ELSE channel
                              END AS channel,
                              origin,
                              CASE
                                WHEN noofinstalments = 12 THEN 'Instalments'
                                ELSE 'Annual'
                              END AS payment_method,
                              date_trunc('month',to_date (term_inception_date)) AS incep_month,
                              SUM(1) AS sale,
                              SUM(act_gross_premium_net_commission_txd_amt) AS sold_net_prem
                       FROM ice_aa_policy_summary ps
                         LEFT JOIN v_ice_policy_origin v ON v.policy_reference_number = ps.policy_reference_number
                         LEFT JOIN ice_dim_question_answer qa ON ps.policy_transaction_key = qa.policy_transaction_key
                       WHERE policy_transaction_type IN ('NEW_BUSINESS','RENEWAL_ACCEPT')
                       GROUP BY scheme,
                                CASE
                                                     WHEN to_date (inception_date) = to_date (term_inception_date) THEN 'NB'
                                                     ELSE 'RN'
                                                   END
                       ,
                                date_trunc('month',to_date (term_inception_date)),
                                timestampdiff(YEAR,inception_date,term_inception_date),
                                CASE
                                                     WHEN channel IS NULL THEN 'Unknown'
                                                     ELSE channel
                                                   END
                       ,
                                origin,
                                CASE
                                                     WHEN noofinstalments = 12 THEN 'Instalments'
                                                     ELSE 'Annual'
                                                   END) b
                   ON c.scheme = b.scheme
                  AND c.trans_type = b.trans_type
                  AND c.incep_month = b.incep_month
                  AND c.aauicl_tenure = b.aauicl_tenure
                  AND c.channel = b.channel
                  AND c.origin = b.origin
                  AND c.payment_method = b.payment_method
            LEFT JOIN (SELECT scheme,
                              CASE
                                WHEN to_date (inception_date) = to_date (term_inception_date) THEN 'NB'
                                ELSE 'RN'
                              END AS trans_type,
                              timestampdiff(YEAR,inception_date,term_inception_date) AS aauicl_tenure,
                              CASE
                                WHEN channel IS NULL THEN 'Unknown'
                                ELSE channel
                              END AS channel,
                              origin,
                              CASE
                                WHEN noofinstalments = 12 THEN 'Instalments'
                                ELSE 'Annual'
                              END AS payment_method,
                              date_trunc('month',to_date (term_inception_date)) AS incep_month,
                              date_trunc('month',to_date (transaction_period_start_date)) AS canc_date,
                              SUM(1) AS all_cancelled,
                              SUM(CASE WHEN to_date (transaction_period_start_date) = to_date (term_inception_date) THEN 1 ELSE 0 END) AS CFI,
                              SUM(act_gross_premium_net_commission_txd_amt) AS all_cancelled_net_prem,
                              SUM(CASE WHEN to_date (transaction_period_start_date) = to_date (term_inception_date) THEN act_gross_premium_net_commission_txd_amt ELSE 0 END) AS cfi_cancelled_net_prem
                       FROM ice_aa_policy_summary ps
                         LEFT JOIN v_ice_policy_origin v ON v.policy_reference_number = ps.policy_reference_number
                         LEFT JOIN ice_dim_question_answer qa ON ps.policy_transaction_key = qa.policy_transaction_key
                       WHERE policy_transaction_type IN ('CANCELLATION')
                       GROUP BY scheme,
                                CASE
                                                     WHEN to_date (inception_date) = to_date (term_inception_date) THEN 'NB'
                                                     ELSE 'RN'
                                                   END
                       ,
                                date_trunc('month',to_date (term_inception_date)),
                                date_trunc('month',to_date (transaction_period_start_date)),
                                timestampdiff(YEAR,inception_date,term_inception_date),
                                CASE
                                                     WHEN channel IS NULL THEN 'Unknown'
                                                     ELSE channel
                                                   END
                       ,
                                origin,
                                CASE
                                                     WHEN noofinstalments = 12 THEN 'Instalments'
                                                     ELSE 'Annual'
                                                   END) a
                   ON a.scheme = c.scheme
                  AND a.incep_month = c.incep_month
                  AND a.canc_date = c.canc_date
                  AND c.trans_type = a.trans_type
                  AND c.aauicl_tenure = a.aauicl_tenure
                  AND c.channel = a.channel
                  AND c.origin = a.origin
                  AND c.payment_method = a.payment_method) t
    ;;
  }
  dimension: Scheme {
    type:  string
    sql: ${TABLE}.scheme ;;
  }

  dimension: Policy_Type{
    type:  string
    sql: ${TABLE}.trans_type ;;
  }

  dimension: aauicl_tenure{
    type:  string
    sql: ${TABLE}.aauicl_tenure ;;
  }

  dimension: Channel_at_NB{
    type:  string
    sql: ${TABLE}.channel ;;
  }

  dimension: Origin{
    type:  string
    sql: ${TABLE}.origin ;;
  }

  dimension: payment_method{
    type:  string
    sql: ${TABLE}.payment_method ;;
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
