# Guía de Presentación: Modelo Lógico del Data Mart

## 1. Control y Trazabilidad

### ETL_CONTROL
**¿Qué es?** El cerebro de nuestro data mart, registra y controla todos los procesos de carga de datos.

**Campos Clave**: 
- `batch_id`: Identificador único de proceso
- `status`: STARTED, RUNNING, COMPLETED, FAILED
- `aggregation_level`: RAW, HOURLY, DAILY, MONTHLY

**Relaciones**: Padre de todas las tablas del modelo para trazabilidad

## 2. Dimensiones Principales

### DIM_TIME
**¿Qué es?** Nuestra dimensión temporal que permite analizar patrones en el tiempo y tendencias de seguridad.

**Campos Clave**:
- `time_id`: Basado en epoch
- `datetime`: Timestamp exacto
- `day_type`: WEEKDAY/WEEKEND
- `is_business_hour`: Indicador horario laboral

**Relaciones**: Se conecta con todas las tablas de hechos para análisis temporal

### DIM_SERVICE
**¿Qué es?** Catálogo de servicios de red que nos permite entender qué servicios están en uso y su nivel de riesgo.

**Campos Clave**:
- `service_id`: Identificador único
- `name`: Nombre del servicio
- `risk_level`: LOW/MEDIUM/HIGH/CRITICAL

**Características**: Implementa SCD Tipo 2 para mantener historial de cambios

### DIM_PORT
**¿Qué es?** Control de puntos de entrada y salida de red, crucial para la seguridad perimetral.

**Campos Clave**:
- `port_number`: 0-65535
- `range_type`: SYSTEM/USER/DYNAMIC
- `default_service`: Servicio típicamente asociado

**Relaciones**: Doble rol en conexiones (origen/destino)

### DIM_ATTACK
**¿Qué es?** Clasificación de amenazas y ataques detectados en la red.

**Campos Clave**:
- `category`: Tipo de ataque
- `severity`: 1-5
- `is_attack`: Indicador de ataque vs tráfico normal

## 3. Hechos Principales

### FACT_CONNECTION
**¿Qué es?** El corazón del data mart, registra cada conexión individual en la red.

**Campos Clave**:
- `duration`: Duración de conexión
- `source/dest_bytes`: Volumen de datos
- `source/dest_packets`: Conteo de paquetes

**Relaciones Principales**:
- → DIM_TIME: Cuándo ocurrió
- → DIM_SERVICE: Qué servicio
- → DIM_PORT: Origen y destino
- → DIM_ATTACK: Clasificación de seguridad

**Características**: Particionado por time_id

### FACT_HOURLY_TRAFFIC
**¿Qué es?** Agregación horaria para análisis de tendencias y patrones a corto plazo.

**Campos Clave**:
- `total_connections`: Conexiones totales
- `normal/attack_connections`: Segregación de tráfico
- `avg_duration`: Duración promedio

**Características**: Base para monitoreo en tiempo real

### FACT_DAILY_TRAFFIC
**¿Qué es?** Vista diaria del tráfico para análisis de patrones y tendencias.

**Campos Relevantes**:
- Métricas diarias consolidadas
- Patrones de ataque
- Indicadores de rendimiento

### FACT_MONTHLY_TRAFFIC
**¿Qué es?** Agregación mensual para análisis de largo plazo y planificación.

**Enfoque**:
- Tendencias mensuales
- Evolución de amenazas
- Planificación de capacidad

## 4. Optimizaciones

### Particionamiento
```sql
-- Ejemplo de partición mensual
PARTITION BY RANGE (time_id);
```

### Índices Estratégicos
```sql
-- Índice para análisis de seguridad
CREATE INDEX idx_conn_security 
ON FACT_CONNECTION (time_id, service_id, attack_id);
```

### Vistas Materializadas
- **MV_HOURLY_SERVICE_PERFORMANCE**: Rendimiento de servicios
- **MV_DAILY_ATTACK_PATTERNS**: Patrones de ataque
- **MV_SERVICE_RISK_PROFILE**: Perfiles de riesgo

## 5. Ejemplos de Análisis

### Detección de Ataques
```sql
SELECT 
    s.name AS service_name,
    COUNT(*) as attack_count
FROM FACT_CONNECTION f
JOIN DIM_SERVICE s ON f.service_id = s.service_id
JOIN DIM_ATTACK a ON f.attack_id = a.attack_id
WHERE a.is_attack = true
GROUP BY s.name;
```

### Análisis de Rendimiento
```sql
SELECT 
    t.hour,
    AVG(ht.total_connections) as avg_connections
FROM FACT_HOURLY_TRAFFIC ht
JOIN DIM_TIME t ON ht.time_id = t.time_id
GROUP BY t.hour
ORDER BY avg_connections DESC;
```