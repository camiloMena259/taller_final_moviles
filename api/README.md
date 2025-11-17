# API REST de Prueba - To-Do List

Esta carpeta contiene un servidor de prueba simple usando `json-server` para simular una API REST.

## Instalación

```bash
cd api
npm install
```

## Ejecutar el servidor

```bash
npm start
```

El servidor estará disponible en: `http://localhost:3000`

## Endpoints disponibles

- **GET** `/tasks` - Obtener todas las tareas
- **GET** `/tasks/:id` - Obtener una tarea específica
- **POST** `/tasks` - Crear una nueva tarea
- **PUT** `/tasks/:id` - Actualizar una tarea existente
- **DELETE** `/tasks/:id` - Eliminar una tarea

## Formato de datos

```json
{
  "id": "uuid-string",
  "title": "Título de la tarea",
  "completed": false,
  "updatedAt": "2025-11-17T10:30:00.000Z"
}
```

## Ejemplo de uso con curl

### Crear una tarea
```bash
curl -X POST http://localhost:3000/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "id": "1",
    "title": "Mi primera tarea",
    "completed": false,
    "updatedAt": "2025-11-17T10:30:00.000Z"
  }'
```

### Listar todas las tareas
```bash
curl http://localhost:3000/tasks
```

### Actualizar una tarea
```bash
curl -X PUT http://localhost:3000/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{
    "id": "1",
    "title": "Tarea actualizada",
    "completed": true,
    "updatedAt": "2025-11-17T11:00:00.000Z"
  }'
```

### Eliminar una tarea
```bash
curl -X DELETE http://localhost:3000/tasks/1
```

## Notas

- Los datos se guardan en `db.json`
- El servidor se reinicia automáticamente cuando detecta cambios
- Para acceder desde un dispositivo móvil en la misma red, usa la IP local de tu computadora en lugar de `localhost`
