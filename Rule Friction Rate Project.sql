# Query to detect friction, recall, and precision of implementing a rule within a merchant (ex. DiDi Foods) given parameters (ex. country, card brand, date)

SELECT
    year_month as "Date",
    friction_qty_pf as "Est. dLocal Friction QTY",
    friction_qty_fnl as "Est. Final Friction QTY",
    recall_qty as "Est. Recall QTY",
    precision_qty as "Est. Precision QTY",
    
    friction_amt_pf as "Est. dLocal Friction AMT",
    friction_amt_fnl as "Est. Final Friction AMT",
    recall_amt as "Est. Recall AMT",
    precision_amt as "Est. Precision AMT"


from(
select
    year_month,
    

        round(100.00*sum((case when corte = 'REJECT' then app_pf_qty else 0 end))/sum(app_pf_qty),2) friction_qty_pf,
        round(100.00*sum((case when corte = 'REJECT' then app_fnl_qty else 0 end))/sum(app_fnl_qty),2) friction_qty_fnl,
        round(100.00*sum((case when corte = 'REJECT' then fraud_qty else 0 end))/sum(fraud_qty),2) recall_qty,
        round(100.00*sum((case when corte = 'REJECT' then fraud_qty else 0 end))/sum(case when corte = 'REJECT' then app_fnl_qty else 0 end),2) precision_qty,
        
        round(100.00*sum((case when corte = 'REJECT' then app_pf_amt else 0 end))/sum(app_pf_amt),2) friction_amt_pf,
        round(100.00*sum((case when corte = 'REJECT' then app_fnl_amt else 0 end))/sum(app_fnl_amt),2) friction_amt_fnl,
        round(100.00*sum((case when corte = 'REJECT' then fraud_amt else 0 end))/sum(fraud_amt),2) recall_amt,
        round(100.00*sum((case when corte = 'REJECT' then fraud_amt else 0 end))/sum(case when corte = 'REJECT' then app_fnl_amt else 0 end),2) precision_amt
    
from (
    select
        concat(cast(year(rc.date_created_date) as varchar), '_', cast(month(rc.date_created_date) as varchar)) as year_month,
        
            case when
                     
                     rc.online_verdict_reason = 'DiDi - Default'
                     --AND "multas_new"."procesador" = 'Banorte'
                     AND c.brand = 'VI'
                     AND c.country <> 'MX'
                
            then 'REJECT' else 'ACCEPT' end as corte,
            
-- Metricas
        count(rc.case_id) as qty,
        sum(case when rc.online_verdict ='ACCEPT' then 1 else 0 end) as app_pf_qty,
        sum(case when cc.result='ACCEPT' then 1 else 0 end) as app_fnl_qty,
        sum(case when (cc.result='ACCEPT' and cbk.id_chargeback is not null) then 1
         when (cc.result='ACCEPT' and refund.id_boleto is not null) then 1
         else 0 end) as fraud_qty,
        
        sum(rc.usd_amount) as amt,
        sum(case when rc.online_verdict='ACCEPT' then rc.usd_amount else 0 end) as app_pf_amt,
        sum(case when cc.result='ACCEPT' then rc.usd_amount else 0 end) as app_fnl_amt,
        sum(case when (cc.result='ACCEPT' and cbk.id_chargeback is not null) then rc.usd_amount
         when (cc.result='ACCEPT' and refund.id_boleto is not null) then rc.usd_amount
         else 0 end) as fraud_amt        

FROM fraud.risk_risk_case rc

    LEFT JOIN
    fraud.risk_risk_case_collect as cc 
    on rc.case_id = cc.case_id

    LEFT JOIN
    dl_main_db.unipay_chargebacks as cbk 
    on rc.ticket_id = cbk.id_boleto 
    and cc.result='ACCEPT'

    LEFT JOIN 
    fraud.risk_card c 
    on rc.card_id = c.card_id
    
    LEFT JOIN 
    gsheets.cbk_con_refund refund 
    on cast(rc.ticket_id as varchar) = cast(refund.id_boleto as varchar)
    

WHERE 1=1
    AND rc.merchant_reference = '29486'
    AND rc.created_date between date '2023-02-01' and date '2023-04-30'
    AND rc.operation_type in ('WITH_CVV', 'WITHOUT_CVV', 'TOKEN')

    group by 1,2
    ) as subq
    
group by 1
) as subz
Order by 1
group by 1,2,3,4,5,6,7,8,9
