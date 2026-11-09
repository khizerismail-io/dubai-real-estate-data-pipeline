with bronze as (
    select * from {{ ref('bronze_projects') }}
),

deduped as (
    select
        *,
        row_number() over (
            partition by project_id 
            order by bronze_loaded_at desc
        ) as rn
    from bronze
),

silver as (
    select
        -- Identifiers
        project_id::varchar                                         as project_id,
        project_number::varchar                                     as project_number,
        developer_number::varchar                                   as developer_number,
        escrow_account_number::varchar                              as escrow_account_number,

        -- Entities & Status
        initcap(trim(project_name))                                 as project_name,
        initcap(trim(developer_name))                               as developer_name,
        upper(trim(prj_type))                                       as project_type,
        upper(trim(project_status))                                 as project_status,
        trim(description)                                           as project_description,

        -- Location Dimensions
        initcap(trim(area_name))                                    as area_name,
        initcap(trim(zone_name))                                    as zone_name,

        -- Unit & Villa Counts
        cnt_villa::integer                                          as villa_count,
        cnt_unit::integer                                           as unit_count,

        -- Timeline & Inspection Dates
        start_date::date                                            as project_start_date,
        end_date::date                                              as project_end_date,
        approval_adoption_date::date                                as approval_adoption_date,
        inspection_date::date                                       as last_inspection_date,
        datediff('month', start_date::date, end_date::date)         as planned_duration_months,

        -- Progress & Completion
        completion_percentage::number(5, 2)                         as completion_percentage,
        case 
            when completion_percentage >= 100 or upper(trim(project_status)) like '%COMPLET%' then true 
            else false 
        end                                                         as is_completed,

        case 
            when (completion_percentage < 100 and upper(trim(project_status)) not like '%COMPLET%')
             and end_date::date < current_date() then true 
            else false 
        end                                                         as is_project_delayed,

        case 
            when completion_percentage >= 100 or upper(trim(project_status)) like '%COMPLET%' then 'Completed'
            when completion_percentage >= 75 then 'Handover / Finishing (75-99%)'
            when completion_percentage >= 25 then 'Active Construction (25-74%)'
            when completion_percentage > 0 then 'Groundwork / Early Stage (1-24%)'
            else 'Planned / Not Started (0%)'
        end                                                         as project_lifecycle_stage,

        -- Financial Metrics (AED & USD)
        project_value::number(18, 2)                                as project_value_aed,
        round(project_value / 3.6725, 2)                            as project_value_usd,

        -- Scale Tiering
        case 
            when project_value < 50000000 then 'Boutique (<50M AED)'
            when project_value between 50000000 and 250000000 then 'Mid-Scale (50M-250M AED)'
            when project_value between 250000000 and 1000000000 then 'Major Development (250M-1B AED)'
            else 'Mega Project (>1B AED)'
        end                                                         as project_scale_tier

    from deduped
    where rn = 1
      and project_id is not null
)

select * 
from silver
order by project_id asc