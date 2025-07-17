# До рефлексии
WITH 

trade_overview AS (
  SELECT
    COUNT(DISTINCT c.civilization_type) AS total_trading_partners,
    SUM(tt.value) AS all_time_trade_value,
    SUM(CASE WHEN tt.balance_direction = 'incoming' THEN tt.value ELSE -tt.value END) AS all_time_trade_balance
  FROM trade_transactions tt
  JOIN caravans c ON tt.caravan_id = c.caravan_id
),

civilization_trade AS (
  SELECT
    c.civilization_type,
    COUNT(DISTINCT c.caravan_id) AS total_caravans,
    SUM(tt.value) AS total_trade_value,
    SUM(CASE WHEN tt.balance_direction = 'incoming' THEN tt.value ELSE -tt.value END) AS trade_balance,
    CASE 
      WHEN SUM(CASE WHEN tt.balance_direction = 'incoming' THEN tt.value ELSE -tt.value END) > 0 
      THEN 'Favorable' ELSE 'Unfavorable' 
    END AS trade_relationship,
    CORR(
      CASE WHEN tt.balance_direction = 'incoming' THEN tt.value ELSE -tt.value END,
      de.relationship_change
    ) AS diplomatic_correlation,
    ARRAY_AGG(DISTINCT c.caravan_id) AS caravan_ids
  FROM trade_transactions tt
  JOIN caravans c ON tt.caravan_id = c.caravan_id
  LEFT JOIN diplomatic_events de ON c.caravan_id = de.caravan_id
  GROUP BY c.civilization_type
),

import_dependencies AS (
  SELECT
    cg.material_type,
    SUM(cg.quantity * cg.value) / NULLIF(SUM(fr.quantity), 0) AS dependency_score,
    SUM(cg.quantity) AS total_imported,
    COUNT(DISTINCT cg.resource_id) AS import_diversity,
    ARRAY_AGG(DISTINCT cg.resource_id) AS resource_ids
  FROM caravan_goods cg
  JOIN trade_transactions tt ON cg.caravan_id = tt.caravan_id
  JOIN fortress_resources fr ON cg.resource_id = fr.resource_id
  WHERE tt.balance_direction = 'incoming'
  GROUP BY cg.material_type
  HAVING SUM(cg.quantity) > 0
  ORDER BY dependency_score DESC
  LIMIT 5
),

export_stats AS (
  SELECT
    w.type AS workshop_type,
    p.type AS product_type,
    ROUND(SUM(CASE WHEN tt.balance_direction = 'outgoing' THEN cg.quantity ELSE 0 END) * 100.0 / 
         NULLIF(SUM(wp.quantity), 0), 1) AS export_ratio,
    ROUND(AVG(cg.value / NULLIF(p.value, 0)), 2) AS avg_markup,
    ARRAY_AGG(DISTINCT w.workshop_id) AS workshop_ids
  FROM workshops w
  JOIN workshop_products wp ON w.workshop_id = wp.workshop_id
  JOIN products p ON wp.product_id = p.product_id
  LEFT JOIN caravan_goods cg ON p.product_id = cg.original_product_id
  LEFT JOIN trade_transactions tt ON cg.caravan_id = tt.caravan_id AND tt.balance_direction = 'outgoing'
  GROUP BY w.type, p.type
  HAVING SUM(wp.quantity) > 0
  ORDER BY export_ratio DESC
),

trade_timeline AS (
  SELECT
    EXTRACT(YEAR FROM tt.date) AS year,
    EXTRACT(QUARTER FROM tt.date) AS quarter,
    SUM(tt.value) AS quarterly_value,
    SUM(CASE WHEN tt.balance_direction = 'incoming' THEN tt.value ELSE -tt.value END) AS quarterly_balance,
    COUNT(DISTINCT cg.type) AS trade_diversity
  FROM trade_transactions tt
  LEFT JOIN caravan_goods cg ON tt.caravan_id = cg.caravan_id
  GROUP BY EXTRACT(YEAR FROM tt.date), EXTRACT(QUARTER FROM tt.date)
  ORDER BY year, quarter
)

SELECT
  JSON_BUILD_OBJECT(
    'total_trading_partners', to.total_trading_partners,
    'all_time_trade_value', to.all_time_trade_value,
    'all_time_trade_balance', to.all_time_trade_balance,
    'civilization_data', JSON_BUILD_OBJECT(
      'civilization_trade_data', (
        SELECT JSON_AGG(
          JSON_BUILD_OBJECT(
            'civilization_type', ct.civilization_type,
            'total_caravans', ct.total_caravans,
            'total_trade_value', ct.total_trade_value,
            'trade_balance', ct.trade_balance,
            'trade_relationship', ct.trade_relationship,
            'diplomatic_correlation', COALESCE(ct.diplomatic_correlation, 0),
            'caravan_ids', ct.caravan_ids
          )
        )
        FROM civilization_trade ct
      )
    ),
    'critical_import_dependencies', JSON_BUILD_OBJECT(
      'resource_dependency', (
        SELECT JSON_AGG(
          JSON_BUILD_OBJECT(
            'material_type', id.material_type,
            'dependency_score', id.dependency_score,
            'total_imported', id.total_imported,
            'import_diversity', id.import_diversity,
            'resource_ids', id.resource_ids
          )
        )
        FROM import_dependencies id
      )
    ),
    'export_effectiveness', JSON_BUILD_OBJECT(
      'export_effectiveness', (
        SELECT JSON_AGG(
          JSON_BUILD_OBJECT(
            'workshop_type', es.workshop_type,
            'product_type', es.product_type,
            'export_ratio', es.export_ratio,
            'avg_markup', es.avg_markup,
            'workshop_ids', es.workshop_ids
          )
        )
        FROM export_stats es
      )
    ),
    'trade_timeline', JSON_BUILD_OBJECT(
      'trade_growth', (
        SELECT JSON_AGG(
          JSON_BUILD_OBJECT(
            'year', tl.year,
            'quarter', tl.quarter,
            'quarterly_value', tl.quarterly_value,
            'quarterly_balance', tl.quarterly_balance,
            'trade_diversity', tl.trade_diversity
          )
        )
        FROM trade_timeline tl
      )
    )
  ) AS trade_analysis
FROM trade_overview to;

# Рефлексия
1. В эталоне более детализированная вложенность JSON
2. Эталон содержит дополнительные разделы и более глубокую аналитику
3. В эталоне используются более сложные формулы для расчетов и более сложные метрики
4. В эталоне больше информации о товарах и более подробная временная аналитика


#После рефлексии
WITH civilization_trade_history AS (
    SELECT 
        c.civilization_type,
        EXTRACT(YEAR FROM c.arrival_date) AS trade_year,
        COUNT(DISTINCT c.caravan_id) AS caravan_count,
        SUM(tt.value) AS total_trade_value,
        SUM(CASE WHEN tt.balance_direction = 'incoming' THEN tt.value ELSE 0 END) AS import_value,
        SUM(CASE WHEN tt.balance_direction = 'outgoing' THEN tt.value ELSE 0 END) AS export_value,
        COUNT(DISTINCT cg.goods_id) AS unique_goods_traded
    FROM 
        caravans c
    JOIN 
        trade_transactions tt ON c.caravan_id = tt.caravan_id
    LEFT JOIN 
        caravan_goods cg ON c.caravan_id = cg.caravan_id
    GROUP BY 
        c.civilization_type, EXTRACT(YEAR FROM c.arrival_date)
),

fortress_resource_dependency AS (
    SELECT 
        cg.material_type,
        COUNT(DISTINCT cg.goods_id) AS times_imported,
        SUM(cg.quantity) AS total_imported,
        SUM(cg.value) AS total_import_value,
        COUNT(DISTINCT c.caravan_id) AS caravans_importing,
        AVG(cg.price_fluctuation) AS avg_price_fluctuation,
        (COUNT(DISTINCT cg.goods_id) * 
         SUM(cg.quantity) * 
         (1.0 / NULLIF(COUNT(DISTINCT c.civilization_type), 0)) AS dependency_score
    FROM 
        caravan_goods cg
    JOIN 
        caravans c ON cg.caravan_id = c.caravan_id
    WHERE 
        tt.balance_direction = 'incoming'
    GROUP BY 
        cg.material_type
),

diplomatic_trade_correlation AS (
    SELECT 
        c.civilization_type,
        CORR(
            de.relationship_change,
            tt.value
        ) AS trade_diplomacy_correlation
    FROM 
        caravans c
    JOIN 
        trade_transactions tt ON c.caravan_id = tt.caravan_id
    LEFT JOIN 
        diplomatic_events de ON c.civilization_type = de.civilization_type
    GROUP BY 
        c.civilization_type
),

workshop_export_effectiveness AS (
    SELECT 
        p.type AS product_type,
        w.type AS workshop_type,
        COUNT(DISTINCT p.product_id) AS products_created,
        COUNT(DISTINCT CASE WHEN cg.goods_id IS NOT NULL THEN p.product_id END) AS products_exported,
        SUM(p.value) AS total_production_value,
        SUM(CASE WHEN cg.goods_id IS NOT NULL THEN cg.value ELSE 0 END) AS export_value,
        AVG(CASE WHEN cg.goods_id IS NOT NULL THEN (cg.value / p.value) ELSE NULL END) AS avg_export_markup
    FROM 
        products p
    JOIN 
        workshops w ON p.workshop_id = w.workshop_id
    LEFT JOIN 
        caravan_goods cg ON p.product_id = cg.original_product_id AND tt.balance_direction = 'outgoing'
    GROUP BY 
        p.type, w.type
),

trade_timeline AS (
    SELECT 
        EXTRACT(YEAR FROM tt.date) AS year,
        EXTRACT(QUARTER FROM tt.date) AS quarter,
        SUM(tt.value) AS quarterly_trade_value,
        COUNT(DISTINCT c.civilization_type) AS trading_civilizations,
        SUM(CASE WHEN tt.balance_direction = 'incoming' THEN tt.value ELSE 0 END) AS import_value,
        SUM(CASE WHEN tt.balance_direction = 'outgoing' THEN tt.value ELSE 0 END) AS export_value,
        LAG(SUM(tt.value)) OVER (ORDER BY EXTRACT(YEAR FROM tt.date), EXTRACT(QUARTER FROM tt.date)) AS previous_quarter_value
    FROM 
        trade_transactions tt
    JOIN 
        caravans c ON tt.caravan_id = c.caravan_id
    GROUP BY 
        EXTRACT(YEAR FROM tt.date), EXTRACT(QUARTER FROM tt.date)
)

SELECT 
    JSON_BUILD_OBJECT(
        'total_trading_partners', (SELECT COUNT(DISTINCT civilization_type) FROM caravans),
        'all_time_trade_value', (SELECT SUM(total_trade_value) FROM civilization_trade_history),
        'all_time_trade_balance', (SELECT SUM(export_value) - SUM(import_value) FROM civilization_trade_history),
        
        'civilization_data', JSON_BUILD_OBJECT(
            'civilization_trade_data', (
                SELECT JSON_AGG(
                    JSON_BUILD_OBJECT(
                        'civilization_type', cth.civilization_type,
                        'total_caravans', SUM(cth.caravan_count),
                        'total_trade_value', SUM(cth.total_trade_value),
                        'trade_balance', SUM(cth.export_value) - SUM(cth.import_value),
                        'trade_relationship', CASE 
                            WHEN (SUM(cth.export_value) - SUM(cth.import_value)) > 0 THEN 'Favorable'
                            ELSE 'Unfavorable' 
                        END,
                        'diplomatic_correlation', COALESCE(dtc.trade_diplomacy_correlation, 0),
                        'caravan_ids', (
                            SELECT JSON_AGG(c.caravan_id)
                            FROM caravans c
                            WHERE c.civilization_type = cth.civilization_type
                        )
                    )
                )
                FROM civilization_trade_history cth
                LEFT JOIN diplomatic_trade_correlation dtc ON cth.civilization_type = dtc.civilization_type
                GROUP BY cth.civilization_type, dtc.trade_diplomacy_correlation
            )
        ),
        
        'critical_import_dependencies', JSON_BUILD_OBJECT(
            'resource_dependency', (
                SELECT JSON_AGG(
                    JSON_BUILD_OBJECT(
                        'material_type', frd.material_type,
                        'dependency_score', frd.dependency_score,
                        'total_imported', frd.total_imported,
                        'import_diversity', frd.caravans_importing,
                        'resource_ids', (
                            SELECT JSON_AGG(DISTINCT r.resource_id)
                            FROM resources r
                            WHERE r.type = frd.material_type
                        )
                    )
                )
                FROM fortress_resource_dependency frd
                ORDER BY frd.dependency_score DESC
                LIMIT 5
            )
        ),
        
        'export_effectiveness', JSON_BUILD_OBJECT(
            'export_effectiveness', (
                SELECT JSON_AGG(
                    JSON_BUILD_OBJECT(
                        'workshop_type', wee.workshop_type,
                        'product_type', wee.product_type,
                        'export_ratio', ROUND((wee.products_exported::DECIMAL / NULLIF(wee.products_created, 0)) * 100, 1),
                        'avg_markup', ROUND(wee.avg_export_markup, 2),
                        'workshop_ids', (
                            SELECT JSON_AGG(w.workshop_id)
                            FROM workshops w
                            WHERE w.type = wee.workshop_type
                        )
                    )
                )
                FROM workshop_export_effectiveness wee
                WHERE wee.products_created > 0
            )
        ),
        
        'trade_timeline', JSON_BUILD_OBJECT(
            'trade_growth', (
                SELECT JSON_AGG(
                    JSON_BUILD_OBJECT(
                        'year', tl.year,
                        'quarter', tl.quarter,
                        'quarterly_value', tl.quarterly_trade_value,
                        'quarterly_balance', tl.export_value - tl.import_value,
                        'trade_diversity', tl.trading_civilizations
                    )
                )
                FROM trade_timeline tl
                ORDER BY tl.year, tl.quarter
            )
        ),
        
        'economic_impact', JSON_BUILD_OBJECT(
            'import_to_production_ratio', ROUND(
                (SELECT SUM(import_value) FROM civilization_trade_history) /
                NULLIF((SELECT SUM(total_production_value) FROM workshop_export_effectiveness), 0) * 100, 2
            ),
            'most_profitable_exports', (
                SELECT JSON_AGG(
                    JSON_BUILD_OBJECT(
                        'product_type', x.product_type,
                        'total_value', x.export_value
                    )
                )
                FROM (
                    SELECT product_type, SUM(export_value) AS export_value
                    FROM workshop_export_effectiveness
                    GROUP BY product_type
                    ORDER BY SUM(export_value) DESC
                    LIMIT 3
                ) x
            )
        ),
        
        'trade_recommendations', JSON_BUILD_OBJECT(
            'recommendations', (
                SELECT JSON_AGG(
                    JSON_BUILD_OBJECT(
                        'material_type', r.material_type,
                        'recommendation', CASE
                            WHEN r.dependency_score > 1000 THEN 'Develop domestic production'
                            WHEN r.dependency_score > 500 THEN 'Diversify import sources'
                            ELSE 'Maintain current strategy'
                        END
                    )
                )
                FROM fortress_resource_dependency r
                ORDER BY r.dependency_score DESC
                LIMIT 3
            )
        )
    ) AS trade_analysis_result;