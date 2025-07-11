# Task 
WITH 
workshop_production AS (
  SELECT 
    w.workshop_id,
    w.name AS workshop_name,
    w.type AS workshop_type,
    COUNT(DISTINCT wc.dwarf_id) AS num_craftsdwarves,
    SUM(wp.quantity) AS total_quantity_produced,
    SUM(wp.quantity * p.value) AS total_production_value,
    COUNT(DISTINCT DATE(wp.production_date)) AS days_active
  FROM 
    WORKSHOPS w
    LEFT JOIN WORKSHOP_CRAFTSDWARVES wc ON w.workshop_id = wc.workshop_id
    LEFT JOIN WORKSHOP_PRODUCTS wp ON w.workshop_id = wp.workshop_id
    LEFT JOIN PRODUCTS p ON wp.product_id = p.product_id
  GROUP BY 
    w.workshop_id, w.name, w.type
),

workshop_materials AS (
  SELECT
    w.workshop_id,
    SUM(wm.quantity) AS total_materials_used
  FROM
    WORKSHOPS w
    LEFT JOIN WORKSHOP_MATERIALS wm ON w.workshop_id = wm.workshop_id AND wm.is_input = TRUE
  GROUP BY
    w.workshop_id
),

craftsdwarf_skills AS (
  SELECT
    w.workshop_id,
    AVG(ds.level) AS average_craftsdwarf_skill,
    CORR(ds.level, p.quality) AS skill_quality_correlation
  FROM
    WORKSHOPS w
    JOIN WORKSHOP_CRAFTSDWARVES wc ON w.workshop_id = wc.workshop_id
    JOIN DWARF_SKILLS ds ON wc.dwarf_id = ds.dwarf_id
    JOIN PRODUCTS p ON p.created_by = wc.dwarf_id
  WHERE
    ds.skill_id IN (SELECT skill_id FROM SKILLS WHERE category = 'Crafting')
  GROUP BY
    w.workshop_id
),

workshop_entities AS (
  SELECT
    w.workshop_id,
    JSON_OBJECT(
      'craftsdwarf_ids', array_agg(DISTINCT wc.dwarf_id),
      'product_ids', array_agg(DISTINCT wp.product_id),
      'material_ids', array_agg(DISTINCT wm.material_id),
      'project_ids', array_agg(DISTINCT pr.project_id)
    ) AS related_entities
  FROM
    WORKSHOPS w
    LEFT JOIN WORKSHOP_CRAFTSDWARVES wc ON w.workshop_id = wc.workshop_id
    LEFT JOIN WORKSHOP_PRODUCTS wp ON w.workshop_id = wp.workshop_id
    LEFT JOIN WORKSHOP_MATERIALS wm ON w.workshop_id = wm.workshop_id
    LEFT JOIN PROJECTS pr ON w.workshop_id = pr.workshop_id
  GROUP BY
    w.workshop_id
)

SELECT
  wp.workshop_id,
  wp.workshop_name,
  wp.workshop_type,
  wp.num_craftsdwarves,
  wp.total_quantity_produced,
  wp.total_production_value,
  
  ROUND(wp.total_quantity_produced::numeric / NULLIF(wp.days_active, 0), 2) AS daily_production_rate,
  ROUND(wp.total_production_value::numeric / NULLIF(wm.total_materials_used, 0), 2) AS value_per_material_unit,
  ROUND(wp.days_active::numeric / (EXTRACT(EPOCH FROM (NOW() - MIN(wp.production_date)) / 86400) * 100, 2) AS workshop_utilization_percent,
  
  ROUND(wp.total_quantity_produced::numeric / NULLIF(wm.total_materials_used, 0), 2) AS material_conversion_ratio,
  
  cs.average_craftsdwarf_skill,
  cs.skill_quality_correlation,
  
  we.related_entities

FROM
  workshop_production wp
  JOIN workshop_materials wm ON wp.workshop_id = wm.workshop_id
  JOIN craftsdwarf_skills cs ON wp.workshop_id = cs.workshop_id
  JOIN workshop_entities we ON wp.workshop_id = we.workshop_id

ORDER BY
  wp.workshop_id;