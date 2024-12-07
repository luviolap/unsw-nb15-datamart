# Guía de Presentación: Modelo Conceptual del Data Mart

## 1. Visión General
"Este modelo representa nuestro data mart de seguridad de red, diseñado para analizar patrones de tráfico, detectar amenazas y optimizar el rendimiento de nuestra red."

## 2. Entidades Base

### CONNECTION_FACT (Conexiones)
**¿Qué es?** El registro detallado de cada comunicación en nuestra red.

**Información Clave**:
- Duración de conexiones
- Volumen de datos transferidos
- Conteo de paquetes
- Métricas de carga

**Importancia**: 
- Base para detección de anomalías
- Fuente primaria de análisis
- Granularidad máxima de datos

### TIME (Tiempo)
**¿Qué es?** Nuestra referencia temporal para todo análisis.

**Aspectos Clave**:
- Momentos exactos
- Períodos laborables
- Clasificación de días
- Horas pico

**Importancia**:
- Análisis de patrones temporales
- Identificación de períodos críticos
- Base para agregaciones

### SERVICE (Servicio)
**¿Qué es?** Catálogo de servicios de red disponibles.

**Aspectos Clave**:
- Tipos de servicio
- Niveles de riesgo
- Protocolos asociados

**Importancia**:
- Control de servicios activos
- Gestión de riesgos
- Optimización de recursos

### PORT (Puerto)
**¿Qué es?** Control de puntos de entrada y salida de red.

**Aspectos Clave**:
- Números de puerto
- Clasificación por tipo
- Servicios predeterminados

**Importancia**:
- Seguridad perimetral
- Control de acceso
- Monitoreo de uso

### ATTACK (Ataque)
**¿Qué es?** Clasificación de amenazas y actividades maliciosas.

**Aspectos Clave**:
- Categorías de ataque
- Niveles de severidad
- Indicadores de amenaza

**Importancia**:
- Identificación de amenazas
- Priorización de respuesta
- Análisis de seguridad

## 3. Agregaciones Temporales

### HOURLY_TRAFFIC (Tráfico Horario)
**¿Qué es?** Consolidación horaria del tráfico de red.

**Métricas Clave**:
- Conexiones totales y por tipo
- Promedios de duración
- Volúmenes de datos
- Patrones de ataque

**Valor de Negocio**:
- Monitoreo en tiempo real
- Detección temprana de anomalías
- Análisis de carga

### DAILY_TRAFFIC (Tráfico Diario)
**¿Qué es?** Vista consolidada del día completo.

**Métricas Clave**:
- Totales diarios
- Horas pico
- Patrones de ataque
- Uso de servicios

**Valor de Negocio**:
- Planificación diaria
- Análisis de tendencias
- Optimización de recursos

### MONTHLY_TRAFFIC (Tráfico Mensual)
**¿Qué es?** Análisis de largo plazo y tendencias.

**Métricas Clave**:
- Tendencias mensuales
- Días pico
- Evolución de ataques
- Patrones de uso

**Valor de Negocio**:
- Planificación estratégica
- Análisis de tendencias
- Presupuesto y recursos

## 4. Análisis Especializados

### SERVICE_STATS (Estadísticas de Servicio)
**¿Qué es?** Análisis profundo del comportamiento de servicios.

**Aspectos Clave**:
- Patrones de uso
- Métricas de ataque
- Indicadores de rendimiento

**Valor de Negocio**:
- Optimización de servicios
- Gestión de riesgos
- Planificación de capacidad

### PORT_USAGE (Uso de Puertos)
**¿Qué es?** Análisis detallado de la actividad en puertos.

**Aspectos Clave**:
- Patrones de uso
- Detección de anomalías
- Servicios asociados

**Valor de Negocio**:
- Seguridad perimetral
- Control de acceso
- Detección de amenazas

## 5. Relaciones Principales

### Conexiones Base
- Cada conexión ocurre en un momento específico
- Utiliza un servicio determinado
- Involucra puertos origen y destino
- Puede representar un ataque

### Agregaciones
- Heredan dimensionalidad completa
- Mantienen conexión temporal
- Preservan contexto de seguridad

## 6. Casos de Uso Principales

### Seguridad
1. "¿Qué servicios están siendo atacados?"
2. "¿Cuándo ocurren los ataques?"
3. "¿Qué puertos son más vulnerables?"

### Rendimiento
1. "¿Cómo se distribuye la carga?"
2. "¿Qué servicios necesitan optimización?"
3. "¿Cuándo ocurren los picos de tráfico?"

### Planificación
1. "¿Qué tendencias hay en el uso de servicios?"
2. "¿Cómo evoluciona el panorama de amenazas?"
3. "¿Dónde necesitamos más recursos?"

## 7. Flujos de Análisis

### Detección de Amenazas
```
Conexión → Servicio → Patrón → Ataque
```

### Análisis de Rendimiento
```
Servicio → Tráfico → Tendencias → Optimización
```

### Gestión de Riesgos
```
Puerto → Servicio → Ataques → Mitigación
```

## 8. Beneficios Clave

### Operativos
- Monitoreo en tiempo real
- Detección temprana
- Respuesta rápida

### Tácticos
- Optimización de recursos
- Mejora de seguridad
- Control de calidad

### Estratégicos
- Planificación informada
- Gestión proactiva
- Evolución de servicios