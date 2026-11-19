# 🚌 TrackDIU — DIU SmartBus Fleet & Transit System

<p align="center">
  <img src="images/bus%20logo.png" alt="TrackDIU Logo" width="120" />
</p>

<p align="center">
  <b>Real-Time Campus Transit Tracking, Driver Telemetry & Fleet Management System for Daffodil International University</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Backend-Supabase%20Realtime-3ECF8E?logo=supabase&logoColor=white" alt="Supabase" />
  <img src="https://img.shields.io/badge/Maps-Google%20Maps%20SDK-4285F4?logo=googlemaps&logoColor=white" alt="Google Maps" />
  <img src="https://img.shields.io/badge/State-Riverpod%202.x-1B365D" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white" alt="Android" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License" />
</p>

---

## 📱 Application Screenshots & Output Screens

All output screenshots are sourced directly from [`lib/Output Screens/`](lib/Output%20Screens).

### 1. Onboarding & Role Authentication
<table>
  <tr>
    <td align="center" width="33%">
      <img src="lib/Output%20Screens/Splash%20Screen.jpg" width="220" alt="Splash Screen" /><br />
      <b>Splash Screen</b><br />
      <sub>Brand intro & session init</sub>
    </td>
    <td align="center" width="33%">
      <img src="lib/Output%20Screens/Role%20Selection%20while%20login.jpg" width="220" alt="Role Selection" /><br />
      <b>Role Selection</b><br />
      <sub>Student / Driver / Admin portal</sub>
    </td>
    <td align="center" width="33%">
      <img src="lib/Output%20Screens/Login%20screen.jpg" width="220" alt="Login Screen" /><br />
      <b>Authentication</b><br />
      <sub>Secure credential validation</sub>
    </td>
  </tr>
</table>

### 2. Home Dashboard & Search
<table>
  <tr>
    <td align="center" width="33%">
      <img src="lib/Output%20Screens/Home%20Screen.jpg" width="220" alt="Home Screen Light" /><br />
      <b>Home Dashboard (Light)</b><br />
      <sub>Quick actions, hero banner & weather</sub>
    </td>
    <td align="center" width="33%">
      <img src="lib/Output%20Screens/Home%20screen%20in%20dark%20mode.jpg" width="220" alt="Home Screen Dark" /><br />
      <b>Home Dashboard (Dark)</b><br />
      <sub>OLED-optimized Midnight Navy theme</sub>
    </td>
    <td align="center" width="33%">
      <img src="lib/Output%20Screens/search%20bus%20screen.jpg" width="220" alt="Search Bus" /><br />
      <b>Live Bus Search</b><br />
      <sub>Filter by route, stops & bus number</sub>
    </td>
  </tr>
</table>

### 3. Live Tracking & Radar Navigation
<table>
  <tr>
    <td align="center" width="33%">
      <img src="lib/Output%20Screens/track%20bus%20screen%20.jpg" width="220" alt="Track Bus Screen" /><br />
      <b>Active Routes List</b><br />
      <sub>Live status, speed & next stop ETA</sub>
    </td>
    <td align="center" width="33%">
      <img src="lib/Output%20Screens/track%20bus%20screen%20in%20map.jpg" width="220" alt="Track Bus in Map" /><br />
      <b>Draggable Map View</b><br />
      <sub>86% full-screen map with snap sheet</sub>
    </td>
    <td align="center" width="33%">
      <img src="lib/Output%20Screens/nearby%20bus%20screen.jpg" width="220" alt="Nearby Bus Screen" /><br />
      <b>Nearby Buses Radar</b><br />
      <sub>Dynamic 2–20 km radius filtering</sub>
    </td>
  </tr>
</table>

### 4. Transit Services, Schedule & Notices
<table>
  <tr>
    <td align="center" width="33%">
      <img src="lib/Output%20Screens/transport%20card%20screen.jpg" width="220" alt="Transport Card" /><br />
      <b>Digital Transport Card</b><br />
      <sub>Virtual smart pass & semester status</sub>
    </td>
    <td align="center" width="33%">
      <img src="lib/Output%20Screens/schedule%20screen.jpg" width="220" alt="Schedule Screen" /><br />
      <b>Bus Schedules</b><br />
      <sub>Corridor departure & arrival timetable</sub>
    </td>
    <td align="center" width="33%">
      <img src="lib/Output%20Screens/notice%20screen.jpg" width="220" alt="Notice Screen" /><br />
      <b>Broadcast Notices</b><br />
      <sub>Live transport alerts & dispatch news</sub>
    </td>
  </tr>
</table>

### 5. Fleet Command & Driver Operations
<table>
  <tr>
    <td align="center" width="50%">
      <img src="lib/Output%20Screens/drive%20location%20share%20screen.jpg" width="220" alt="Driver Screen" /><br />
      <b>Driver Live GPS Sharing</b><br />
      <sub>Active/Idle switch & telemetry broadcast</sub>
    </td>
    <td align="center" width="50%">
      <img src="lib/Output%20Screens/admin%20panel.jpg" width="220" alt="Admin Panel" /><br />
      <b>Admin Command Panel</b><br />
      <sub>Fleet health, bus management & review queue</sub>
    </td>
  </tr>
</table>

---

## ⚡ Implemented Features Table

| # | Feature Category | Feature Name | Description | Target Role | Status |
|:---:|:---|:---|:---|:---:|:---:|
| 1 | **Authentication** | Multi-Role Access Control | Dedicated login & sign-up flows for Students, Drivers, and Transport Admins with Supabase Auth metadata. | All Roles | `Completed` |
| 2 | **Live Navigation** | Real-Time GPS Tracking | High-precision bus coordinate broadcasting via Supabase Realtime channel at adaptive intervals. | Student, Driver | `Completed` |
| 3 | **Map UI** | Draggable Sheet & Full Map | Google Maps integration with a snap-enabled `DraggableScrollableSheet` (14% collapsed to 85% full route sheet). | Student | `Completed` |
| 4 | **Transit Radar** | Nearby Buses by Radius | Geolocator-driven distance calculation with customizable radius chips (2 km, 5 km, 10 km, 20 km) & custom input. | Student | `Completed` |
| 5 | **Fleet Operations** | Driver Location Broadcasting | Driver shift toggle that automatically syncs active/idle status in the database and streams GPS telemetry. | Driver | `Completed` |
| 6 | **Fleet Command** | Admin Bus & Route Manager | Add new buses, toggle fleet status, edit routes, decommission buses with confirmation dialogs, and pair drivers. | Admin | `Completed` |
| 7 | **Dispatch Desk** | Request Approval System | Driver bus assignment requests reviewed and approved by administrators with automatic state refresh. | Admin, Driver | `Completed` |
| 8 | **Campus Card** | Digital Smart Pass | Digital transport pass showing student ID, semester validity, card QR/barcode, and application workflow. | Student | `Completed` |
| 9 | **Schedules** | Corridor Timetables | Departure & arrival schedules for Mirpur, Uttara, Dhanmondi, Motijheel, and Gazipur transit routes. | Student | `Completed` |
| 10 | **Broadcasts** | Live Notification Inbox | Real-time push broadcast updates for route changes, holiday schedules, and emergency dispatch alerts. | All Roles | `Completed` |
| 11 | **Smart Assistant** | Campus AI Chatbot | Intelligent transit chatbot powered by OpenRouter API with fallbacks to local DIU transit rules. | Student | `Completed` |
| 12 | **Distribution** | In-App Update Engine | Direct APK update checker querying Supabase `app_versions`, featuring a modern release-notes modal & download manager. | All Roles | `Completed` |
| 13 | **Theming** | Dynamic Dark/Light Mode | High-contrast DIU Dark Navy (`#0A1F44`) and slate dark themes persisted locally with Hive. | All Roles | `Completed` |
| 14 | **Resilience** | Professional Error Handler | Centralized `AppErrorHandler` that catches database, network, and auth exceptions into clear user feedback. | All Roles | `Completed` |

---

## 🔄 System Architecture & Workflow

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                TrackDIU WORKFLOW OVERVIEW                              │
└────────────────────────────────────────────────────────────────────────────────────────┘

    [ STUDENT WORKFLOW ]
         │
         ├──► 1. Launch App (Splash ➔ Auto-session restore or Role Login)
         ├──► 2. Home Dashboard ➔ View Active Buses, Corridor Status & Weather
         ├──► 3. Live Tracking ➔ Tap any bus to open Google Map with Draggable Route Sheet
         ├──► 4. Radar Search ➔ Set radius (2–20 km) to find nearest approaching buses
         ├──► 5. Digital Services ➔ View Transport Card, Timetable & Dispatch Notices
         └──► 6. Self Update ➔ Auto-notified on new APK releases with changelog popup

    [ DRIVER WORKFLOW ]
         │
         ├──► 1. Authenticate as Driver ➔ Request bus assignment from Admin
         ├──► 2. Once Approved ➔ Select Assigned Bus Corridor
         ├──► 3. Tap "Start Sharing Location" ➔ Status switches from IDLE to ACTIVE
         ├──► 4. Background GPS Broadcasts telemetry (lat, lng, speed, bearing) to Supabase
         └──► 5. Complete Shift ➔ Tap "Stop Sharing" ➔ Bus automatically marked IDLE

    [ ADMIN WORKFLOW ]
         │
         ├──► 1. Authenticate as Admin ➔ Access "Admin Panel"
         ├──► 2. Live Fleet KPI Ribbon ➔ Monitor total buses, active count, pending requests
         ├──► 3. Fleet Maintenance ➔ Add bus, edit corridors, or delete obsolete buses
         ├──► 4. Driver Verification ➔ Approve or reject pending driver bus pairing requests
         └──► 5. Broadcasts ➔ Publish emergency transit announcements to student inboxes

    [ REAL-TIME TELEMETRY DATA FLOW ]
         │
         ▼
    ┌──────────────────────┐         Stream Lat/Lng         ┌──────────────────────┐
    │  Driver Device (GPS) │ ─────────────────────────────► │   Supabase Postgres  │
    │  Geolocator Service  │                                │   Realtime Channels  │
    └──────────────────────┘                                └──────────┬───────────┘
                                                                       │
                                                       Broadcast Event │ PostGIS Distance
                                                                       ▼
                                                            ┌──────────────────────┐
                                                            │  Student Devices     │
                                                            │  - Moving Map Pin    │
                                                            │  - Accurate ETA      │
                                                            │  - Radar Filter      │
                                                            └──────────────────────┘
```

---

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev) (Channel stable, Android SDK 21–34)
- **Language**: [Dart](https://dart.dev)
- **Backend & Realtime**: [Supabase](https://supabase.com) (PostgreSQL, Row-Level Security, Auth, Realtime Postgres Changes)
- **Maps & Geolocation**:
  - `google_maps_flutter` (Google Maps SDK)
  - `geolocator` (High accuracy location stream)
  - `flutter_polyline_points` (Route polylines)
- **State Management**: [Flutter Riverpod](https://riverpod.dev)
- **Local Persistence**: [Hive](https://pub.dev/packages/hive_flutter)
- **Design & Typography**: Google Fonts (`Plus Jakarta Sans`, `Inter`), Glassmorphism, Material 3
- **Networking & AI**: `http`, OpenRouter API (Auto LLM routing)
- **In-App Updater**: Direct download manager with `url_launcher`

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.0.0`
- Android Studio / VS Code with Flutter extension
- Google Maps API Key
- Supabase project URL & Anon Key

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/diu_smartbus.git
   cd diu_smartbus
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables**:
   Copy `.env.example` to `.env` and add your project keys:
   ```bash
   cp .env.example .env
   ```
   *(Ensure `MAPS_API_KEY=YOUR_KEY` is also set in `android/local.properties` for Google Maps)*

4. **Run the database migration**:
   Execute the schema script in [supabase_setup.sql](supabase_setup.sql) in your **Supabase SQL Editor**.

5. **Run the App**:
   ```bash
   flutter run
   ```

6. **Build Production Release APK**:
   ```bash
   flutter build apk --release
   ```

---

<p align="center">
  Developed for <b>Daffodil International University (DIU)</b> Transit & Smart Campus Initiative.
</p>
