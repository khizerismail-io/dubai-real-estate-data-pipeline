{% macro classify_price_tier(amount_col) %}
    case 
        when {{ amount_col }} < 1000000 then 'Budget (<1M AED)'
        when {{ amount_col }} between 1000000 and 3000000 then 'Mid-Market (1M-3M AED)'
        when {{ amount_col }} between 3000000 and 10000000 then 'Prime (3M-10M AED)'
        else 'Ultra-Luxury (>10M AED)'
    end
{% endmacro %}