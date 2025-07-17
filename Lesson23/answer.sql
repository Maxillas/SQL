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