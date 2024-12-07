# Modelo Conceptual: Entidades y Atributos

## 1. Entidades de Conexión

### CONNECTION_FACT
**Descripción**: Representa cada conexión de red individual detectada en el sistema.

**Propósito**:
- Registro granular de actividad de red
- Base para análisis de seguridad
- Fuente para detección de anomalías

**Atributos Principales**:
- `connection_id`: Identificador único de la conexión
- `duration`: Duración total de la conexión
- `source_bytes`: Volumen de datos enviados
- `dest_bytes`: Volumen de datos recibidos
- `source_packets`: Cantidad de paquetes enviados
- `dest_packets`: Cantidad de paquetes recibidos
- `source_load`: Carga en origen
- `dest_load`: Carga en destino

**Métricas Derivadas**:
- Tasa de transferencia
- Ratio de pérdida de paquetes
- Indicadores de comportamiento anómalo

### HOURLY_TRAFFIC_FACT
**Descripción**: Agregación horaria del tráfico de red.

**Propósito**:
- Análisis de tendencias horarias
- Detección de patrones temporales
- Monitoreo de volumen de tráfico

**Atributos Principales**:
- `total_connections`: Conexiones en la hora
- `normal_connections`: Conexiones normales
- `attack_connections`: Conexiones maliciosas
- `avg_duration`: Duración promedio
- `total_bytes_normal`: Volumen de tráfico normal
- `total_bytes_attack`: Volumen de tráfico malicioso

### DAILY_TRAFFIC_FACT
**Descripción**: Resumen diario de actividad de red.

**Propósito**:
- Análisis de patrones diarios
- Identificación de días anómalos
- Tendencias de uso de servicios

**Atributos Principales**:
- `total_connections`: Conexiones diarias
- `attack_percentage`: Porcentaje de ataques
- `peak_hour_connections`: Hora pico
- `distinct_attack_types`: Tipos de ataques únicos

### MONTHLY_TRAFFIC_FACT
**Descripción**: Consolidación mensual de tráfico.

**Propósito**:
- Análisis de tendencias a largo plazo
- Planificación de capacidad
- Evaluación de seguridad mensual

**Atributos Principales**:
- `total_connections`: Total mensual
- `attack_percentage`: Tasa de ataques
- `peak_day_connections`: Día pico
- `distinct_attack_types`: Variedad de ataques

## 2. Entidades de Análisis Especializado

### SERVICE_STATS_FACT
**Descripción**: Estadísticas específicas por servicio.

**Propósito**:
- Análisis de comportamiento por servicio
- Identificación de servicios vulnerables
- Optimización de recursos

**Atributos Principales**:
- `total_connections`: Uso del servicio
- `attack_percentage`: Tasa de ataques
- `avg_duration`: Duración típica
- `duration_ratio`: Comparativa normal vs ataque
- `exclusive_attack_ports`: Puertos comprometidos

### PORT_USAGE_FACT
**Descripción**: Análisis detallado de uso de puertos.

**Propósito**:
- Monitoreo de puertos
- Detección de uso indebido
- Seguridad de puertos

**Atributos Principales**:
- `total_usage`: Uso total
- `attack_percentage`: Tasa de ataques
- `exclusive_to_attacks`: Indicador de compromiso
- `first_seen`: Primera detección
- `last_seen`: Última detección

## 3. Entidades Dimensionales

### TIME
**Descripción**: Dimensión temporal para análisis.

**Propósito**:
- Segmentación temporal
- Análisis de patrones temporales
- Identificación de períodos críticos

**Atributos Principales**:
- `datetime`: Momento específico
- `hour`: Hora del día
- `day_type`: Tipo de día
- `is_business_hour`: Indicador horario laboral

### SERVICE
**Descripción**: Catálogo de servicios de red.

**Propósito**:
- Clasificación de servicios
- Gestión de riesgos
- Control de acceso

**Atributos Principales**:
- `name`: Nombre del servicio
- `protocol`: Protocolo utilizado
- `service_type`: Tipo de servicio
- `risk_level`: Nivel de riesgo

### PORT
**Descripción**: Registro de puertos de red.

**Propósito**:
- Control de puertos
- Seguridad de acceso
- Monitoreo de uso

**Atributos Principales**:
- `port_number`: Número de puerto
- `range_type`: Clasificación del rango
- `default_service`: Servicio predeterminado

### STATE
**Descripción**: Estados posibles de conexión.

**Propósito**:
- Control de estados de conexión
- Análisis de ciclo de vida
- Detección de anomalías

**Atributos Principales**:
- `name`: Nombre del estado
- `category`: Categoría
- `description`: Descripción detallada

### PROTOCOL
**Descripción**: Protocolos de red soportados.

**Propósito**:
- Gestión de protocolos
- Control de comunicaciones
- Análisis de uso

**Atributos Principales**:
- `name`: Nombre del protocolo
- `type`: Tipo de protocolo
- `description`: Descripción y uso

### ATTACK
**Descripción**: Categorización de ataques.

**Propósito**:
- Clasificación de amenazas
- Análisis de seguridad
- Respuesta a incidentes

**Atributos Principales**:
- `category`: Categoría del ataque
- `severity`: Nivel de severidad
- `description`: Descripción del ataque
- `is_attack`: Indicador de ataque

# Modelo Conceptual: Relaciones y Dependencias

## 1. Relaciones de Conexión Base

### CONNECTION_FACT ↔ Dimensiones
**Relación con TIME**:
- Naturaleza: Cada conexión ocurre en un momento específico
- Cardinalidad: Una conexión tiene un tiempo exacto (N:1)
- Significado de Negocio: Permite análisis temporal de conexiones
- Uso Analítico: Patrones temporales, picos de tráfico

**Relación con SERVICE**:
- Naturaleza: Cada conexión utiliza un servicio
- Cardinalidad: Una conexión usa un servicio (N:1)
- Significado de Negocio: Identifica uso de servicios
- Uso Analítico: Análisis de uso, seguridad por servicio

**Relación con PORT (origen y destino)**:
- Naturaleza: Cada conexión tiene puertos origen y destino
- Cardinalidad: Una conexión usa dos puertos (N:1 doble)
- Significado de Negocio: Control de puntos de entrada/salida
- Uso Analítico: Seguridad de puertos, patrones de uso

**Relación con STATE**:
- Naturaleza: Cada conexión tiene un estado
- Cardinalidad: Una conexión está en un estado (N:1)
- Significado de Negocio: Control de ciclo de vida
- Uso Analítico: Análisis de estados, patrones anómalos

**Relación con PROTOCOL**:
- Naturaleza: Cada conexión usa un protocolo
- Cardinalidad: Una conexión sigue un protocolo (N:1)
- Significado de Negocio: Tipo de comunicación
- Uso Analítico: Seguridad por protocolo

**Relación con ATTACK**:
- Naturaleza: Cada conexión puede ser un ataque
- Cardinalidad: Una conexión tiene una clasificación (N:1)
- Significado de Negocio: Identificación de amenazas
- Uso Analítico: Análisis de seguridad

## 2. Relaciones de Agregaciones

### HOURLY_TRAFFIC_FACT ↔ Dimensiones
**Principales Relaciones**:
- Agregación temporal por hora
- Consolidación por servicio
- Clasificación por ataque
- Uso de protocolo

**Significado de Negocio**:
- Tendencias horarias
- Patrones de uso
- Detección de anomalías
- Monitoreo de servicios

### DAILY_TRAFFIC_FACT ↔ Dimensiones
**Principales Relaciones**:
- Resumen diario
- Uso de servicios
- Patrones de ataque
- Estadísticas de protocolo

**Significado de Negocio**:
- Análisis diario
- Tendencias de uso
- Seguridad diaria
- Optimización de recursos

### MONTHLY_TRAFFIC_FACT ↔ Dimensiones
**Principales Relaciones**:
- Consolidación mensual
- Tendencias de servicio
- Patrones de ataque
- Uso de protocolo

**Significado de Negocio**:
- Planificación a largo plazo
- Evolución de servicios
- Tendencias de seguridad
- Análisis estratégico

## 3. Relaciones de Análisis Especializado

### SERVICE_STATS_FACT ↔ Dimensiones
**Relaciones Clave**:
- Servicios específicos
- Períodos de tiempo
- Patrones de ataque
- Uso de protocolo

**Significado de Negocio**:
- Rendimiento de servicios
- Seguridad por servicio
- Optimización
- Control de calidad

### PORT_USAGE_FACT ↔ Dimensiones
**Relaciones Clave**:
- Puertos específicos
- Servicios asociados
- Patrones temporales
- Clasificación de ataques

**Significado de Negocio**:
- Seguridad de puertos
- Control de acceso
- Detección de anomalías
- Gestión de riesgos

## 4. Patrones de Análisis

### Análisis de Seguridad
**Patrones Comunes**:
- Correlación servicio-ataque
- Patrones temporales de ataques
- Uso anómalo de puertos
- Comportamiento de protocolo

**Preguntas de Negocio**:
1. ¿Qué servicios son más atacados?
2. ¿Cuándo ocurren los ataques?
3. ¿Qué puertos son más vulnerables?
4. ¿Qué protocolos son más seguros?

### Análisis de Rendimiento
**Patrones Comunes**:
- Uso de servicios
- Carga por hora
- Eficiencia de protocolos
- Utilización de puertos

**Preguntas de Negocio**:
1. ¿Cuál es el uso típico de servicios?
2. ¿Cuándo hay sobrecarga?
3. ¿Qué servicios necesitan optimización?
4. ¿Cómo se distribuye el tráfico?

### Análisis de Tendencias
**Patrones Comunes**:
- Evolución temporal
- Cambios en patrones de uso
- Tendencias de ataques
- Cambios en servicios

**Preguntas de Negocio**:
1. ¿Cómo evoluciona el uso?
2. ¿Cambian los patrones de ataque?
3. ¿Qué servicios crecen?
4. ¿Hay nuevas amenazas?

## 5. Consideraciones de Análisis

### Granularidad
- Conexión individual
- Agregación horaria
- Resumen diario
- Consolidación mensual

### Dimensionalidad
- Temporal (cuándo)
- Servicio (qué)
- Puerto (dónde)
- Protocolo (cómo)
- Ataque (por qué)

### Jerarquías
- Temporal (hora → día → mes)
- Servicio (servicio → tipo → categoría)
- Puerto (puerto → rango → tipo)
- Ataque (ataque → categoría → severidad)

## 6. Casos de Uso Principales

### Seguridad
1. Detección de intrusiones
2. Análisis de vulnerabilidades
3. Monitoreo de amenazas
4. Respuesta a incidentes

### Rendimiento
1. Optimización de servicios
2. Balanceo de carga
3. Planificación de capacidad
4. Control de calidad

### Planificación
1. Estrategia de servicios
2. Gestión de recursos
3. Política de seguridad
4. Evolución de infraestructura

