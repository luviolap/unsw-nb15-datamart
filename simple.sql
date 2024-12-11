-- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * --
-- 1. First, let's create the database and schema:

-- Create the database
CREATE DATABASE network_traffic_dw;

-- Connect to the new database and create schema
\c network_traffic_dw
CREATE SCHEMA dw;

-- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * --
-- 2. Create dimension and fact tables:

-- Create dimension tables first
CREATE TABLE dw.dim_time (
    time_key SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    hour INTEGER NOT NULL,
    day INTEGER NOT NULL,
    month INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    year INTEGER NOT NULL,
    is_weekend BOOLEAN NOT NULL
);

CREATE TABLE dw.dim_service (
    service_key SERIAL PRIMARY KEY,
    service_name VARCHAR(20),
    description TEXT
);

CREATE TABLE dw.dim_protocol (
    protocol_key SERIAL PRIMARY KEY,
    protocol_name VARCHAR(10) NOT NULL,
    protocol_state VARCHAR(5)
);

CREATE TABLE dw.dim_location (
    location_key SERIAL PRIMARY KEY,
    ip_address VARCHAR(15) NOT NULL,
    port INTEGER NOT NULL,
    UNIQUE(ip_address, port)
);

CREATE TABLE dw.dim_attack_category (
    category_key SERIAL PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL,
    description TEXT
);

CREATE TABLE dw.dim_attack (
    attack_key SERIAL PRIMARY KEY,
    category_key INTEGER REFERENCES dw.dim_attack_category,
    is_attack BOOLEAN NOT NULL
);

-- Create fact table

-- Drop the existing fact table if it exists (and its dependencies if necessary)
-- DROP TABLE IF EXISTS dw.fact_connections CASCADE;

CREATE TABLE dw.fact_connections (
    connection_key SERIAL PRIMARY KEY,
    time_key INTEGER REFERENCES dw.dim_time,
    src_location_key INTEGER REFERENCES dw.dim_location,
    dst_location_key INTEGER REFERENCES dw.dim_location,
    service_key INTEGER REFERENCES dw.dim_service,
    protocol_key INTEGER REFERENCES dw.dim_protocol,
    attack_key INTEGER REFERENCES dw.dim_attack,
    duration FLOAT NOT NULL,
    src_bytes BIGINT NOT NULL,
    dst_bytes BIGINT NOT NULL,
    src_packets BIGINT NOT NULL,
    dst_packets BIGINT NOT NULL,
    total_bytes BIGINT GENERATED ALWAYS AS (src_bytes + dst_bytes) STORED,
    total_packets BIGINT GENERATED ALWAYS AS (src_packets + dst_packets) STORED
);

-- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * --
-- 3. Create a staging table to load the raw data:

-- Drop the existing staging table if it exists
-- DROP TABLE IF EXISTS dw.staging_connections;

-- Create staging table with all columns nullable
CREATE TABLE dw.staging_connections (
    srcip VARCHAR(15) NULL,
    sport INTEGER NULL,
    dstip VARCHAR(15) NULL,
    dsport INTEGER NULL,
    proto VARCHAR(10) NULL,
    state VARCHAR(5) NULL,
    dur FLOAT NULL,
    sbytes BIGINT NULL,
    dbytes BIGINT NULL,
    sttl INTEGER NULL,
    dttl INTEGER NULL,
    sloss INTEGER NULL,
    dloss INTEGER NULL,
    service VARCHAR(20) NULL,
    sload FLOAT NULL,
    dload FLOAT NULL,
    spkts BIGINT NULL,
    dpkts BIGINT NULL,
    swin INTEGER NULL,
    dwin INTEGER NULL,
    stcpb BIGINT NULL,
    dtcpb BIGINT NULL,
    smeansz INTEGER NULL,
    dmeansz INTEGER NULL,
    trans_depth INTEGER NULL,
    res_bdy_len INTEGER NULL,
    sjit FLOAT NULL,
    djit FLOAT NULL,
    stime BIGINT NULL,
    ltime BIGINT NULL,
    sintpkt FLOAT NULL,
    dintpkt FLOAT NULL,
    tcprtt FLOAT NULL,
    synack FLOAT NULL,
    ackdat FLOAT NULL,
    is_sm_ips_ports INTEGER NULL,
    ct_state_ttl INTEGER NULL,
    ct_flw_http_mthd INTEGER NULL,
    is_ftp_login INTEGER NULL,
    ct_ftp_cmd INTEGER NULL,
    ct_srv_src INTEGER NULL,
    ct_srv_dst INTEGER NULL,
    ct_dst_ltm INTEGER NULL,
    ct_src_ltm INTEGER NULL,
    ct_src_dport_ltm INTEGER NULL,
    ct_dst_sport_ltm INTEGER NULL,
    ct_dst_src_ltm INTEGER NULL,
    attack_cat VARCHAR(50) NULL,
    label INTEGER NULL
);

-- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * --
-- 5. Transform and load data into dimension and fact tables:

-- Load dim_time
INSERT INTO dw.dim_time (timestamp, hour, day, month, quarter, year, is_weekend)
SELECT DISTINCT
    to_timestamp(stime) as timestamp,
    EXTRACT(HOUR FROM to_timestamp(stime)) as hour,
    EXTRACT(DAY FROM to_timestamp(stime)) as day,
    EXTRACT(MONTH FROM to_timestamp(stime)) as month,
    EXTRACT(QUARTER FROM to_timestamp(stime)) as quarter,
    EXTRACT(YEAR FROM to_timestamp(stime)) as year,
    EXTRACT(ISODOW FROM to_timestamp(stime)) IN (6,7) as is_weekend
FROM dw.staging_connections;

-- Load dim_service
INSERT INTO dw.dim_service (service_name)
SELECT DISTINCT service FROM dw.staging_connections
WHERE service IS NOT NULL;

-- Load dim_protocol
INSERT INTO dw.dim_protocol (protocol_name, protocol_state)
SELECT DISTINCT proto, state FROM dw.staging_connections
WHERE proto IS NOT NULL;

-- Load dim_location
INSERT INTO dw.dim_location (ip_address, port)
SELECT DISTINCT srcip, sport FROM dw.staging_connections
UNION
SELECT DISTINCT dstip, dsport FROM dw.staging_connections;

-- Load dim_attack_category
INSERT INTO dw.dim_attack_category (category_name)
SELECT DISTINCT attack_cat FROM dw.staging_connections
WHERE attack_cat IS NOT NULL;

-- Load dim_attack
INSERT INTO dw.dim_attack (category_key, is_attack)
SELECT 
    ac.category_key,
    s.label = 1 as is_attack
FROM dw.staging_connections s
LEFT JOIN dw.dim_attack_category ac ON s.attack_cat = ac.category_name;

-- Load fact_connections
INSERT INTO dw.fact_connections (
    time_key, src_location_key, dst_location_key, 
    service_key, protocol_key, attack_key,
    duration, src_bytes, dst_bytes, src_packets, dst_packets
)
SELECT
    t.time_key,
    sl.location_key as src_location_key,
    dl.location_key as dst_location_key,
    s.service_key,
    p.protocol_key,
    a.attack_key,
    stg.dur,
    stg.sbytes,
    stg.dbytes,
    stg.spkts,
    stg.dpkts
FROM dw.staging_connections stg
JOIN dw.dim_time t ON to_timestamp(stg.stime) = t.timestamp
JOIN dw.dim_location sl ON stg.srcip = sl.ip_address AND stg.sport = sl.port
JOIN dw.dim_location dl ON stg.dstip = dl.ip_address AND stg.dsport = dl.port
LEFT JOIN dw.dim_service s ON stg.service = s.service_name
JOIN dw.dim_protocol p ON stg.proto = p.protocol_name AND stg.state = p.protocol_state
JOIN dw.dim_attack a ON stg.label = CASE WHEN a.is_attack THEN 1 ELSE 0 END;

-- 6. Create indices for better query performance:

CREATE INDEX idx_fact_time ON dw.fact_connections(time_key);
CREATE INDEX idx_fact_service ON dw.fact_connections(service_key);
CREATE INDEX idx_fact_attack ON dw.fact_connections(attack_key);
CREATE INDEX idx_fact_service_attack ON dw.fact_connections(service_key, attack_key);

-- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * --
-- 7. Additional performance:

-- Add materialized views for common aggregations:
CREATE MATERIALIZED VIEW mv_hourly_service_stats AS
SELECT 
    s.service_key,
    t.hour,
    a.is_attack,
    COUNT(*) as connection_count,
    SUM(fc.src_bytes + fc.dst_bytes) as total_bytes,
    AVG(fc.duration) as avg_duration
FROM fact_connections fc
JOIN dim_service s ON fc.service_key = s.service_key
JOIN dim_attack a ON fc.attack_key = a.attack_key
JOIN dim_time t ON fc.time_key = t.time_key
GROUP BY s.service_key, t.hour, a.is_attack;

-- Add additional indices for common query patterns:
CREATE INDEX idx_fact_service_attack ON fact_connections(service_key, attack_key);
CREATE INDEX idx_fact_time_components ON fact_connections(time_key) INCLUDE (service_key, attack_key);
CREATE INDEX idx_location_port ON dim_location(port);

-- Add partitioning for better query performance:

-- Partition fact table by month
ALTER TABLE fact_connections 
    PARTITION BY RANGE (time_key);

-- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * ---- * --
-- 8. Queries

-- A. ANÁLISIS DE SERVICIOS
-- A1. Ranking de servicios por número total de conexiones
SELECT 
    s.service_name,
    COUNT(*) as total_connections
FROM fact_connections fc
JOIN dim_service s ON fc.service_key = s.service_key
GROUP BY s.service_name
ORDER BY total_connections DESC;

-- A2. Por servicio: conexiones atacadas y categorías distintas de ataque
SELECT 
    s.service_name,
    COUNT(*) as attack_connections,
    COUNT(DISTINCT a.attack_category) as attack_categories
FROM fact_connections fc
JOIN dim_service s ON fc.service_key = s.service_key
JOIN dim_attack a ON fc.attack_key = a.attack_key
WHERE a.is_attack = true
GROUP BY s.service_name;

-- A3. Porcentaje de conexiones maliciosas vs normales para servicios con más de 1000 conexiones
WITH service_counts AS (
    SELECT 
        s.service_name,
        COUNT(*) as total_connections,
        SUM(CASE WHEN a.is_attack THEN 1 ELSE 0 END) as attack_connections
    FROM fact_connections fc
    JOIN dim_service s ON fc.service_key = s.service_key
    JOIN dim_attack a ON fc.attack_key = a.attack_key
    GROUP BY s.service_name
    HAVING COUNT(*) > 1000
)
SELECT 
    service_name,
    total_connections,
    ROUND(attack_connections * 100.0 / total_connections, 2) as attack_percentage,
    ROUND((total_connections - attack_connections) * 100.0 / total_connections, 2) as normal_percentage
FROM service_counts;

-- A4. Total de ataques por servicio agrupados por hora/día/mes
SELECT 
    s.service_name,
    t.hour,
    t.day,
    t.month,
    COUNT(*) as total_attacks
FROM fact_connections fc
JOIN dim_service s ON fc.service_key = s.service_key
JOIN dim_attack a ON fc.attack_key = a.attack_key
JOIN dim_time t ON fc.time_key = t.time_key
WHERE a.is_attack = true
GROUP BY GROUPING SETS (
    (s.service_name, t.hour),
    (s.service_name, t.day),
    (s.service_name, t.month)
);

-- B. ANÁLISIS DE TRÁFICO NORMAL
-- B1. Para conexiones normales, calcular totales por servicio
SELECT 
    s.service_name,
    SUM(fc.src_bytes) as total_src_bytes,
    SUM(fc.dst_bytes) as total_dst_bytes,
    SUM(fc.src_packets) as total_src_packets,
    SUM(fc.dst_packets) as total_dst_packets
FROM fact_connections fc
JOIN dim_service s ON fc.service_key = s.service_key
JOIN dim_attack a ON fc.attack_key = a.attack_key
WHERE a.is_attack = false
GROUP BY s.service_name;

-- B2. Duración promedio de conexiones normales por servicio
SELECT 
    s.service_name,
    AVG(fc.duration) as avg_duration
FROM fact_connections fc
JOIN dim_service s ON fc.service_key = s.service_key
JOIN dim_attack a ON fc.attack_key = a.attack_key
WHERE a.is_attack = false
GROUP BY s.service_name;

-- B3. Top 5 puertos destino más frecuentes por servicio en tráfico normal
WITH ranked_ports AS (
    SELECT 
        s.service_name,
        dl.port as dst_port,
        COUNT(*) as connection_count,
        RANK() OVER (PARTITION BY s.service_name ORDER BY COUNT(*) DESC) as rank
    FROM fact_connections fc
    JOIN dim_service s ON fc.service_key = s.service_key
    JOIN dim_location dl ON fc.dst_location_key = dl.location_key
    JOIN dim_attack a ON fc.attack_key = a.attack_key
    WHERE a.is_attack = false
    GROUP BY s.service_name, dl.port
)
SELECT * FROM ranked_ports WHERE rank <= 5;

-- B4. Conexiones normales agrupadas por hora/día/mes
SELECT 
    s.service_name,
    t.hour,
    t.day,
    t.month,
    COUNT(*) as normal_connections
FROM fact_connections fc
JOIN dim_service s ON fc.service_key = s.service_key
JOIN dim_attack a ON fc.attack_key = a.attack_key
JOIN dim_time t ON fc.time_key = t.time_key
WHERE a.is_attack = false
GROUP BY GROUPING SETS (
    (s.service_name, t.hour),
    (s.service_name, t.day),
    (s.service_name, t.month)
);

-- C. ANÁLISIS DE TRÁFICO MALICIOSO
-- C1. Por servicio y categoría de ataque, calcular total de bytes transferidos
SELECT 
    s.service_name,
    ac.category_name,
    SUM(fc.src_bytes + fc.dst_bytes) as total_bytes
FROM fact_connections fc
JOIN dim_service s ON fc.service_key = s.service_key
JOIN dim_attack a ON fc.attack_key = a.attack_key
JOIN dim_attack_category ac ON a.category_key = ac.category_key
WHERE a.is_attack = true
GROUP BY s.service_name, ac.category_name;

-- C2. Por tipo de ataque y servicio: estadísticas de duración
SELECT 
    s.service_name,
    ac.category_name,
    MIN(fc.duration) as min_duration,
    AVG(fc.duration) as avg_duration,
    MAX(fc.duration) as max_duration
FROM fact_connections fc
JOIN dim_service s ON fc.service_key = s.service_key
JOIN dim_attack a ON fc.attack_key = a.attack_key
JOIN dim_attack_category ac ON a.category_key = ac.category_key
WHERE a.is_attack = true
GROUP BY s.service_name, ac.category_name;

-- C3. Puertos destino más utilizados por categoría de ataque
WITH port_usage AS (
    SELECT 
        ac.category_name,
        dl.port as dst_port,
        COUNT(*) as usage_count,
        RANK() OVER (PARTITION BY ac.category_name ORDER BY COUNT(*) DESC) as rank
    FROM fact_connections fc
    JOIN dim_attack a ON fc.attack_key = a.attack_key
    JOIN dim_attack_category ac ON a.category_key = ac.category_key
    JOIN dim_location dl ON fc.dst_location_key = dl.location_key
    WHERE a.is_attack = true
    GROUP BY ac.category_name, dl.port
)
SELECT * FROM port_usage WHERE rank <= 10;

-- C4. Análisis temporal de ataques por tipo y servicio
SELECT 
    s.service_name,
    ac.category_name,
    t.hour,
    COUNT(*) as attacks_per_hour,
    t.day,
    COUNT(*) as attacks_per_day,
    t.month,
    COUNT(*) as attacks_per_month
FROM fact_connections fc
JOIN dim_service s ON fc.service_key = s.service_key
JOIN dim_attack a ON fc.attack_key = a.attack_key
JOIN dim_attack_category ac ON a.category_key = ac.category_key
JOIN dim_time t ON fc.time_key = t.time_key
WHERE a.is_attack = true
GROUP BY GROUPING SETS (
    (s.service_name, ac.category_name, t.hour),
    (s.service_name, ac.category_name, t.day),
    (s.service_name, ac.category_name, t.month)
);

-- D. ANÁLISIS COMPARATIVO
-- D1. Comparar promedios entre tráfico normal y malicioso por servicio
WITH traffic_stats AS (
    SELECT 
        s.service_name,
        a.is_attack,
        t.hour,
        t.day,
        t.month,
        AVG(fc.src_bytes + fc.dst_bytes) as avg_bytes,
        AVG(fc.src_packets + fc.dst_packets) as avg_packets
    FROM fact_connections fc
    JOIN dim_service s ON fc.service_key = s.service_key
    JOIN dim_attack a ON fc.attack_key = a.attack_key
    JOIN dim_time t ON fc.time_key = t.time_key
    GROUP BY GROUPING SETS (
        (s.service_name, a.is_attack, t.hour),
        (s.service_name, a.is_attack, t.day),
        (s.service_name, a.is_attack, t.month)
    )
)
SELECT 
    service_name,
    COALESCE(hour, day, month) as time_unit,
    MAX(CASE WHEN is_attack THEN avg_bytes END) as malicious_avg_bytes,
    MAX(CASE WHEN NOT is_attack THEN avg_bytes END) as normal_avg_bytes,
    MAX(CASE WHEN is_attack THEN avg_packets END) as malicious_avg_packets,
    MAX(CASE WHEN NOT is_attack THEN avg_packets END) as normal_avg_packets
FROM traffic_stats
GROUP BY service_name, COALESCE(hour, day, month)
ORDER BY service_name, time_unit;

-- D2. Comparación de duraciones promedio por servicio
SELECT 
    s.service_name,
    AVG(CASE WHEN a.is_attack THEN fc.duration END) as avg_attack_duration,
    AVG(CASE WHEN NOT a.is_attack THEN fc.duration END) as avg_normal_duration,
    AVG(CASE WHEN a.is_attack THEN fc.duration END) / 
    NULLIF(AVG(CASE WHEN NOT a.is_attack THEN fc.duration END), 0) as duration_ratio
FROM fact_connections fc
JOIN dim_service s ON fc.service_key = s.service_key
JOIN dim_attack a ON fc.attack_key = a.attack_key
GROUP BY s.service_name;

-- D3. Identificar puertos exclusivos de ataques
WITH port_usage AS (
    SELECT 
        dl.port,
        bool_and(a.is_attack) as attack_only
    FROM fact_connections fc
    JOIN dim_location dl ON fc.dst_location_key = dl.location_key
    JOIN dim_attack a ON fc.attack_key = a.attack_key
    GROUP BY dl.port
    HAVING COUNT(*) > 1  -- Filtering out single-use ports
)
SELECT port 
FROM port_usage 
WHERE attack_only;

-- D4. Resumen de los 5 servicios más atacados
WITH service_stats AS (
    SELECT 
        s.service_name,
        COUNT(*) as total_connections,
        SUM(CASE WHEN a.is_attack THEN 1 ELSE 0 END) as attack_count,
        AVG(fc.duration) as avg_duration,
        array_agg(DISTINCT dl.port) as common_ports,
        COUNT(DISTINCT t.hour) as active_hours,
        COUNT(DISTINCT t.day) as active_days,
        COUNT(DISTINCT t.month) as active_months
    FROM fact_connections fc
    JOIN dim_service s ON fc.service_key = s.service_key
    JOIN dim_attack a ON fc.attack_key = a.attack_key
    JOIN dim_location dl ON fc.dst_location_key = dl.location_key
    JOIN dim_time t ON fc.time_key = t.time_key
    GROUP BY s.service_name
)
SELECT *,
    (attack_count::float / total_connections * 100) as attack_percentage
FROM service_stats
ORDER BY attack_count DESC
LIMIT 5;