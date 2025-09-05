# Políticas IAM para ElasticBeanstalk Web Environment

Este directorio contiene las políticas IAM personalizadas para el entorno web de Elastic Beanstalk.

## Políticas del Service Role

### service-enhanced-monitoring.json
**Rol:** Service Role  
**Propósito:** Proporciona capacidades mejoradas de monitoreo para el servicio Elastic Beanstalk
**Permisos incluidos:**
- CloudWatch: métricas, estadísticas y logs
- SNS: publicación de notificaciones 
- EventBridge: envío de eventos personalizados

## Políticas del EC2 Instance Role

### web-monitoring-access.json
- **Propósito**: Acceso a CloudWatch y logs para monitoreo de la aplicación web
- **Permisos incluidos**:
  - `cloudwatch:PutMetricData`, `cloudwatch:GetMetricStatistics` para métricas personalizadas
  - `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents` para logging
  - `s3:GetObject` en directorios específicos para assets estáticos

### `web-email-config-access.json`
- **Propósito**: Acceso a SES para envío de emails y SSM para configuración
- **Permisos incluidos**:
  - `ses:SendEmail`, `ses:SendRawEmail` para notificaciones por email
  - `ssm:GetParameter*` para obtener configuraciones desde Parameter Store

## Políticas Managed Adicionales

- **CloudWatchAgentServerPolicy**: Para agente de CloudWatch avanzado
- **AmazonSSMReadOnlyAccess**: Acceso de lectura completo a SSM Parameter Store

## Uso en el Código

```javascript
// Ejemplo de uso en la aplicación Express.js

// CloudWatch Metrics
const AWS = require('aws-sdk');
const cloudwatch = new AWS.CloudWatch();

const putMetric = async (metricName, value) => {
  await cloudwatch.putMetricData({
    Namespace: 'ExpressDemoApp/Web',
    MetricData: [{
      MetricName: metricName,
      Value: value,
      Unit: 'Count'
    }]
  }).promise();
};

// SES Email
const ses = new AWS.SES();

const sendEmail = async (to, subject, body) => {
  await ses.sendEmail({
    Source: 'noreply@express-demo-app.com',
    Destination: { ToAddresses: [to] },
    Message: {
      Subject: { Data: subject },
      Body: { Text: { Data: body } }
    }
  }).promise();
};

// SSM Parameters
const ssm = new AWS.SSM();

const getConfig = async (parameterName) => {
  const result = await ssm.getParameter({
    Name: `/express-demo-app/${parameterName}`,
    WithDecryption: true
  }).promise();
  return result.Parameter.Value;
};
```

## Casos de Uso

1. **Monitoreo**: Enviar métricas personalizadas de la aplicación
2. **Logging**: Crear logs estructurados en CloudWatch
3. **Notificaciones**: Enviar emails de confirmación, alertas, etc.
4. **Configuración**: Obtener secretos y configuraciones de SSM
5. **Assets**: Servir archivos estáticos desde S3

## Buenas Prácticas

- Usar principio de menor privilegio
- Especificar recursos ARN específicos cuando sea posible
- Rotar credenciales regularmente
- Monitorear el uso de las políticas con CloudTrail
