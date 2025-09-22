-- VALIDACAO DE CARGA DA TABELA
SELECT * FROM "ifood-case-sot"."tbsot_yellow_rides" WHERE dtref='202305' limit 10;


-- Qual a média de valor total (total\_amount) recebido em um mês
-- considerando todos os yellow táxis da frota?
SELECT 
    dtref,
    ROUND(AVG(total_amount), 2) AS media_total_mes
FROM "ifood-case-sot"."tbsot_yellow_rides"
GROUP BY dtref
ORDER BY dtref;

-- Qual a média de passageiros (passenger\_count) por cada hora do dia
-- que pegaram táxi no mês de maio considerando todos os táxis da frota?
SELECT
  HOUR(tpep_pickup_datetime) AS pickup_hour,
  ROUND(AVG(passenger_count), 2) AS avg_passengers
FROM "ifood-case-sot"."tbsot_yellow_rides"
WHERE dtref = '202305'
GROUP BY 1
ORDER BY 1;
