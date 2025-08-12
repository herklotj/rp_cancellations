view: lk_m_policy_history_written {
  derived_table: {
    sql:
      select * from
        (
          SELECT *
          FROM dbuser.lkr_motor_policy_history
          WHERE SCHEDULE_COVER_START_DTTM = ANNUAL_COVER_START_DTTM
          AND   CFI_IND = 0
        ) a
      left join v_ice_canc_at_inception cfi
      ON a.uw_policy_no = cfi.policy_reference_number
      AND date(a.annual_cover_start_dttm) = cfi.term_inception_date
        ;;
  }

  dimension_group: annual_cover_start_dttm {
    label: "Annual Cover Start DTTM"
    type: time
    timeframes: [
      raw,
      date,
      week,
      month,
      quarter,
      year,
      fiscal_year
    ]
    sql: CAST(${TABLE}.annual_cover_start_dttm AS TIMESTAMP WITHOUT TIME ZONE) ;;
  }

  dimension: broker_nb_rb {
    label: "Broker NB/RB"
    type: string
    sql: ${TABLE}.broker_nb_rb ;;
  }

  dimension: aauicl_scheme {
    label: "AAUICL Scheme"
    type: string
    sql: ${TABLE}.aauicl_scheme ;;
  }

  dimension: cbi {
    type: number
    sql: ${TABLE}.cbi ;;
  }

  measure: aauicl_covers {
    label: "AAUICL Covers"
    type: sum
    sql: ${TABLE}.aauicl_ind ;;
    value_format_name: decimal_0
  }

}
