-- Network Security Data Mart - Connection Facts ETL
-- Version: 1.1
-- For UNSW-NB15 Dataset

-- Helper function to get or create time_id
CREATE OR REPLACE FUNCTION get_or_create_time_id(p_timestamp BIGINT, p_batch_id BIGINT)
RETURNS INTEGER AS $$
DECLARE
    v_time_id INTEGER;
    v_datetime TIMESTAMP;
BEGIN
    v_datetime := to_timestamp(p_timestamp);
    
    SELECT time_id INTO v_time_id
    FROM DIM_TIME
    WHERE datetime = date_trunc('hour', v_datetime);
    
    IF v_time_id IS NULL THEN
        INSERT INTO DIM_TIME (
            time_id,
            datetime,
            hour,
            day,
            month,
            year,
            day_type,
            day_name,
            month_name,
            is_business_hour,
            is_peak_hour,
            week_of_year,
            quarter,
            batch_id
        ) VALUES (
            EXTRACT(EPOCH FROM v_datetime)::INTEGER,
            date_trunc('hour', v_datetime),
            EXTRACT(HOUR FROM v_datetime),
            EXTRACT(DAY FROM v_datetime),
            EXTRACT(MONTH FROM v_datetime),
            EXTRACT(YEAR FROM v_datetime),
            CASE 
                WHEN EXTRACT(DOW FROM v_datetime) IN (0, 6) THEN 'WEEKEND'
                ELSE 'WEEKDAY'
            END,
            TO_CHAR(v_datetime, 'Day'),
            TO_CHAR(v_datetime, 'Month'),
            CASE 
                WHEN EXTRACT(HOUR FROM v_datetime) BETWEEN 9 AND 17 
                AND EXTRACT(DOW FROM v_datetime) NOT IN (0, 6) THEN TRUE
                ELSE FALSE
            END,
            CASE 
                WHEN EXTRACT(HOUR FROM v_datetime) IN (9, 10, 11, 14, 15, 16) THEN TRUE
                ELSE FALSE
            END,
            EXTRACT(WEEK FROM v_datetime),
            EXTRACT(QUARTER FROM v_datetime),
            p_batch_id
        )
        RETURNING time_id INTO v_time_id;
    END IF;
    
    RETURN v_time_id;
END;
$$ LANGUAGE plpgsql;

-- Create procedure to manage partitions
CREATE OR REPLACE PROCEDURE create_fact_partitions(
    p_start_time TIMESTAMP,
    p_end_time TIMESTAMP
) LANGUAGE plpgsql AS $$
DECLARE
    v_start_id INTEGER;
    v_end_id INTEGER;
    v_partition_name TEXT;
    v_current_start TIMESTAMP;
    v_current_end TIMESTAMP;
BEGIN
    -- Create monthly partitions
    v_current_start := date_trunc('month', p_start_time);
    WHILE v_current_start < p_end_time LOOP
        v_current_end := v_current_start + INTERVAL '1 month';
        
        -- Calculate partition bounds
        v_start_id := EXTRACT(EPOCH FROM v_current_start)::INTEGER;
        v_end_id := EXTRACT(EPOCH FROM v_current_end)::INTEGER;
        
        -- Create partition name
        v_partition_name := 'fact_connection_' || to_char(v_current_start, 'YYYY_MM');
        
        -- Create partition if it doesn't exist
        IF NOT EXISTS (
            SELECT 1
            FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE c.relname = lower(v_partition_name)
            AND n.nspname = current_schema()
        ) THEN
            EXECUTE format(
                'CREATE TABLE %I PARTITION OF fact_connection
                FOR VALUES FROM (%L) TO (%L)',
                v_partition_name, v_start_id, v_end_id
            );
            
            RAISE NOTICE 'Created partition % for range % to %',
                v_partition_name, v_current_start, v_current_end;
        END IF;
        
        v_current_start := v_current_end;
    END LOOP;
END;
$$;

-- Create procedure to manage indexes
CREATE OR REPLACE PROCEDURE manage_connection_fact_indexes(
    p_batch_id BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
    -- Drop existing batch-specific indexes if they exist
    DROP INDEX IF EXISTS idx_conn_time_range_active;
    DROP INDEX IF EXISTS idx_conn_service_metrics_active;
    DROP INDEX IF EXISTS idx_conn_attack_analysis_active;
    DROP INDEX IF EXISTS idx_conn_protocol_service_active;

    -- Create new partial indexes for the current batch
    EXECUTE format(
        'CREATE INDEX idx_conn_time_range_active ON FACT_CONNECTION (time_id, service_id) WHERE batch_id = %L',
        p_batch_id
    );

    EXECUTE format(
        'CREATE INDEX idx_conn_service_metrics_active ON FACT_CONNECTION (service_id) 
         INCLUDE (duration, source_bytes, dest_bytes) WHERE batch_id = %L',
        p_batch_id
    );

    EXECUTE format(
        'CREATE INDEX idx_conn_attack_analysis_active ON FACT_CONNECTION (attack_id, time_id)
         INCLUDE (duration, source_bytes, dest_bytes) WHERE batch_id = %L',
        p_batch_id
    );

    EXECUTE format(
        'CREATE INDEX idx_conn_protocol_service_active ON FACT_CONNECTION (protocol_id, service_id)
         INCLUDE (duration) WHERE batch_id = %L',
        p_batch_id
    );
    
    -- Create general indexes if they don't exist
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_conn_time_range') THEN
        CREATE INDEX idx_conn_time_range ON FACT_CONNECTION (time_id, service_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_conn_service_metrics') THEN
        CREATE INDEX idx_conn_service_metrics ON FACT_CONNECTION (service_id)
        INCLUDE (duration, source_bytes, dest_bytes);
    END IF;
END;
$$;

-- Create procedure to initialize fact tables
CREATE OR REPLACE PROCEDURE initialize_fact_tables(
    p_start_time TIMESTAMP,
    p_end_time TIMESTAMP
) LANGUAGE plpgsql AS $$
BEGIN
    -- Create partitions for FACT_CONNECTION
    CALL create_fact_partitions(p_start_time, p_end_time);
    
    -- Create default partition for any data outside the range
    IF NOT EXISTS (
        SELECT 1
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relname = 'fact_connection_default'
        AND n.nspname = current_schema()
    ) THEN
        CREATE TABLE fact_connection_default 
        PARTITION OF fact_connection DEFAULT;
        
        RAISE NOTICE 'Created default partition for fact_connection';
    END IF;
END;
$$;

-- Main ETL procedure for connection facts
CREATE OR REPLACE PROCEDURE etl_load_connection_facts(
    p_batch_size INTEGER DEFAULT 10000
) LANGUAGE plpgsql AS $$
DECLARE
    v_batch_id BIGINT;
    v_offset INTEGER := 0;
    v_processed INTEGER := 0;
    v_total INTEGER;
    v_error_message TEXT;
    v_start_time TIMESTAMP;
BEGIN
    -- Initialize ETL batch
    v_start_time := CURRENT_TIMESTAMP;
    
    INSERT INTO ETL_CONTROL (
        start_time,
        status,
        source_system,
        aggregation_level
    ) VALUES (
        v_start_time,
        'STARTED',
        'UNSW-NB15',
        'RAW'
    ) RETURNING batch_id INTO v_batch_id;
    
    -- Get total number of records
    SELECT COUNT(*) INTO v_total
    FROM staging.source_data;
    
    RAISE NOTICE 'Starting Connection Facts ETL. Total records: %', v_total;
    
    -- Process in batches
    WHILE v_offset < v_total LOOP
        -- Insert connection facts
        WITH batch_data AS (
            SELECT *
            FROM staging.source_data
            ORDER BY stime
            LIMIT p_batch_size
            OFFSET v_offset
        ),
        inserted_facts AS (
            INSERT INTO FACT_CONNECTION (
                time_id,
                service_id,
                source_port_id,
                dest_port_id,
                state_id,
                protocol_id,
                attack_id,
                duration,
                source_bytes,
                dest_bytes,
                source_packets,
                dest_packets,
                source_load,
                dest_load,
                source_ttl,
                dest_ttl,
                source_loss,
                dest_loss,
                ct_srv_src,
                ct_srv_dst,
                ct_state_ttl,
                batch_id
            )
            SELECT 
                get_or_create_time_id(bd.stime, v_batch_id),
                COALESCE(s.service_id, 0),
                COALESCE(sp.port_id, 0),
                COALESCE(dp.port_id, 0),
                COALESCE(st.state_id, 0),
                COALESCE(pr.protocol_id, 0),
                COALESCE(a.attack_id, 0),
                bd.dur,
                bd.sbytes,
                bd.dbytes,
                bd.spkts,
                bd.dpkts,
                bd.sload,
                bd.dload,
                bd.sttl,
                bd.dttl,
                bd.sloss,
                bd.dloss,
                bd.ct_srv_src,
                bd.ct_srv_dst,
                bd.ct_state_ttl,
                v_batch_id
            FROM batch_data bd
            LEFT JOIN DIM_SERVICE s ON bd.service = s.name AND s.is_active = TRUE
            LEFT JOIN DIM_PORT sp ON bd.sport = sp.port_number AND sp.is_active = TRUE
            LEFT JOIN DIM_PORT dp ON bd.dsport = dp.port_number AND dp.is_active = TRUE
            LEFT JOIN DIM_STATE st ON bd.state = st.name AND st.is_active = TRUE
            LEFT JOIN DIM_PROTOCOL pr ON bd.proto = pr.name AND pr.is_active = TRUE
            LEFT JOIN DIM_ATTACK a ON COALESCE(bd.attack_cat, 'NORMAL') = a.category AND a.is_active = TRUE
            RETURNING connection_id
        )
        SELECT COUNT(*) INTO v_processed
        FROM inserted_facts;
        
        -- Update progress
        v_offset := v_offset + p_batch_size;
        
        RAISE NOTICE 'Processed % of % records', LEAST(v_offset, v_total), v_total;
    END LOOP;
    
    -- Create indexes for the current batch
    CALL manage_connection_fact_indexes(v_batch_id);
    
    -- Update ETL control record
    UPDATE ETL_CONTROL 
    SET status = 'COMPLETED',
        end_time = CURRENT_TIMESTAMP,
        records_processed = v_total
    WHERE batch_id = v_batch_id;
    
    RAISE NOTICE 'Connection Facts ETL completed. Total records processed: %', v_total;
    
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
    
    -- Update ETL control record with error
    UPDATE ETL_CONTROL 
    SET status = 'FAILED',
        end_time = CURRENT_TIMESTAMP,
        error_message = v_error_message
    WHERE batch_id = v_batch_id;
    
    RAISE EXCEPTION 'Connection Facts ETL failed: %', v_error_message;
END;
$$;

-- Create procedures to validate fact loading
CREATE OR REPLACE PROCEDURE validate_connection_facts(
    p_batch_id BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
    v_validation_errors TEXT[];
BEGIN
    -- Check for orphaned foreign keys
    SELECT array_agg(error_message)
    INTO v_validation_errors
    FROM (
        -- Check time dimension references
        SELECT 'Orphaned time_id references: ' || COUNT(*) as error_message
        FROM FACT_CONNECTION f
        LEFT JOIN DIM_TIME t ON f.time_id = t.time_id
        WHERE t.time_id IS NULL AND f.batch_id = p_batch_id
        HAVING COUNT(*) > 0
        
        UNION ALL
        
        -- Check service dimension references
        SELECT 'Orphaned service_id references: ' || COUNT(*) as error_message
        FROM FACT_CONNECTION f
        LEFT JOIN DIM_SERVICE s ON f.service_id = s.service_id
        WHERE s.service_id IS NULL AND f.batch_id = p_batch_id
        HAVING COUNT(*) > 0
        
        -- Add similar checks for other dimensions...
    ) validation_checks
    WHERE error_message IS NOT NULL;
    
    -- Raise exception if there are validation errors
    IF v_validation_errors IS NOT NULL THEN
        RAISE EXCEPTION 'Fact table validation failed: %', array_to_string(v_validation_errors, E'\n');
    END IF;
    
    RAISE NOTICE 'Fact table validation completed successfully for batch %', p_batch_id;
END;
$$;

-- Create general indexes
CREATE INDEX IF NOT EXISTS idx_conn_time_range ON FACT_CONNECTION (time_id, service_id);
CREATE INDEX IF NOT EXISTS idx_conn_service_metrics ON FACT_CONNECTION (service_id)
INCLUDE (duration, source_bytes, dest_bytes);

-- Example usage:
COMMENT ON PROCEDURE etl_load_connection_facts IS 
$doc$
Load connection facts from staging data into the data mart.

Example usage:
BEGIN;
CALL etl_load_connection_facts(10000);  -- Process in batches of 10000
CALL validate_connection_facts(v_batch_id);
COMMIT;
$doc$;

BEGIN;
CALL initialize_fact_tables('2014-01-01'::timestamp, '2025-01-01'::timestamp);
CALL etl_load_connection_facts(10000);
COMMIT;

-- Check loaded records
SELECT COUNT(*) as total_records FROM FACT_CONNECTION;

-- Check distribution across partitions
SELECT 
    tableoid::regclass as partition_name,
    COUNT(*) as record_count
FROM FACT_CONNECTION
GROUP BY tableoid;

-- Check ETL control status
SELECT 
    batch_id,
    status,
    records_processed,
    start_time,
    end_time,
    error_message
FROM ETL_CONTROL
ORDER BY batch_id DESC
LIMIT 1;