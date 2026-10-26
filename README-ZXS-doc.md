# 📘 ZXS-doc — Documentación de Zero X Siento

Documentación técnica y funcional de **Zero X Siento (ZXS)**, el sistema de gestión de stock y ventas que se usa en producción en **PagoFácil Zeroxsiento** (San Nicolás de los Arroyos, Argentina).

🔗 Sistema en producción: [stock-zero-x-siento.vercel.app](https://stock-zero-x-siento.vercel.app)

---

## 📦 ¿Qué es ZXS?

Aplicación web para administrar el stock y las ventas del local, con estadísticas, control de usuarios y un módulo de seguimiento de entregas de Correo Argentino.

## ✨ Funcionalidades

- **Stock y ventas:** carga, control y consulta de productos y movimientos.
- **Dashboards de estadísticas:** gráficos con Chart.js.
- **Gestión de usuarios:** la creación de usuarios es exclusiva de administradores.
- **Seguimiento de entregas de Correo Argentino** (sub-app):
  - Login compartido con PIN
  - Canvas de firma
  - Integración con tableta Wacom mediante SigCaptX
  - Datos en Firebase / Firestore

## 🛠️ Tecnologías

| Capa | Tecnología |
|---|---|
| Frontend | HTML, CSS, JavaScript vanilla (ES Modules, sin bundlers) |
| Base de datos | Firebase / Firestore |
| Gráficos | Chart.js |
| Hardware | Wacom + SigCaptX |
| Deploy | Vercel |

## 🗂️ Estructura del código

El código fuente está modularizado dentro de `/src`. Convenciones usadas en el proyecto:

- Módulos nativos con `<script type="module">`
- Funciones expuestas con `window.nombreFuncion` para usarlas desde los `onclick` del HTML
- Firebase importado por URL de CDN (sin npm ni bundlers)
- Fechas construidas en hora local para evitar desfases por UTC en Argentina

## 📄 Contenido de esta documentación

- Descripción general y alcance del sistema
- Módulos y funcionalidades
- Roles y permisos de usuario
- Modelo de datos en Firestore
- Flujo del sistema de entregas de Correo Argentino
- Guía de instalación y despliegue

## 👤 Autor

**Valen García** — [LinkedIn](https://linkedin.com/in/valengarcia0401) · [Instagram](https://instagram.com/valengarcia0401)
