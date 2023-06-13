with tabla_previa as (

SELECT
    case
        when ml.class_1 is null then 'null'
        when ml.class_1 < 100 then '0-100'
        when ml.class_1 < 150 then '100-150'
        when ml.class_1 < 200 then '150-200'
        when ml.class_1 < 250 then '200-250'
        when ml.class_1 < 300 then '250-300'
        when ml.class_1 < 350 then '300-350'
        when ml.class_1 < 400 then '350-400'
        when ml.class_1 < 450 then '400-450'
        when ml.class_1 < 500 then '450-500'
        when ml.class_1 < 550 then '500-550'
        when ml.class_1 < 600 then '550-600'
        when ml.class_1 < 650 then '600-650'
        when ml.class_1 < 700 then '650-700'
        when ml.class_1 < 750 then '700-750'
        when ml.class_1 < 800 then '750-800'
        when ml.class_1 < 850 then '800-850'
        when ml.class_1 < 900 then '850-900'
        when ml.class_1 < 950 then '900-950'
        when ml.class_1 <= 1000 then '950-1000'

        else 'error'
    end as ml_score,

    count(rc.case_id) as Incoming_Qty,
    round(100.00*sum(case when (rc.online_verdict = 'ACCEPT') then 1 else 0 end)/count(rc.case_id),2) Ratio_App_Dlo_Qty,
    sum(case when (rc.online_verdict = 'ACCEPT') then 1 else 0 end) as "dLocal App. Qty",
    round(100.00*sum(case when (cc.result = 'ACCEPT') then 1 else 0 end)/count(rc.case_id),2) Ratio_App_Fnl_Qty,
    sum(case when (cc.result = 'ACCEPT') then 1 else 0 end) as "Final App. Qty",
    sum(case when (cc.result = 'ACCEPT' and id_chargeback is not null) then 1 else 0 end) as CBK_Qty,
    round(100.00*sum(case when (cc.result = 'ACCEPT' and id_chargeback is not null) then 1 else 0 end)/sum(case when (cc.result = 'ACCEPT') then 1 else 0 end),2) as "Ratio CBK Qty",
    
    sum (rc.usd_amount) as Incoming_Amt,
    sum (case when rc.online_verdict='ACCEPT' then rc.usd_amount else 0 end) as "dLocal App. Amt",
    sum (case when cc.result='ACCEPT' then rc.usd_amount else 0 end) as "Final App. Amt",
    sum (case when cc.result='ACCEPT' and cbk.id_chargeback is not null then rc.usd_amount else 0 end) as Cbk_Amt,
    round(100.00*sum(case when (cc.result = 'ACCEPT' and id_chargeback is not null) then rc.usd_amount else 0 end)/sum(case when (cc.result = 'ACCEPT') then rc.usd_amount else 0 end),2) as "Ratio CBK Amt",
    
    '1' as uno
    
    
FROM fraud.risk_risk_case rc

        LEFT JOIN fraud.risk_risk_case_collect cc
            ON rc.case_id = cc.case_id

        LEFT JOIN "dlocal_eu1_office_live_machine_learning"."inferences_mx"  ml
            ON ml.case_id = rc.case_id
            
        LEFT JOIN dl_main_db.unipay_chargebacks as cbk 
            ON rc.ticket_id = cbk.id_boleto 
            AND cc.result='ACCEPT'
    
WHERE 1=1
    AND rc.merchant_reference = '54061'
    AND rc.created_date between date '2023-04-18' and date '2023-05-17'
    --AND rc.country_code = 'BR'
    --AND ml.class_1 IS NOT null
    AND rc.operation_type in ('WITH_CVV', 'WITHOUT_CVV', 'TOKEN')
    AND rc.online_verdict_reason = 'Default'


    
GROUP BY 1
ORDER BY 1
)


SELECT
    *,
    ROUND(100.00*"Final App. Qty" / SUM("Final App. Qty") OVER(PARTITION BY uno),2) Share_Fnl_Qty,
    ROUND(100.00*Cbk_Qty / SUM(Cbk_Qty) OVER(PARTITION BY uno),2) Share_Cbk_Qty,
    ROUND(100.00*"Final App. Amt" / SUM("Final App. Amt") OVER(PARTITION BY uno),2) Share_Fnl_Amt,
    ROUND(100.00*Cbk_Amt / SUM(Cbk_Amt) OVER(PARTITION BY uno),2) Share_Cbk_Amt




FROM tabla_previa

