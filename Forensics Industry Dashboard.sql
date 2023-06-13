SELECT 
    merchant_name as "MERCHANT",
    merchant_reference as "MID",
    industry as "INDUSTRY",
    tier as "TIER",
    --rc.operation_type as "OPERATION TYPE",
    --rc.operation_name as "OPERATION NAME",
    share_attack_total as "Est. Attack Share",
    ratio_cbk_qty as "Est. CBK Ratio",
    ratio_app_final_qty as "Est. App Final"
    


from(
select
    merchant_name,
    merchant_reference,
    industry,
    tier,
    
        round(100.00*sum(app_fnl_qty)/sum(qty),2) ratio_app_final_qty,
        round(100.00*sum(cbk_qty)/sum(app_fnl_qty),2) ratio_cbk_qty,
        round(100.00*sum(fraud_qty)/sum(qty),2) share_attack_total
        
    
from (
    select
        mer.merchant_name,
        rc.merchant_reference,
        mer.industry,
        mer.tier,
        count(rc.case_id) qty,
    
        sum(case when (rc.online_verdict = 'ACCEPT') then 1 else 0 end) app_pf_qty,
        sum(case when (rc.online_verdict = 'ACCEPT' and cc.result = 'ACCEPT') then 1 else 0 end) app_fnl_qty,
        
        --sum(case when cc.result = 'ACCEPT' or cc.reason in ('200','400','600') or (rc.online_verdict = 'ACCEPT' and cc.reason is null) then 1 else 0 end) auth_qty,
        sum(case when result = 'ACCEPT' and id_chargeback is not null then 1 else 0 end) cbk_qty,
        sum(case when (cc.reason in ('317','306','303','311','312','305','301','310','313') OR cbk.id_boleto is not null) then 1 else 0 end) fraud_qty



FROM fraud.risk_risk_case rc

        LEFT JOIN fraud.risk_risk_case_collect cc
            ON rc.case_id = cc.case_id

        LEFT JOIN fraud.risk_card_new c 
            ON rc.card_id = c.card_id
            
        LEFT JOIN dl_db_master_batch.unipay_chargebacks cbk
            ON rc.ticket_id = cbk.id_boleto
            AND cc.result = 'ACCEPT'
            
        LEFT JOIN gsheets.merchant_data_pf mer
            ON rc.merchant_reference = mer.merchant_reference
            AND rc.country_code = mer.country_code
    
WHERE (((rc.created_date) >= ((TIMESTAMP '2022-11-01')) AND (rc.created_date) < ((TIMESTAMP '2022-12-01'))))

    AND mer.big_industry = 'Recurring Payments'
    AND rc.operation_type in ('WITH_CVV', 'WITHOUT_CVV', 'TOKEN')

        
    group by 1,2,3,4
    ) as subq
    
group by 1,2,3,4
) as subz

group by 1,2,3,4,5,6,7