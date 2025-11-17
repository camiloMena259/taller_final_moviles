# 📱 To-Do List - Aplicación Flutter

Aplicación móvil moderna de lista de tareas construida con Flutter, implementando arquitectura limpia, sincronización offline-first y gestión de estado con Riverpod.

## 📋 Tabla de Contenidos

- [Características](#-características)
- [Arquitectura](#-arquitectura)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Tecnologías Utilizadas](#-tecnologías-utilizadas)
- [Instalación](#-instalación)
- [Configuración del API](#-configuración-del-api)
- [Ejecución](#-ejecución)
- [Funcionalidad Offline](#-funcionalidad-offline)
- [Testing](#-testing)
- [Generación de APK](#-generación-de-apk)

## ✨ Características

- ✅ Crear, editar, marcar como completadas y eliminar tareas
- 🔍 Filtros: Todas, Pendientes, Completadas
- 📴 **Modo Offline**: Funciona completamente sin conexión
- 🔄 **Sincronización Automática**: Sincroniza datos cuando vuelve la conexión
- 🎯 **Estrategia Offline-First**: Datos locales primero, sincronización en background
- ⚡ **Backoff Exponencial**: Reintentos inteligentes con tiempos de espera progresivos
- 🔀 **Resolución de Conflictos**: Last-Write-Wins (LWW)
- 💾 Persistencia local con SQLite
- 🌐 Integración con API REST
- 🎨 Interfaz moderna y responsive
- ♻️ Pull-to-refresh
- 📊 Indicador de estado de sincronización

## 🏗️ Arquitectura

Este proyecto sigue los principios de **Clean Architecture** separando las responsabilidades en capas:

### Capas

```
┌─────────────────────────────────────────┐
│         PRESENTATION LAYER              │
│  (UI, Widgets, Providers, State)        │
├─────────────────────────────────────────┤
│          DOMAIN LAYER                   │
│     (Models, Use Cases, Entities)       │
├─────────────────────────────────────────┤
│           DATA LAYER                    │
│  (Repositories, Data Sources, API)      │
└─────────────────────────────────────────┘
```

### Componentes Principales

1. **Presentation Layer**
   - Screens (HomeScreen, TaskFormScreen)
   - Widgets (TaskListItem, SyncStatusIndicator)
   - Providers (Riverpod para gestión de estado)

2. **Domain Layer**
   - Task Model: Entidad principal de tarea
   - QueueOperation Model: Operaciones en cola para sincronización

3. **Data Layer**
   - **Local**: DatabaseHelper (SQLite)
   - **Remote**: TaskApiService (HTTP REST)
   - **Repositories**: TaskRepository (coordina local + remoto)
   - **Sync**: SyncService (sincronización con backoff exponencial)

## 📁 Estructura del Proyecto

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # Constantes de la aplicación
│   ├── errors/
│   │   └── exceptions.dart            # Excepciones personalizadas
│   └── utils/
│       ├── connectivity_utils.dart    # Utilidades de conectividad
│       └── date_utils.dart            # Utilidades de fecha
│
├── data/
│   ├── local/
│   │   └── database_helper.dart       # SQLite Database
│   ├── remote/
│   │   └── task_api_service.dart      # Cliente HTTP REST
│   └── repositories/
│       ├── task_repository.dart       # Repositorio principal (Offline-First)
│       └── sync_service.dart          # Servicio de sincronización
│
├── domain/
│   └── models/
│       ├── task.dart                  # Modelo de Tarea
│       └── queue_operation.dart       # Modelo de operación en cola
│
├── presentation/
│   ├── providers/
│   │   ├── providers.dart             # Providers base
│   │   └── task_providers.dart        # Providers de tareas y acciones
│   ├── screens/
│   │   ├── home_screen.dart           # Pantalla principal
│   │   └── task_form_screen.dart      # Formulario de tarea
│   └── widgets/
│       ├── task_list_item.dart        # Item de lista de tarea
│       └── sync_status_indicator.dart # Indicador de sincronización
│
└── main.dart                          # Punto de entrada

api/
├── db.json                            # Base de datos JSON del servidor
├── package.json                       # Configuración del servidor de prueba
└── README.md                          # Documentación del API
```

## 🛠️ Tecnologías Utilizadas

### Frontend (Flutter)

- **Flutter SDK**: 3.9.2+
- **Dart**: ^3.9.2
- **flutter_riverpod**: ^2.6.1 - Gestión de estado
- **sqflite**: ^2.4.1 - Base de datos local SQLite
- **path_provider**: ^2.1.5 - Acceso a directorios del sistema
- **http**: ^1.2.2 - Cliente HTTP
- **connectivity_plus**: ^6.1.1 - Detección de conectividad
- **uuid**: ^4.5.1 - Generación de IDs únicos
- **intl**: ^0.19.0 - Internacionalización y formato de fechas

### Backend (API de Prueba)

- **json-server**: ^0.17.4 - Servidor REST falso

## 📦 Instalación

### Prerequisitos

- Flutter SDK (>= 3.9.2)
- Dart SDK (>= 3.9.2)
- Android Studio / VS Code
- Node.js (>= 14.x) para el servidor API
- Git

### Pasos

1. **Clonar el repositorio**

```bash
git clone https://github.com/camiloMena259/taller_final_moviles.git
cd taller_final_moviles
```

2. **Instalar dependencias de Flutter**

```bash
flutter pub get
```

3. **Verificar instalación de Flutter**

```bash
flutter doctor
```

## 🌐 Configuración del API

### Opción 1: Servidor de Prueba Local (json-server)

1. **Navegar a la carpeta del API**

```bash
cd api
```

2. **Instalar dependencias**

```bash
npm install
```

3. **Iniciar el servidor**

```bash
npm start
```

El servidor estará disponible en `http://localhost:3000`

### Opción 2: Usar tu propia API

Si tienes tu propio backend, actualiza la URL base en:

```dart
// lib/core/constants/app_constants.dart
static const String baseUrl = 'https://tu-api.com';
```

### Endpoints Requeridos

- `GET /tasks` - Obtener todas las tareas
- `POST /tasks` - Crear nueva tarea
- `GET /tasks/{id}` - Obtener tarea por ID
- `PUT /tasks/{id}` - Actualizar tarea
- `DELETE /tasks/{id}` - Eliminar tarea

## 🚀 Ejecución

### En Emulador/Dispositivo

```bash
flutter run
```

### En modo Debug

```bash
flutter run --debug
```

### En modo Release

```bash
flutter run --release
```

### Para Web

```bash
flutter run -d chrome
```

## 📴 Funcionalidad Offline

### Cómo Funciona

La aplicación implementa una estrategia **Offline-First**:

1. **Operaciones Locales**: Todas las acciones se guardan primero en SQLite
2. **Cola de Sincronización**: Las operaciones se encolan para sincronizar posteriormente
3. **Sincronización Automática**: Cuando hay conexión, se sincronizan automáticamente
4. **Backoff Exponencial**: Si falla la sincronización, reintenta con tiempos progresivos

### Probar Modo Offline

#### Método 1: Modo Avión

1. Ejecuta la aplicación normalmente
2. Crea algunas tareas
3. Activa el **Modo Avión** en tu dispositivo
4. Continúa creando, editando y eliminando tareas
5. Desactiva el **Modo Avión**
6. Observa cómo las tareas se sincronizan automáticamente

#### Método 2: Detener el Servidor API

1. Detén el servidor json-server (`Ctrl+C` en la terminal del servidor)
2. Usa la aplicación normalmente
3. Reinicia el servidor
4. Las operaciones se sincronizarán automáticamente

### Indicador de Estado

La aplicación muestra un indicador en la barra superior:

- 🟢 **Nube verde**: Todo sincronizado
- 🟠 **Spinner naranja con número**: Operaciones pendientes de sincronizar
- 🔴 **Nube roja**: Error de conexión

### Resolución de Conflictos

La aplicación usa la estrategia **Last-Write-Wins (LWW)**:

- Se compara el campo `updatedAt` de la tarea local vs remota
- La tarea con la fecha más reciente prevalece
- Garantiza consistencia eventual

## 🧪 Testing

### Ejecutar Tests

```bash
flutter test
```

### Análisis de Código

```bash
flutter analyze
```

## 📦 Generación de APK

### APK de Debug

```bash
flutter build apk --debug
```

### APK de Release

```bash
flutter clean
flutter pub get
flutter build apk --release
```

El APK se generará en: `build/app/outputs/flutter-apk/app-release.apk`

### APK Split por ABI (Optimizado)

```bash
flutter build apk --split-per-abi
```

Esto genera APKs separados para cada arquitectura (arm64-v8a, armeabi-v7a, x86_64), reduciendo el tamaño.

### App Bundle (Para Google Play)

```bash
flutter build appbundle
```

## 📱 Características Implementadas

### ✅ Funcionalidades Completas

- [x] CRUD de tareas (Crear, Leer, Actualizar, Eliminar)
- [x] Persistencia local con SQLite
- [x] Integración con API REST
- [x] Modo offline funcional
- [x] Sincronización automática
- [x] Cola de operaciones pendientes
- [x] Backoff exponencial en reintentos
- [x] Resolución de conflictos (LWW)
- [x] Filtros de tareas (Todas/Pendientes/Completadas)
- [x] Pull-to-refresh
- [x] Indicador de estado de sincronización
- [x] Validación de formularios
- [x] Manejo de errores con mensajes claros
- [x] Estados de carga (loading, error, success)
- [x] Confirmación de eliminación
- [x] Swipe para eliminar
- [x] Material Design 3

## 👨‍💻 Autor

Camilo Mena - [GitHub](https://github.com/camiloMena259)

## 📄 Licencia

Este proyecto está bajo la Licencia MIT.

---

**Nota**: Este proyecto fue desarrollado como parte del taller final de desarrollo móvil, demostrando arquitectura limpia, sincronización offline-first y buenas prácticas de desarrollo Flutter.
