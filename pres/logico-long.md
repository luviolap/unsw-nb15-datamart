# Guía Detallada: Tablas y Campos del Data Mart de Seguridad

## Control ETL (ETL_CONTROL)

### Propósito
- Control centralizado de procesos ETL
- Auditoría de carga de datos
- Seguimiento de calidad de datos

### Campos
| Campo | Tipo | Origen | Propósito | Características |
|-------|------|--------|-----------|-----------------|
| batch_id | BIGSERIAL | Creado | Identificador único de proceso | - PK, Auto-incremento |
| start_time | TIMESTAMP | Creado | Inicio del proceso | - Never null |
| end_time | TIMESTAMP | Creado | Fin del proceso | - Null si proceso en curso |
| status | VARCHAR(20) | Creado | Estado del proceso | - CHECK ('STARTED', 'RUNNING', 'COMPLETED', 'FAILED') |
| records_processed | INTEGER | Creado | Conteo de registros | - Default 0 |
| aggregation_level | VARCHAR(20) | Creado | Nivel de agregación | - CHECK ('RAW', 'HOURLY', 'DAILY', 'MONTHLY') |
| error_message | TEXT | Creado | Detalle de errores | - Null si proceso exitoso |

### Características Técnicas
- Sin particionamiento
- Índice en (start_time, status)
- Retención: permanente
- Consultas frecuentes por status y fecha

### Visualización Recomendada
- Tableros de control ETL
- Gráficos de tendencia de carga
- Métricas de calidad de datos

## Dimensión Tiempo (DIM_TIME)

### Propósito
- Soporte para análisis temporal
- Clasificación de períodos
- Identificación de patrones temporales

### Campos
| Campo | Tipo | Origen | Propósito | Características |
|-------|------|--------|-----------|-----------------|
| time_id | INTEGER | Derivado de Stime | PK, referencia temporal | - Basado en epoch |
| datetime | TIMESTAMP | Derivado de Stime | Fecha/hora exacta | - Unique constraint |
| hour | INTEGER | Extraído | Hora del día | - CHECK (0-23) |
| day | INTEGER | Extraído | Día del mes | - CHECK (1-31) |
| month | INTEGER | Extraído | Mes del año | - CHECK (1-12) |
| year | INTEGER | Extraído | Año | - CHECK (≥2000) |
| day_type | VARCHAR(10) | Calculado | Tipo de día | - WEEKDAY/WEEKEND/HOLIDAY |
| is_business_hour | BOOLEAN | Calculado | Indicador horario laboral | - True: 9-17h en días laborables |
| is_peak_hour | BOOLEAN | Calculado | Indicador hora pico | - Basado en patrones de tráfico |

### Características Técnicas
- Sin particionamiento (dimensión pequeña)
- Índices en datetime y componentes temporales
- Alta cardinalidad en time_id
- Baja cardinalidad en clasificadores

### Visualización Recomendada
- Calendarios heat map
- Gráficos de distribución temporal
- Análisis de patrones por período

## Dimensión Servicio (DIM_SERVICE)

### Propósito
- Clasificación de servicios de red
- Gestión de riesgo
- Seguimiento de cambios en servicios

### Campos
| Campo | Tipo | Origen | Propósito | Características |
|-------|------|--------|-----------|-----------------|
| service_id | INTEGER | Creado | Identificador único | - PK, surrogate key |
| name | VARCHAR(100) | Dataset (service) | Nombre del servicio | - Unique por versión |
| protocol | VARCHAR(50) | Dataset (proto) | Protocolo asociado | - e.g., TCP, UDP |
| service_type | VARCHAR(50) | Creado | Clasificación de servicio | - e.g., WEB, DB, FILE |
| category | VARCHAR(50) | Creado | Categoría de servicio | - e.g., CRITICAL, SUPPORT |
| risk_level | VARCHAR(20) | Creado | Nivel de riesgo | - LOW/MEDIUM/HIGH/CRITICAL |
| is_active | BOOLEAN | Creado | Estado actual | - Default TRUE |
| valid_from | TIMESTAMP | Creado | Inicio de validez | - Never null |
| valid_to | TIMESTAMP | Creado | Fin de validez | - Null si activo |
| version | INTEGER | Creado | Versión del registro | - SCD Type 2 |

### Características Técnicas
- SCD Tipo 2 implementado
- Índices en name y risk_level
- Baja cardinalidad (~100 registros)
- Alta frecuencia de acceso

### Visualización Recomendada
- Matriz de servicios/riesgo
- Timeline de cambios
- Distribución por categoría

## Dimensión Puerto (DIM_PORT)

### Propósito
- Gestión de puertos de red
- Clasificación de uso
- Control de seguridad

### Campos
| Campo | Tipo | Origen | Propósito | Características |
|-------|------|--------|-----------|-----------------|
| port_id | INTEGER | Creado | Identificador único | - PK, surrogate key |
| port_number | INTEGER | Dataset (sport/dsport) | Número de puerto | - CHECK (0-65535) |
| range_type | VARCHAR(20) | Creado | Clasificación de rango | - SYSTEM/USER/DYNAMIC |
| default_service | VARCHAR(100) | Creado | Servicio típico | - Referencias comunes |
| is_active | BOOLEAN | Creado | Estado actual | - Default TRUE |

### Características Técnicas
- Índices en port_number
- Media cardinalidad (~65K posibles)
- Alta frecuencia de acceso

### Visualización Recomendada
- Heat map de uso de puertos
- Distribución por tipo
- Análisis de patrones anómalos

## Hechos de Conexión (FACT_CONNECTION)

### Propósito
- Registro detallado de conexiones
- Análisis de tráfico
- Detección de anomalías

### Campos
| Campo | Tipo | Origen | Propósito | Características |
|-------|------|--------|-----------|-----------------|
| connection_id | BIGSERIAL | Creado | Identificador único | - PK parte 1 |
| time_id | INTEGER | FK | Momento de conexión | - PK parte 2 |
| service_id | INTEGER | FK | Servicio usado | - Never null |
| source_port_id | INTEGER | FK | Puerto origen | - Never null |
| dest_port_id | INTEGER | FK | Puerto destino | - Never null |
| duration | NUMERIC(10,3) | Dataset (dur) | Duración conexión | - En segundos |
| source_bytes | BIGINT | Dataset (sbytes) | Bytes enviados | - CHECK (≥0) |
| dest_bytes | BIGINT | Dataset (dbytes) | Bytes recibidos | - CHECK (≥0) |
| source_packets | INTEGER | Dataset (spkts) | Paquetes enviados | - CHECK (≥0) |
| dest_packets | INTEGER | Dataset (dpkts) | Paquetes recibidos | - CHECK (≥0) |

### Características Técnicas
- Particionamiento por time_id
- Índices compuestos para análisis común
- Alta cardinalidad
- Compresión recomendada

### Visualización Recomendada
- Gráficos de flujo de red
- Análisis de volumen
- Patrones de tráfico

## Hechos Agregados (FACT_HOURLY_TRAFFIC)

### Propósito
- Análisis de tendencias
- Detección de patrones
- Optimización de consultas

### Campos
| Campo | Tipo | Origen | Propósito | Características |
|-------|------|--------|-----------|-----------------|
| hourly_traffic_id | BIGSERIAL | Creado | Identificador único | - PK |
| total_connections | INTEGER | Calculado | Conexiones totales | - Never null |
| normal_connections | INTEGER | Calculado | Conexiones normales | - Subset del total |
| attack_connections | INTEGER | Calculado | Conexiones maliciosas | - Subset del total |
| avg_duration | NUMERIC(10,3) | Calculado | Duración promedio | - En segundos |
| total_bytes_normal | BIGINT | Calculado | Volumen normal | - Sum de bytes |
| total_bytes_attack | BIGINT | Calculado | Volumen ataques | - Sum de bytes |

### Características Técnicas
- Particionamiento mensual
- Índices para análisis temporal
- Media cardinalidad
- Actualización diaria

### Visualización Recomendada
- Gráficos de tendencia
- Comparativas normal vs ataque
- Análisis de patrones horarios

## Vistas Materializadas

### MV_HOURLY_SERVICE_PERFORMANCE
- Rendimiento por servicio
- Métricas agregadas horarias
- Actualización programada

### MV_DAILY_ATTACK_PATTERNS
- Patrones de ataque
- Tendencias diarias
- Correlaciones de servicio

### MV_SERVICE_RISK_PROFILE
- Perfiles de riesgo
- Métricas acumuladas
- Indicadores clave

## Particionamiento

### Estrategia Temporal
```sql
-- Ejemplo de partición mensual
CREATE TABLE fact_connection_y2024m01 
PARTITION OF fact_connection
FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

### Mantenimiento de Particiones
- Creación automática
- Rotación programada
- Archivado de históricos

## Indexación

### Índices Principales
```sql
-- Ejemplo de índices compuestos
CREATE INDEX idx_conn_analysis ON fact_connection 
(time_id, service_id, attack_id) 
INCLUDE (duration, source_bytes, dest_bytes);
```

### Estrategia de Actualización
- Rebuild programado
- Estadísticas actualizadas
- Monitoreo de uso

## Monitoreo y Mantenimiento

### KPIs Principales
- Volumen de datos
- Tiempo de carga
- Uso de recursos
- Rendimiento de consultas

### Procedimientos de Mantenimiento
- Vacuum regular
- Actualización de estadísticas
- Rotación de logs

## Ejemplos de Uso

### Análisis de Seguridad
```sql
-- Ejemplo de detección de anomalías
SELECT 
    s.name,
    COUNT(*) as connections,
    AVG(f.duration) as avg_duration
FROM fact_connection f
JOIN dim_service s ON f.service_id = s.service_id
WHERE f.duration > (
    SELECT percentile_cont(0.95) 
    WITHIN GROUP (ORDER BY duration)
    FROM fact_connection
)
GROUP BY s.name;
```

### Reportes de Rendimiento
```sql
-- Ejemplo de análisis de carga
SELECT 
    t.hour,
    SUM(h.total_connections) as connections,
    AVG(h.avg_duration) as duration
FROM fact_hourly_traffic h
JOIN dim_time t ON h.time_id = t.time_id
GROUP BY t.hour
ORDER BY t.hour;
```

# Relaciones entre Tablas del Data Mart

## 1. Jerarquía de Control

### ETL_CONTROL → Todas las Tablas
- **Cardinalidad**: 1:N
- **Tipo**: Referencial no restrictiva
- **Campos**: `batch_id`
- **Propósito**: 
  - Trazabilidad de cargas
  - Control de versiones
  - Auditoría de datos
- **Reglas de Negocio**:
  - Cada registro está asociado a un batch_id
  - Los batch_id son secuenciales
  - Mantiene historial completo de cargas

## 2. Relaciones de Hechos Base

### FACT_CONNECTION → Dimensiones
- **Hacia DIM_TIME**
  - Cardinalidad: N:1
  - Campo: `time_id`
  - Obligatoria: Sí
  - Propósito: Ubicación temporal de conexiones
  - Reglas: Cada conexión debe tener un momento específico

- **Hacia DIM_SERVICE**
  - Cardinalidad: N:1
  - Campo: `service_id`
  - Obligatoria: Sí
  - Propósito: Identificación del servicio
  - Reglas: Servicios deben estar activos (is_active = true)

- **Hacia DIM_PORT (source)**
  - Cardinalidad: N:1
  - Campo: `source_port_id`
  - Obligatoria: Sí
  - Propósito: Puerto de origen
  - Reglas: Puertos válidos (0-65535)

- **Hacia DIM_PORT (destination)**
  - Cardinalidad: N:1
  - Campo: `dest_port_id`
  - Obligatoria: Sí
  - Propósito: Puerto de destino
  - Reglas: Puertos válidos (0-65535)

- **Hacia DIM_STATE**
  - Cardinalidad: N:1
  - Campo: `state_id`
  - Obligatoria: Sí
  - Propósito: Estado de la conexión
  - Reglas: Estados válidos según protocolo

- **Hacia DIM_PROTOCOL**
  - Cardinalidad: N:1
  - Campo: `protocol_id`
  - Obligatoria: Sí
  - Propósito: Protocolo utilizado
  - Reglas: Protocolos activos

- **Hacia DIM_ATTACK**
  - Cardinalidad: N:1
  - Campo: `attack_id`
  - Obligatoria: Sí
  - Propósito: Clasificación de ataque
  - Reglas: Incluye tráfico normal (attack_id = 0)

## 3. Relaciones de Hechos Agregados

### FACT_HOURLY_TRAFFIC → Dimensiones
- **Principales Relaciones**:
  - DIM_TIME (N:1)
  - DIM_SERVICE (N:1)
  - DIM_PROTOCOL (N:1)
  - DIM_ATTACK (N:1)
- **Características**:
  - Agregaciones por hora
  - Métricas consolidadas
  - Mantiene relaciones dimensionales

### FACT_DAILY_TRAFFIC → Dimensiones
- **Principales Relaciones**:
  - Similar a HOURLY pero a nivel diario
- **Características**:
  - Resúmenes diarios
  - Patrones de 24 horas
  - Métricas acumuladas

### FACT_MONTHLY_TRAFFIC → Dimensiones
- **Principales Relaciones**:
  - Similar a DAILY pero a nivel mensual
- **Características**:
  - Tendencias mensuales
  - Análisis de largo plazo
  - KPIs consolidados

## 4. Relaciones de Hechos Especializados

### FACT_SERVICE_STATS
- **Relaciones Principales**:
  - DIM_SERVICE (N:1)
  - DIM_TIME (N:1)
  - DIM_PROTOCOL (N:1)
  - DIM_ATTACK (N:1)
- **Características**:
  - Estadísticas por servicio
  - Métricas de rendimiento
  - Indicadores de seguridad

### FACT_PORT_USAGE
- **Relaciones Principales**:
  - DIM_PORT (N:1)
  - DIM_SERVICE (N:1)
  - DIM_PROTOCOL (N:1)
  - DIM_TIME (N:1)
  - DIM_ATTACK (N:1)
- **Características**:
  - Patrones de uso de puertos
  - Análisis de seguridad
  - Detección de anomalías

## 5. Reglas de Integridad

### Integridad Referencial
```sql
-- Ejemplo de constraint
ALTER TABLE FACT_CONNECTION
ADD CONSTRAINT fk_fact_conn_service
FOREIGN KEY (service_id)
REFERENCES DIM_SERVICE(service_id);
```

### Reglas de Negocio
1. **Temporales**:
   - No pueden existir gaps temporales
   - Fechas futuras no permitidas
   - Coherencia en agregaciones

2. **Servicios**:
   - Solo servicios activos
   - Versión vigente
   - Clasificación completa

3. **Puertos**:
   - Rangos válidos
   - Coherencia protocolo-puerto
   - Control de estados

4. **Ataques**:
   - Clasificación obligatoria
   - Coherencia severidad-tipo
   - Tracking completo

## 6. Ejemplo de Queries de Relación

### Análisis Multi-dimensional
```sql
-- Análisis de servicios y ataques
SELECT 
    s.name AS service_name,
    p.name AS protocol,
    a.category AS attack_type,
    COUNT(*) as connections
FROM FACT_CONNECTION f
JOIN DIM_SERVICE s ON f.service_id = s.service_id
JOIN DIM_PROTOCOL p ON f.protocol_id = p.protocol_id
JOIN DIM_ATTACK a ON f.attack_id = a.attack_id
GROUP BY s.name, p.name, a.category;
```

### Análisis Temporal con Agregaciones
```sql
-- Tendencias por servicio
SELECT 
    s.name,
    t.month,
    mt.total_connections,
    mt.attack_percentage
FROM FACT_MONTHLY_TRAFFIC mt
JOIN DIM_SERVICE s ON mt.service_id = s.service_id
JOIN DIM_TIME t ON mt.time_id = t.time_id
ORDER BY s.name, t.month;
```

## 7. Consideraciones de Rendimiento

### Optimización de Joins
- Índices apropiados
- Estadísticas actualizadas
- Plan de ejecución optimizado

### Particionamiento
- Alineado con relaciones
- Partition pruning efectivo
- Mantenimiento coordinado

## 8. Mantenimiento de Relaciones

### Rutinas de Verificación
```sql
-- Verificación de integridad
SELECT 
    'FACT_CONNECTION' as table_name,
    COUNT(*) as total_records,
    COUNT(*) FILTER (WHERE s.service_id IS NULL) as orphaned_services,
    COUNT(*) FILTER (WHERE p.protocol_id IS NULL) as orphaned_protocols
FROM FACT_CONNECTION f
LEFT JOIN DIM_SERVICE s ON f.service_id = s.service_id
LEFT JOIN DIM_PROTOCOL p ON f.protocol_id = p.protocol_id;
```

### Procedimientos de Limpieza
```sql
-- Limpieza de referencias huérfanas
DELETE FROM FACT_CONNECTION
WHERE service_id NOT IN (
    SELECT service_id 
    FROM DIM_SERVICE 
    WHERE is_active = true
);
```

## 9. Visualización de Relaciones

### Diagrama ERD
- Niveles de agrupación
- Cardinalidad clara
- Claves y relaciones

### Matriz de Dependencias
- Servicios vs Protocolos
- Puertos vs Servicios
- Ataques vs Servicios

## 10. Mejores Prácticas

### Diseño
- Normalización apropiada
- Jerarquías claras
- Documentación completa

### Implementación
- Constraints declarativos
- Índices de soporte
- Monitoreo de rendimiento

### Mantenimiento
- Validación periódica
- Limpieza proactiva
- Actualización de estadísticas