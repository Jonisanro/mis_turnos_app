# Changelog — Mis Turnos App

Registro de cambios, decisiones técnicas y su impacto en los flujos de la aplicación.

---

## [0.2.1] — 2026-05-30

### 📅 Vista de 3 días en mobile

#### Qué había antes
- En mobile, la vista semanal del `SfCalendar` repartía 7 columnas en ~460px → ~65px por día. Los turnos quedaban prácticamente ilegibles (solo se alcanzaba a leer "S..." de "Soledad")

#### Qué se hizo
- **Nueva abstracción `AppCalendarView { day, threeDays, week }`** sobre el `CalendarView` de Syncfusion: diferencia "3 días" (mobile) de "semana" (desktop), que comparten `CalendarView.week` pero con distinto número de días visibles
- **Helpers `_toSfView` / `_toDaysCount`**: traducen el enum propio a la API de Syncfusion
- **Vista de 3 días en mobile** vía `TimeSlotViewSettings.numberOfDaysInView: 3` → ~150px por columna, turnos legibles ("Soledad / Corte de pelo")
- **Toggle adaptativo (`_ViewToggle`)**: en mobile ofrece `Día` / `3 días` (ícono `view_column_outlined`); en desktop se mantiene `Día` / `Semana`
- La navegación con flechas avanza de a 3 días (mobile) o 7 (desktop) automáticamente, derivado de `numberOfDaysInView`

#### Decisiones tomadas
- Syncfusion **v28** no tiene una vista nativa de "3 días": se simula con `CalendarView.week` + `numberOfDaysInView: 3`
- `numberOfDaysInView` es propiedad de **`TimeSlotViewSettings`**, no del widget `SfCalendar` (la versión instalada, 28.2.11, rechaza esa propiedad en el widget raíz). Las vistas `day` y `week` usan el default `-1` (1 y 7 días naturales); solo `threeDays` fuerza 3 columnas
- Desktop mantiene la semana completa: el ancho disponible sí permite leer 7 columnas

#### Flujos afectados
- **Flujo de agenda en mobile**: el emprendedor puede leer el nombre del cliente y el servicio de cada turno sin tocarlo, en una vista de 3 días que abarca más que la diaria

---

## [0.2.0] — 2026-05-29

### Resumen ejecutivo

Sesión de trabajo completa sobre la base existente (calendaro Syncfusion + Firebase inicializado). Se tomó el proyecto desde un estado de prototipo funcional (un solo usuario, sin seguridad, colores hardcodeados) hasta un **MVP usable multi-usuario** con identidad visual definida.

---

## 🔐 Auth real y rutas protegidas

### Qué había antes
- Login funcional pero con errores que solo iban a `print()` — el usuario nunca veía por qué fallaba
- Cualquiera podía acceder a `/home` escribiendo la URL directamente, sin sesión
- No había pantalla de registro: la única forma de crear una cuenta era desde la consola de Firebase
- `emailController`, `passwordController` e `isPasswordVisible` eran **variables globales** en `login_form.dart`, compartidas entre pantallas y sin `dispose`

### Qué se hizo
- **`AuthService`** refactorizado con resultados tipados (`AuthResult`): cada operación devuelve `{User? user, String? error}` con mensajes legibles en español para cada código de error de Firebase (`user-not-found`, `wrong-password`, `email-already-in-use`, `weak-password`, etc.)
- **`authStateProvider`**: nuevo `StreamProvider<User?>` que emite el usuario actual en tiempo real; lo consumen el router y los providers de datos
- **Guard reactivo en `go_router`**: patrón `GoRouterRefreshStream` sobre `authStateChanges()`. Reglas: sin sesión → redirige a `/`; con sesión en ruta pública → redirige a `/home`. Se reevalúa automáticamente al hacer login o logout
- **Pantalla de registro** (`/register`): campos email, password y confirmar password, con validaciones en el cliente antes de llamar a Firebase
- **Refactor del formulario de login**: controllers movidos al `State`, con `dispose` correcto; errores mostrados en `SnackBar` con el mensaje real del servidor

### Decisiones tomadas
- Se eligió `GoRouterRefreshStream` (patrón `ChangeNotifier` sobre el stream de auth) en vez de un `routerProvider` que dependa del estado de Riverpod, para mantener el router como singleton estático y simplificar la configuración
- Rutas públicas declaradas explícitamente como set: `{'/','  /register'}`. Todo lo demás es protegido por defecto

### Flujos afectados
- **Flujo de entrada**: el usuario que no está logueado es redirigido a `/` desde cualquier ruta
- **Flujo de registro**: nuevo flujo completo; al crear la cuenta el stream de auth dispara el redirect a `/home` automáticamente
- **Flujo de sesión expirada**: al hacer `signOut()` el guard redirige a `/` sin necesidad de navegación manual

---

## 🔒 Aislamiento de datos por usuario

### Qué había antes
- `getAppointments()` hacía `.collection('appointment').get()` sin ningún filtro → todos los emprendedores veían los turnos de todos los demás
- El `owner` de cada turno se elegía con un **dropdown hardcodeado** ("Usuario 1", "Usuario 2")
- Sin reglas de seguridad en Firestore: cualquiera con las credenciales del proyecto podía leer y escribir toda la colección

### Qué se hizo
- **Filtro por `owner`**: `getAppointments(String ownerId)` agrega `.where('owner', isEqualTo: ownerId)`. El `ownerId` fluye desde `authStateProvider` → `appointments_provider` → usecase → repo → datasource
- **`owner = uid` al crear**: `buildAppointment()` ya no recibe `selectedUser`; el owner lo provee el provider a partir de `currentUser.uid`. Eliminado el dropdown
- **`firestore.rules`**: creado y registrado en `firebase.json`. Regla base: un documento de `appointment` o `services` solo puede ser leído, creado, editado o eliminado por el usuario cuyo `uid` coincida con el campo `owner` del documento. El filtrado en el cliente **no es seguridad**: estas reglas lo son
- **Cadena de providers**: `appointmentsProvider` observa `authStateProvider`; cuando cambia la sesión la lista se invalida y se recarga con el nuevo `uid`

### Decisiones tomadas
- **1 emprendedor = 1 cuenta**: el modelo de datos no prevé múltiples profesionales bajo una misma cuenta (queda como post-MVP). Simplifica las reglas de Firestore y el modelo `owner`
- El deploy de `firestore.rules` es un **paso manual**: `firebase deploy --only firestore:rules`. No se automatizó en este ciclo

### Flujos afectados
- **Flujo de agenda**: cada usuario ve únicamente sus propios turnos
- **Flujo de creación de turno**: `owner` se asigna automáticamente; el usuario no puede elegirlo ni modificarlo
- **Seguridad**: aunque alguien intercepte las credenciales del proyecto, las reglas de Firestore bloquean el acceso a datos ajenos a nivel de servidor

---

## 📅 CRUD completo de turnos

### Qué había antes
- Solo era posible **crear** y **ver** turnos
- No había forma de corregir un error en un turno ni de cancelarlo
- El formulario de alta era un diálogo con 4 `Expanded` en un `Row` que hacía overflow en pantallas pequeñas

### Qué se hizo
- **`editarTurno` y `eliminarTurno`** agregados a la interfaz del repositorio, su implementación y al notifier de Riverpod (`Appointments`)
- **Tap en el calendario**: `SfCalendar.onTap` detecta cuando se toca un turno existente (`CalendarElement.appointment`) y abre el diálogo en modo edición con los datos precargados
- **Diálogo unificado**: `NewAppointmentDialogWidget` recibe un `Appointment?` opcional. Si viene → modo edición (título "Editar Turno", botón "Guardar cambios" + botón "Eliminar" con confirmación). Si no → modo alta ("Agendar Turno")
- **`NewAppointmentFormController.loadFrom(Appointment)`**: método que hidrata todos los campos del formulario a partir de un turno existente
- **Diálogo responsive**: `Dialog` con `insetPadding` adaptativo (mobile: casi pantalla completa; desktop: flotante centrado), campos dentro de `SingleChildScrollView` para que el teclado no tape nada

### Decisiones tomadas
- El diálogo reutiliza el mismo widget para alta y edición, con un parámetro opcional, en vez de crear dos widgets separados. Reduce duplicación de lógica de validación y de construcción del `AppointmentModel`
- La eliminación requiere confirmación explícita (`AlertDialog`) para prevenir borrados accidentales

### Flujos afectados
- **Flujo de edición**: tap en turno → diálogo prellenado → guardar cambios → Firestore actualizado → calendario se refresca (el stream lo detecta solo)
- **Flujo de cancelación**: tap en turno → eliminar → confirmación → turno desaparece del calendario en tiempo real

---

## 🛠️ Catálogo de servicios

### Qué había antes
- El "motivo" del turno era un campo de texto libre: sin estandarización, sin precio, sin duración predefinida
- La seña era un `Checkbox` que al marcarse ponía `deposit = 100` fijo, sin posibilidad de ingresar el monto real

### Qué se hizo
**Nueva feature `lib/features/services/`** siguiendo la misma arquitectura limpia del resto del proyecto:
- `Service` (entidad) con campos: `id`, `name`, `price`, `durationMinutes`, `owner`
- `ServiceModel` (modelo de datos) con `fromMap` / `toMap` para Firestore
- `ServicesDataSource` + `ServicesRepositoryImpl`: CRUD completo en colección `services`, filtrada por `owner`
- `ServicesNotifier` (Riverpod): observa `authStateProvider`, expone `saveService` y `deleteService`
- **Pantalla `/services`**: lista con avatar de iniciales, precio y duración, edición inline, confirmación al eliminar, estado vacío ilustrado
- **Selector en el diálogo de turno**: al elegir un servicio del dropdown, se autocompleta la hora de fin sumando la duración configurada. Reemplaza el campo "Motivo" de texto libre
- **Seña como monto**: el `Checkbox` se reemplaza por un `Checkbox` + campo numérico que aparece condicionalmente; `deposit` se guarda con el valor real ingresado

### Decisiones tomadas
- Los servicios son **configurables por el emprendedor desde la app** (colección Firestore), no una lista hardcodeada. Permite que cada emprendedor tenga su propio catálogo (uñas vs. corte de cabello vs. pestañas)
- Las reglas de Firestore para `services` siguen el mismo patrón que `appointment`: solo el `owner` puede leer y escribir sus servicios

### Flujos afectados
- **Flujo de configuración**: emprendedor va a "Mis servicios" → crea/edita/elimina servicios → quedan disponibles en el selector del formulario de turno
- **Flujo de agenda**: al agendar un turno, el servicio elegido autocompleta la duración, acelerando la carga
- **Flujo financiero**: la seña se registra con el monto real, impactando el resumen del día

---

## ⚡ Agenda en tiempo real

### Qué había antes
- `getAppointments()` usaba `.get()` (una sola petición) + un botón flotante de "Refresh" manual
- Si otro dispositivo creaba un turno, el calendario no se actualizaba hasta que el usuario tocara el botón

### Qué se hizo
- `AppointmentsDataSource` agrega `watchAppointments(String ownerId)`: usa `.snapshots()` en vez de `.get()`
- `AppointmentsRepository` expone `watchTurnos(String ownerId)` que mapea el stream de modelos a entidades
- `GetAppointmentsUsecase` agrega `watch(String ownerId)`
- `appointmentsProvider` migra de `AsyncNotifier` a `StreamNotifier`: su `build()` retorna el stream directamente
- Las operaciones de mutación (create/edit/delete) ya no necesitan llamar a `reload()`: Firestore notifica el cambio y el stream actualiza la UI automáticamente
- Eliminado el botón flotante de refresh

### Decisiones tomadas
- El stream se filtra por `owner` en la misma query de Firestore (`.where('owner', isEqualTo: uid).snapshots()`), no en el cliente
- El `StreamNotifier` se reconstruye al cambiar `authStateProvider`: cuando el usuario hace logout, el stream anterior se cancela y se emite una lista vacía

### Flujos afectados
- **Flujo de agenda multi-dispositivo**: un turno creado en el celular aparece instantáneamente en la pestaña del desktop
- **Flujo post-mutación**: crear, editar o eliminar un turno actualiza el calendario sin ninguna acción adicional del usuario

---

## 🐛 Bugs críticos corregidos

### Bug 1 — Teléfono se perdía silenciosamente
**Síntoma**: el campo "Teléfono" aparecía en el formulario pero nunca se persistía en Firestore.
**Causa**: `AppointmentModel` y la entidad `Appointment` no tenían el campo `phone`. `buildAppointment()` lo ignoraba.
**Fix**: campo `phone: ''` agregado a entidad, modelo (`fromMap`/`toMap`), repo, form controller (`buildAppointment` y `loadFrom`) y `CustomAppointment`.

### Bug 2 — NPE en `AppointmentModel.fromMap`
**Síntoma**: si un documento de Firestore tenía algún campo nulo o faltante, la conversión lanzaba una `NullPointerException` que mataba el stream entero. El calendario quedaba en estado de error permanente hasta reiniciar la app.
**Causa**: accesos directos como `map['id']` sin null check — si el campo no existía en el documento, retornaba `null` y el cast a `String` fallaba.
**Fix**: todos los campos defienden con cast seguro y valor por defecto:
```dart
id: map['id'] as String? ?? '',
clientName: map['clientName'] as String? ?? 'Sin nombre',
duration: map['duration'] as int? ?? 0,
// etc.
```

### Bug 3 — Overflow del diálogo de turno en mobile
**Síntoma**: en vista `day` (mobile), el diálogo de agendar turno rompía el layout: los 4 campos en línea (Fecha / Hora inicio / Hora fin / Servicio) no entraban en pantalla.
**Fix**: 
- Diálogo usa `insetPadding` adaptativo según breakpoint
- Campos reorganizados en filas lógicas (nombre+apellido, teléfono+observaciones, fecha+horas, servicio)
- Todo el formulario dentro de `SingleChildScrollView` (el teclado ya no tapa campos)
- Switches de pago usan `Wrap` en vez de `Row` fijo

---

## 🎨 Rediseño UX/UI

### Qué había antes
- Sin `ThemeData` real: todos los colores hardcodeados en cada archivo (`Colors.pink[50]`, `Colors.blue`, `#B3E5FC`, etc.)
- Inconsistencias: botones azules en el calendario vs. negro en el login; fondo rosa en el calendario vs. blanco en el resto
- `LoginCard` y `RegisterCard` con ancho fijo de 400px → rompía en mobile
- Sin sistema de tipografía: tamaños de fuente distintos en cada widget

### Decisiones de diseño tomadas
- **Estilo**: moderno y minimalista (referencia: Calendly / Linear). Sin gradientes, mucho espacio en blanco, tipografía clara
- **Paleta**:
  - Fondo: `#FFFFFF`
  - Superficie: `#F5F5F5`
  - Primario: `#111111` (casi negro)
  - Acento: `#7C3AED` (violeta)
  - Secundario: `#6B7280` (gris medio)
  - Error: `#EF4444`
  - Éxito: `#16A34A` (turno pagado)
  - Warning: `#F59E0B` (turno con seña)
- **Plataforma**: web desktop + mobile, diseño responsive

### Qué se hizo

**`lib/core/theme/app_theme.dart`** — archivo nuevo, punto único de verdad para toda la identidad visual:
- `AppColors`: constantes de color tipadas
- `appointmentColor(hasPaid, deposit)`: función que centraliza la lógica de color de los turnos (pagado=verde, con seña=ámbar, pendiente=rojo)
- `AppTheme.light`: `ThemeData` Material 3 completo con `colorScheme`, `inputDecorationTheme`, `elevatedButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`, `appBarTheme`, `cardTheme`, `fabTheme`, `snackBarTheme`, `switchTheme`, `checkboxTheme`, `dividerTheme`

**Login / Registro**:
- `LoginCard` / `RegisterCard`: de ancho fijo 400px a `ConstrainedBox(maxWidth: 420)` adaptativo
- Gradiente azul eliminado → card blanca con sombra suave (`boxShadow`)
- Ícono de la app (calendario violeta) arriba del formulario
- `Form` con `GlobalKey` y validadores en todos los campos (email, password vacío, longitud mínima, coincidencia de contraseñas)
- `AuthTextField`: widget reutilizable entre login y registro

**Home**:
- `AppBar` sin elevación, divisor sutil de 1px entre AppBar y contenido

**`DaySummaryWidget`**:
- Reemplaza la `Card` plana con Row por 3 mini-cards independientes
- Cada card: borde izquierdo violeta de 3px, ícono en contenedor con fondo `accentLight`, valor en bold, label en gris
- Responsive: se apila en columna en pantallas < 400px

**Calendario (`SfCalendar`)**:
- `backgroundColor`: `Colors.pink[50]` → `AppColors.background` (blanco)
- `cellBorderColor`: `Colors.black` → `AppColors.border` (gris suave)
- `todayHighlightColor`: → `AppColors.accent` (violeta)
- Texto de horas en gris secundario

**`CustomAppointmentWidget`** (card de turno en el calendario):
- De bloque sólido de color → borde izquierdo de 3px + fondo tenue `color.withValues(alpha: 0.08)`
- Color de texto en el tono del estado del turno (no blanco sobre fondo oscuro)
- 3 estados visuales diferenciados: pagado (verde), con seña (ámbar), pendiente sin pago (rojo)

**`ServicesPage`**:
- `ListTile` con `CircleAvatar` de iniciales en color acento
- Confirmación al eliminar (fix de bug 🟡 pendiente)
- Estado vacío con ícono ilustrativo y texto explicativo
- `ServiceFormDialog` con `prefixIcon` en cada campo

### Flujos afectados
- **Flujo de onboarding**: la pantalla de login/registro transmite profesionalismo y es usable en mobile
- **Flujo de agenda diaria**: el resumen del día con los 3 estados de color permite identificar el estado financiero de cada turno de un vistazo
- **Flujo de consulta rápida**: los colores de turno diferenciados (verde/ámbar/rojo) permiten saber sin abrir el turno si está pagado, tiene seña, o está pendiente

---

## 🔧 Infraestructura y repo

### CI/CD — Fix de versión de Flutter
**Síntoma**: los workflows de GitHub Actions (`flutter_web_ci.yml` y `flutter_web_deploy.yml`) fallaban con `"SDK version >=3.8.0 required"`.
**Causa**: ambos workflows usaban `flutter-version: 3.29.0` (Dart 3.7.0), pero el `pubspec.yaml` requiere `sdk: '>=3.8.0 <4.0.0'` y el `.fvmrc` pina Flutter 3.35.3 localmente.
**Fix**: ambos workflows actualizados a `flutter-version: 3.35.3`, alineados con `.fvmrc`.
**Regla**: el `flutter-version` en los workflows siempre debe coincidir con el valor en `.fvmrc`.

### `.gitignore` completo
El `.gitignore` original solo excluía `.fvm/`. Se reescribió completamente para excluir:
- `.dart_tool/`: carpeta de herramientas de Flutter, incluye el perfil de Chrome que se crea al correr `flutter run -d chrome` con cookies, historial, localStorage y logs de bases de datos LevelDB. Nada de esto es código
- `build/`: output compilado (puede pesar cientos de MB)
- `.metadata`: metadatos del proyecto generados por Flutter
- `.vscode/launch.json`: configuración de debug personal
- `.flutter-plugins`, `.flutter-plugins-dependencies`: generados por `pub get`
- Keystores de Android (`*.jks`, `*.keystore`)

Se ejecutó `git rm --cached` para sacar del historial los archivos que ya estaban trackeados (especialmente todo el contenido de `.dart_tool/chrome-device/`).

**Qué NO se ignora** (y por qué):
- `pubspec.lock`: garantiza builds reproducibles en CI
- `*.g.dart`: archivos generados por Riverpod (`build_runner`) — se commitean para que al clonar el repo no sea necesario correr `build_runner` antes de lanzar la app
- `.fvmrc`: le indica a todos los desarrolladores qué versión de Flutter usar
- `firestore.rules`: son código de seguridad, deben estar en el historial

---

## 📁 Archivos nuevos creados

| Archivo | Descripción |
|---------|-------------|
| `lib/core/theme/app_theme.dart` | Sistema de diseño centralizado (colores + tema Material 3) |
| `lib/core/constants/breakpoints.dart` | Constantes de breakpoints responsive |
| `lib/features/login/presentation/pages/register_page.dart` | Pantalla de registro |
| `lib/features/login/presentation/widgets/register_form.dart` | Formulario y card de registro |
| `lib/features/home/presentation/pages/widgets/day_summary_widget.dart` | Resumen del día (3 mini-cards) |
| `lib/features/home/presentation/pages/widgets/new_appointment_form_controller.dart` | Controladores y lógica del formulario de turno |
| `lib/features/home/presentation/pages/widgets/new_appointment_validators.dart` | Validadores reutilizables del formulario |
| `lib/features/services/domain/entities/service.dart` | Entidad Service |
| `lib/features/services/data/models/service_model.dart` | Modelo de datos Firestore para Service |
| `lib/features/services/data/datasources/services_data_source.dart` | Datasource remoto de servicios |
| `lib/features/services/data/repositories/services_repository_impl.dart` | Implementación del repositorio |
| `lib/features/services/domain/repositories/services_repository.dart` | Interfaz del repositorio |
| `lib/features/services/presentation/providers/services_provider.dart` | Providers Riverpod de servicios |
| `lib/features/services/presentation/pages/services_page.dart` | Pantalla de gestión de servicios |
| `firestore.rules` | Reglas de seguridad de Firestore |
| `test/new_appointment_form_controller_test.dart` | Tests unitarios del form controller |
| `.gitignore` | Reescrito completo |
| `CHANGELOG.md` | Este archivo |

---

## 📋 Pasos manuales pendientes en Firebase

Estos cambios requieren acciones manuales en la consola de Firebase que están **fuera del código**:

1. **Habilitar Email/Password**: Firebase Console → Authentication → Sign-in method → Email/Password → Activar
2. **Desplegar reglas de Firestore**: `firebase deploy --only firestore:rules`

Sin el paso 1 no es posible registrarse ni iniciar sesión. Sin el paso 2 las reglas del archivo `firestore.rules` no tienen efecto en producción.

---

## 🚀 Estado del proyecto post-sesión

| Área | Estado |
|------|--------|
| Auth (login, registro, logout, guard de rutas) | ✅ Completo |
| Aislamiento de datos por usuario | ✅ Completo |
| Seguridad Firestore (rules) | ✅ Código listo, deploy manual pendiente |
| CRUD de turnos (crear, editar, eliminar) | ✅ Completo |
| Catálogo de servicios | ✅ Completo |
| Tiempo real (stream) | ✅ Completo |
| UX/UI — sistema de diseño | ✅ Completo |
| Tests unitarios | ✅ 4 tests (form controller) |
| CI/CD (GitHub Actions) | ✅ Fix aplicado |
| `.gitignore` | ✅ Completo |
| Booking público para clientes | 🔲 Post-MVP |
| Recordatorios WhatsApp/push | 🔲 Post-MVP |
| Reportes de ingresos | 🔲 Post-MVP |
| Multi-profesional por cuenta | 🔲 Post-MVP |
