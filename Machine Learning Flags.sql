WITH table_tmp AS (
    SELECT
        rc.case_id,
        rc.merchant_reference,
        rc.created_date,
        rc.case_id as "CASE",
        rc.ticket_id,
        rc.card_id,
        rc.operation_type, 
        rc.operation_name,
        rc.local_amount,
        rc.usd_amount,
        rc.online_verdict,
        rc.online_verdict_reason,
        cc.result,
        cc.reason,
        CASE WHEN cbk.id_boleto IS NULL THEN 0 ELSE 1 END as cbk_flag,
        CASE WHEN 
            rc.online_verdict = 'REJECT' AND rc.online_verdict_reason in (
                'Retail Sift Model - SHEIN BR - Same Device 1D App',
                'Shein MX - Same Email Diff Card - Amount - Mx Model',
                'Retail Sift Model - SHEIN BR - Average - RetailV2 and MX',
                'Shein MX - New Email - High amount - Model - Credit - VI',
                'Shein MX - Same Email 7D App - New Card - Model - MC',
                'Shein MX - Same Card 7D App - New Email - Model - Credit',
                'Shein MX - Same Email Diff Card - New Email - Amount - Retail Model - Credit',
                'Risk Limit - Same Email Diff Card Att 1M',
                'Shein MX - Same Card 7D App - Model - VI',
                'Stop Loss - Same Card 1D Approval Limit (USD)',
                'Risk Limit - Same Email Diff Card Att 2D'
            )
        THEN 1 ELSE 0 END as pf_high_risk_flag,
        CASE WHEN rc.online_verdict = 'ACCEPT' AND cc.result = 'REJECT' AND cc.reason IN ('303','310','311','312''313','317') THEN 1 ELSE 0 END as fraud_reason_status_flag,
        CASE WHEN rc.online_verdict = 'ACCEPT' AND cc.result = 'REJECT' AND cc.reason IN ('305','308','319') THEN 1 ELSE 0 END as fraud_high_atmpt_flag,
        CASE WHEN 
            rc.online_verdict = 'ACCEPT' AND rc.online_verdict_reason in (
                'Positive User 3M Lvl 5',
                'Positive User Lvl 5',
                'Positive User Lvl 2',
                'Positive User Lvl 3',
                'Positive User 3M Lvl 3',
                'Positive User Lvl 9'
            )
        THEN 1 ELSE 0 END as pf_high_risk_pos_user_flag,
        CASE WHEN 
            rc.online_verdict = 'ACCEPT' AND rc.online_verdict_reason in (
                'Super Positive',
                'Positive User 3M Lvl 1',
                'Positive User Lvl 4',
                'Positive User Lvl 1',
                'Positive User Prepaid',
                'Super Positive 3M',
                'Super Positive - GreenChannel',
                'Positive User 1M Lvl 2',
                'Super Positive 3M - GreenChannel',
                'Positive User Lvl 1 - GreenChannel',
                'Positive User Cash Lvl 1',
                'Positive User 3M Lvl 1 - GreenChannel',
                'Super Positive - GreenChannel - Control Group',
                'Positive User Lvl 2 - GreenChannel - Control Group',
                'Super Positive 3M - GreenChannel - Control Group',
                'Positive User Lvl 1 - GreenChannel - Control Group',
                'Positive User 3M Lvl 8',
                'Positive User 3M Lvl 1 - Control Group',
                'Positive User Lvl 5 - GreenChannel',
                'Positive User 3M Lvl 2 - GreenChannel',
                'Positive User Lvl 3 - GreenChannel',
                'Positive User Lvl 8 - GreenChannel',
                'Positive User Lvl 5 - GreenChannel - Control Group',
                'Positive User 3M Lvl 2 - Control Group',
                'Positive User Lvl 8 - GreenChannel - Control Group',
                'Positive User Lvl 3 - GreenChannel - Control Group',
                'Positive User Lvl 6',
                'Positive List - Email',
                'Retail Sift Model SHEIN MX Installments - SHEIN Positives 1M',
                'Positive User 3M Lvl 8'
            )
        THEN 1 ELSE 0 END as pf_low_risk_pos_user_flag
        
FROM fraud.risk_risk_case rc
    
    LEFT JOIN fraud.risk_risk_case_collect cc
        ON rc.case_id = cc.case_id
        
    LEFT JOIN dl_main_db.unipay_chargebacks cbk
        ON rc.ticket_id = cbk.id_boleto
            AND cc.result = 'ACCEPT'

WHERE 
    rc.date_created_date >= TIMESTAMP '2022-01-01'
            AND rc.operation_type in ('WITH_CVV', 'WITHOUT_CVV', 'TOKEN')
            AND rc.merchant_reference in (
                '51044','65786'
            )
        
)

SELECT 
    SUBSTRING(CAST(created_date AS VARCHAR), 1, 10) as yyyy_mm_dd,
    sum(case when result = 'ACCEPT' then 1 else 0 end) as apr_purchase, 
    sum(case when result <> 'ACCEPT' then 1 else 0 end) as rej_purchase,
    SUM(pf_high_risk_flag) AS q_pf_high_risk_flag,
    SUM(fraud_reason_status_flag) AS q_fraud_reason_status_flag,
    SUM(fraud_high_atmpt_flag) AS q_fraud_high_atmpt_flag,
    SUM(cbk_flag) AS q_cbk_flag,
    SUM(pf_high_risk_pos_user_flag) AS q_pf_high_risk_pos_user_flag,
    SUM(pf_low_risk_pos_user_flag) AS q_pf_low_risk_pos_user_flag,
    count(*) q_trx_tot,
    SUM(
        CASE WHEN 
            pf_high_risk_flag = 1 OR
            fraud_reason_status_flag = 1 OR
            cbk_flag = 1
            OR
            fraud_high_atmpt_flag = 1
        THEN 1
        ELSE 0 END
    ) as tot_class_1,
    SUM(
        CASE WHEN 
            pf_high_risk_flag = 0 AND
            fraud_reason_status_flag = 0 AND
            cbk_flag = 0 AND 
            result IN ('ACCEPT','AUTHORIZE')
        THEN 1
        ELSE 0 END
    ) as tot_class_0
FROM table_tmp as tt1



GROUP BY
    SUBSTRING(CAST(created_date AS VARCHAR), 1, 10)
ORDER BY 1 asc
;