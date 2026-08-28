-- 1. Deleta a tabela antiga para não dar conflito de estrutura
DROP TABLE IF EXISTS dataset_final;

-- 2. Cria a nova tabela com a hidrelétrica
CREATE TABLE dataset_final AS
WITH ons_diario AS (
    SELECT 
        SUBSTR("din_instante", 1, 10) AS data_dia,
        SUM(CASE 
            WHEN "val_gereolica" LIKE '%,%' THEN CAST(REPLACE(REPLACE("val_gereolica", '.', ''), ',', '.') AS FLOAT)
            ELSE CAST("val_gereolica" AS FLOAT)
        END) AS geracao_eolica_total_dia,
        SUM(CASE 
            WHEN "val_gersolar" LIKE '%,%' THEN CAST(REPLACE(REPLACE("val_gersolar", '.', ''), ',', '.') AS FLOAT)
            ELSE CAST("val_gersolar" AS FLOAT)
        END) AS geracao_solar_total_dia,
          SUM(CASE 
            WHEN "val_gertermica" LIKE '%,%' THEN CAST(REPLACE(REPLACE("val_gertermica", '.', ''), ',', '.') AS FLOAT)
            ELSE CAST("val_gertermica" AS FLOAT)
        END) AS geracao_termica_total_dia,
        
        -- NOVA VARIÁVEL: Tratando e somando a geração hidráulica diária
        SUM(CASE 
            WHEN "val_gerhidraulica" LIKE '%,%' THEN CAST(REPLACE(REPLACE("val_gerhidraulica", '.', ''), ',', '.') AS FLOAT)
            ELSE CAST("val_gerhidraulica" AS FLOAT)
        END) AS geracao_hidreletrica_total_dia
    FROM 
        BALANCO_ENERGIA_SUBSISTEMA 
    WHERE 
        "din_instante" IS NOT NULL
    GROUP BY 
        SUBSTR("din_instante", 1, 10)
),
ons_formatado AS (
    SELECT 
        SUBSTR(data_dia, 9, 2) || '/' || 
        SUBSTR(data_dia, 6, 2) || '/' || 
        SUBSTR(data_dia, 1, 4) AS data_ons_com_barra,
        geracao_eolica_total_dia,
        geracao_solar_total_dia,
        geracao_hidreletrica_total_dia,
        geracao_termica_total_dia
    FROM 
        ons_diario
)
SELECT 
    p."Data" AS data_referencia,
    CAST(REPLACE(p."Preço - petróleo bruto - Brent (FOB) - US$ - Energy Information Administration (EIA) - EIA366_PBRENT366", ',', '.') AS FLOAT) AS preco_brent,
    o.geracao_eolica_total_dia AS geracao_eolica_mwmed,
    o.geracao_solar_total_dia AS geracao_solar_mwmed,
    o.geracao_hidreletrica_total_dia AS geracao_hidreletrica_mwmed,
    o.geracao_termica_total_dia AS geracao_termica_mwmed
FROM 
    ipeadata p
INNER JOIN 
    ons_formatado o ON p."Data" = o.data_ons_com_barra
WHERE 
    p."Preço - petróleo bruto - Brent (FOB) - US$ - Energy Information Administration (EIA) - EIA366_PBRENT366" IS NOT NULL 
    AND p."Preço - petróleo bruto - Brent (FOB) - US$ - Energy Information Administration (EIA) - EIA366_PBRENT366" != ''
    AND p."Preço - petróleo bruto - Brent (FOB) - US$ - Energy Information Administration (EIA) - EIA366_PBRENT366" != 'ND'
    AND CAST(SUBSTR(p."Data", -4) AS INTEGER) >= 2012;
        
SELECT * FROM dataset_final;