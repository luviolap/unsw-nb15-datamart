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