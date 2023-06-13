SELECT
    "risk_case"."online_verdict_reason" AS "risk_case.online_verdict_reason",
    "risk_case"."online_verdict" AS "risk_case.online_verdict",
    COUNT(*) AS "risk_case.count_risk_case",
    COALESCE(SUM(case
      when ( "risk_case"."online_verdict"  = 'ACCEPT') then 1
      else 0 END), 0) AS "risk_case.count_verdict_accept",
    COALESCE(SUM(case
      when ( "risk_case"."online_verdict"  = 'REJECT') then 1
      else 0 END), 0) AS "risk_case.count_verdict_reject",
    COALESCE(SUM(case
      when ( "risk_case_collect"."result"  = 'ACCEPT') then 1
      else 0 END), 0) AS "risk_case_collect.count_result_accept",
    COALESCE(SUM(case
      when ( "risk_case_collect"."result"  = 'REJECT') then 1
      else 0 END), 0) AS "risk_case_collect.count_result_reject",
    COALESCE(CAST( ( SUM(DISTINCT (CAST(FLOOR(COALESCE( case
         when ( "chargebacks"."id_chargeback"  is not null) then 1
         else 0 END ,0)*(1000000*1.0)) AS DECIMAL(38,0))) + CAST(STRTOL(LEFT(MD5(CAST( chargebacks.id_chargeback   AS VARCHAR)),15),16) AS DECIMAL(38,0))* 1.0e8 + CAST(STRTOL(RIGHT(MD5(CAST( chargebacks.id_chargeback   AS VARCHAR)),15),16) AS DECIMAL(38,0)) ) - SUM(DISTINCT CAST(STRTOL(LEFT(MD5(CAST( chargebacks.id_chargeback   AS VARCHAR)),15),16) AS DECIMAL(38,0))* 1.0e8 + CAST(STRTOL(RIGHT(MD5(CAST( chargebacks.id_chargeback   AS VARCHAR)),15),16) AS DECIMAL(38,0))) )  AS DOUBLE PRECISION) / CAST((1000000*1.0) AS DOUBLE PRECISION), 0) AS "chargebacks.count"
FROM
    "risk_case" AS "risk_case"
    LEFT JOIN "fact_chargeback" AS "chargebacks" ON "risk_case"."id_transaction" = "chargebacks"."id_transaction"
    LEFT JOIN "public"."risk_case_collect" AS "risk_case_collect" ON "risk_case"."case_id" = "risk_case_collect"."case_id"
WHERE ("risk_case"."created_date") >= (TIMESTAMP '2023-04-01') AND "risk_case"."merchant_reference" = '51044' AND "risk_case"."country_code" = 'BR'
GROUP BY
    1,
    2
ORDER BY
    3 DESC
LIMIT 100

-- sql for creating the total and/or determining pivot columns
SELECT
    COUNT(*) AS "risk_case.count_risk_case",
    COALESCE(SUM(case
      when ( "risk_case"."online_verdict"  = 'ACCEPT') then 1
      else 0 END), 0) AS "risk_case.count_verdict_accept",
    COALESCE(SUM(case
      when ( "risk_case"."online_verdict"  = 'REJECT') then 1
      else 0 END), 0) AS "risk_case.count_verdict_reject",
    COALESCE(SUM(case
      when ( "risk_case_collect"."result"  = 'ACCEPT') then 1
      else 0 END), 0) AS "risk_case_collect.count_result_accept",
    COALESCE(SUM(case
      when ( "risk_case_collect"."result"  = 'REJECT') then 1
      else 0 END), 0) AS "risk_case_collect.count_result_reject",
    COALESCE(CAST( ( SUM(DISTINCT (CAST(FLOOR(COALESCE( case
         when ( "chargebacks"."id_chargeback"  is not null) then 1
         else 0 END ,0)*(1000000*1.0)) AS DECIMAL(38,0))) + CAST(STRTOL(LEFT(MD5(CAST( chargebacks.id_chargeback   AS VARCHAR)),15),16) AS DECIMAL(38,0))* 1.0e8 + CAST(STRTOL(RIGHT(MD5(CAST( chargebacks.id_chargeback   AS VARCHAR)),15),16) AS DECIMAL(38,0)) ) - SUM(DISTINCT CAST(STRTOL(LEFT(MD5(CAST( chargebacks.id_chargeback   AS VARCHAR)),15),16) AS DECIMAL(38,0))* 1.0e8 + CAST(STRTOL(RIGHT(MD5(CAST( chargebacks.id_chargeback   AS VARCHAR)),15),16) AS DECIMAL(38,0))) )  AS DOUBLE PRECISION) / CAST((1000000*1.0) AS DOUBLE PRECISION), 0) AS "chargebacks.count"
FROM
    "risk_case" AS "risk_case"
    LEFT JOIN "fact_chargeback" AS "chargebacks" ON "risk_case"."id_transaction" = "chargebacks"."id_transaction"
    LEFT JOIN "public"."risk_case_collect" AS "risk_case_collect" ON "risk_case"."case_id" = "risk_case_collect"."case_id"
WHERE ("risk_case"."created_date") >= (TIMESTAMP '2023-04-01') AND "risk_case"."merchant_reference" = '51044' AND "risk_case"."country_code" = 'BR'
LIMIT 1