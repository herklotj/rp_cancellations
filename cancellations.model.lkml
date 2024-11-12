connection: "av2"

# include all the views
include: "/views/**/*.view"

datagroup: cancellations_default_datagroup {
  # sql_trigger: SELECT MAX(id) FROM etl_log;;
  max_cache_age: "1 hour"
}

persist_with: cancellations_default_datagroup


explore: cancellations {}
explore: lk_m_cancel_history {}
explore: lk_m_policy_history_written {}
