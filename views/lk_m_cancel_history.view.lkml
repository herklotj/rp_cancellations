view: lk_m_cancel_history {
    derived_table: { sql:
      SELECT tia_reference,
       tia_customer_no,
       tia_transaction_no,
       uw_policy_no,
       status,
       policy_year,
       original_inception_dttm,
       provenance_code,
       installment_flag,
       channel,
       broked_ind,
       nb_sw_flag,
       inception_dttm,
       tia_combined_reference,
       merlin_reference,
       membership_no,
       cover_type,
       cover_type_requested,
       annual_cover_start_dttm,
       annual_cover_end_dttm,
       schedule_cover_start_dttm,
       schedule_cover_end_dttm,
       renewal_date,
       transaction_dttm,
       motor_cover_level,
       cfi_status,
       cfi_dttm,
       cfi_reason,
       cfi_ind_lapse_dttm,
       cfi_ind,
       cfi_ind_lapse,
       transaction_date,
       policy_start_date,
       policy_start_wk,
       policy_start_mth,
       policy_start_yr,
       policy_written_wk,
       policy_written_mth,
       policy_written_yr,
       broker_ind,
       aauicl_ind,
       aauicl_scheme,
       broker_nb_rb,
       insurer_nb_rb,
       aa_tenure,
       uw_tenure,
       aa_membership,
       addon_ind_mla,
       addon_commission_mla,
       addon_ind_hir,
       addon_commission_hir,
       addon_ind_acc,
       addon_commission_acc,
       addon_ind_xsp,
       addon_commission_xsp,
       mta_dttm,
       mta_ind,
       mta_add_net_written_premium,
       mta_add_undiscounted_commission,
       mta_add_ipt_amount,
       mta_add_flex_discount_amount,
       mta_add_woff_discount_amount,
       mta_add_iaf_commission_discount,
       net_written_premium,
       undiscounted_commission,
       ipt_amount,
       flex_discount_amount,
       woff_discount_amount,
       ipt_rate,
       iaf_amount_t AS iaf_amount,
       iaf_commission_discount,
       policy_mta_date,
       policy_mta_mth,
       policy_mta_yr,
       day_of_birth,
       broker_iaf,
       broker_commission_t AS broker_commission,
       broker_commission_xfees,
       broker_commission_woff,
       broker_commission_disc,
       broker_iaf_ipt,
       broker_lapse_disc,
       mta_add_broker_iaf,
       mta_add_broker_commission,
       mta_add_broker_commission_xfees,
       mta_add_broker_commission_woff,
       mta_add_broker_commission_disc,
       mta_add_broker_iaf_ipt,
       perc_broker_commission,
       perc_broker_commission_xfees,
       net_written_premium_aauicl,
       broker_commission_aauicl,
       mta_add_net_premium_aauicl,
       mta_add_commission_aauicl,
       net_written_premium_other,
       broker_commission_other,
       mta_add_net_premium_other,
       mta_add_commission_other,
       aauicl_ind_102,
       net_written_premium_102,
       broker_commission_102,
       aauicl_ind_103,
       net_written_premium_103,
       broker_commission_103,
       aauicl_ind_173,
       net_written_premium_173,
       broker_commission_173,
       load_dttm,
       cancel_effective_dttm_t AS cancel_effective_dttm,
       cancel_reason,
       policy_cancel_date_t AS policy_cancel_date,
       policy_cancel_mth_t AS policy_cancel_mth,
       policy_cancel_yr_t AS policy_cancel_yr,
       policy_cancel_notified_mth_t AS policy_cancel_notified_mth,
       policy_cancel_notified_yr_t AS policy_cancel_notified_yr,
       cancel_cooling,
       time_on_risk,
       broker_ind*time_on_risk AS broker_tor,
       aauicl_ind*time_on_risk AS aauicl_tor
FROM (SELECT c.*,
             CASE
               WHEN cfi_ind_lapse = 1 THEN annual_cover_start_dttm
               ELSE cancel_effective_dttm
             END AS cancel_effective_dttm_t,
             CASE
               WHEN cfi_ind_lapse = 1 THEN CAST(cfi_ind_lapse_dttm,ansidate)
               ELSE policy_cancel_date
             END AS policy_cancel_date_t,
             CASE
               WHEN cfi_ind_lapse = 1 THEN CAST(DATE_TRUNC ('MONTH',cfi_ind_lapse_dttm),ansidate)
               ELSE policy_cancel_mth
             END AS policy_cancel_mth_t,
             CASE
               WHEN cfi_ind_lapse = 1 THEN date_part ('year',cfi_ind_lapse_dttm)
               ELSE policy_cancel_yr
             END AS policy_cancel_yr_t,
             CASE
               WHEN cfi_ind_lapse = 1 THEN CAST(DATE_TRUNC ('MONTH',cfi_ind_lapse_dttm),ansidate)
               ELSE policy_cancel_notified_mth
             END AS policy_cancel_notified_mth_t,
             CASE
               WHEN cfi_ind_lapse = 1 THEN date_part ('year',cfi_ind_lapse_dttm)
               ELSE policy_cancel_notified_yr
             END AS policy_cancel_notified_yr_t,
             CASE
               WHEN cfi_ind_lapse = 1 THEN 0
               ELSE broker_commission
             END AS broker_commission_t,
             CASE
               WHEN cfi_ind_lapse = 1 THEN 0
               ELSE iaf_amount
             END AS iaf_amount_t,
             ((CASE
               WHEN cfi_ind_lapse = 1 THEN annual_cover_start_dttm
               ELSE cancel_effective_dttm
             END
      ) - annual_cover_start_dttm) /(annual_cover_end_dttm - annual_cover_start_dttm) AS time_on_risk
      FROM (SELECT a.*,
                   b.cancel_effective_dttm,
                   b.cancel_reason,
                   b.policy_cancel_date,
                   b.policy_cancel_mth,
                   b.policy_cancel_yr,
                   b.policy_cancel_notified_mth,
                   b.policy_cancel_notified_yr,
                   b.cancel_cooling
            FROM (SELECT *
                  FROM actian.lk_m_policy_history
                  WHERE schedule_cover_start_dttm = annual_cover_start_dttm
                  AND   cfi_ind = 0) a
              LEFT JOIN actian.lk_m_cancel_history b
                     ON a.tia_reference = b.tia_reference
                    AND a.annual_cover_start_dttm = b.annual_cover_start_dttm) c) d
WHERE cancel_effective_dttm_t IS NOT NULL


      ;;
    }

  dimension: aauicl_flag_joint {
    type: number
    sql: ${TABLE}.aauicl_flag_joint ;;
  }

  dimension: aauicl_ind_bds {
    type: number
    sql: ${TABLE}.aauicl_ind_bds ;;
  }

  dimension: aauicl_ind_cts {
    type: number
    sql: ${TABLE}.aauicl_ind_cts ;;
  }

  dimension: aauicl_scheme {
    type: string
    sql: ${TABLE}.aauicl_scheme ;;
  }

  dimension_group: annual_cover_end_dttm {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.annual_cover_end_dttm ;;
  }

  dimension_group: annual_cover_start_dttm {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.annual_cover_start_dttm ;;
  }

  dimension: broker_flag_joint {
    type: number
    sql: ${TABLE}.broker_flag_joint ;;
  }

  dimension: broker_ind_bds {
    type: number
    sql: ${TABLE}.broker_ind_bds ;;
  }

  dimension: broker_ind_cts {
    type: number
    sql: ${TABLE}.broker_ind_cts ;;
  }

  dimension: broker_nb_rb {
    type: string
    sql: ${TABLE}.broker_nb_rb ;;
  }

  dimension: cancel_cooling {
    type: number
    sql: ${TABLE}.cancel_cooling ;;
  }

  dimension: cancel_cooling_bds {
    type: number
    sql: ${TABLE}.cancel_cooling_bds ;;
  }

  dimension: cancel_cooling_cts {
    type: number
    sql: ${TABLE}.cancel_cooling_cts ;;
  }

  dimension_group: cancel_dttm {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.cancel_dttm ;;
  }

  dimension_group: cancel_effective_dttm {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.cancel_effective_dttm ;;
  }

  dimension: cancel_reason {
    type: number
    sql: ${TABLE}.cancel_reason ;;
  }

  dimension: cancel_reason_desc {
    type: string
    sql: ${TABLE}.cancel_reason_desc ;;
  }

  dimension: cover_type {
    type: string
    sql: ${TABLE}.cover_type ;;
  }

  dimension_group: load_dttm {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.load_dttm ;;
  }

  dimension: nb_sw_flag {
    type: string
    sql: ${TABLE}.nb_sw_flag ;;
  }

  dimension_group: policy_cancel {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.policy_cancel_date ;;
  }

  dimension_group: policy_cancel_mth {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.policy_cancel_mth ;;
  }

  dimension_group: policy_cancel_notified_mth {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.policy_cancel_notified_mth ;;
  }

  dimension: policy_cancel_notified_yr {
    type: number
    sql: ${TABLE}.policy_cancel_notified_yr ;;
  }

  dimension: policy_cancel_yr {
    type: number
    sql: ${TABLE}.policy_cancel_yr ;;
  }

  dimension_group: schedule_cover_end_dttm {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.schedule_cover_end_dttm ;;
  }

  dimension_group: schedule_cover_start_dttm {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.schedule_cover_start_dttm ;;
  }

  dimension: status {
    type: string
    sql: ${TABLE}.status ;;
  }

  dimension: tia_customer_no {
    type: string
    sql: ${TABLE}.tia_customer_no ;;
  }

  dimension: tia_reference {
    type: string
    sql: ${TABLE}.tia_reference ;;
  }

  dimension: tia_transaction_no {
    type: string
    sql: ${TABLE}.tia_transaction_no ;;
  }

  dimension_group: transaction {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.transaction_date ;;
  }

  dimension_group: transaction_dttm {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}.transaction_dttm ;;
  }

  dimension: uw_policy_no {
    type: string
    sql: ${TABLE}.uw_policy_no ;;
  }

  dimension: cfi_ind_lapse {
    type: number
    sql: ${TABLE}.cfi_ind_lapse ;;
  }

  dimension: cfi_ind {
    type: number
    sql: ${TABLE}.cfi_ind ;;
  }


  measure: broker_covers {
    label: "Broker Covers"
    type: sum
    sql: ${TABLE}.broker_ind ;;
    value_format_name: decimal_0
  }

  measure: aauicl_covers {
    label: "AAUICL Covers"
    type: sum
    sql: ${TABLE}.aauicl_ind ;;
    value_format_name: decimal_0
  }

  measure: broker_tor {
    label: "Broker TOR"
    type: sum
    sql: ${TABLE}.broker_tor ;;
    value_format_name: decimal_0
  }

  measure: aauicl_tor {
    label: "AAUICL TOR"
    type: sum
    sql: ${TABLE}.aauicl_tor ;;
    value_format_name: decimal_0
  }

  measure: count {
    type: count
    drill_fields: []
  }
}