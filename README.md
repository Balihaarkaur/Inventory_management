# Warehouse Tracking SaaS Platform

This repository houses a modern, production-grade Hardware Inventory Management system. It features a scalable Node.js/PostgreSQL backend and a beautiful, Glassmorphism-styled Flutter frontend designed to imitate top-tier SaaS dashboards like Blinkit and Linear.

## Core Features
1. **Interactive SaaS Dashboard**: Soft-shadow cards, progress steppers, and dynamic status badges.
2. **Lightning-Fast Barcode Scanner**: Optimized mobile camera detection with zero duplicate-scan latency.
3. **Dynamic Hardware Registration**: Unknown barcodes trigger an automatic registration popup dialog on the fly.
4. **Geospatial Processing**: Enforced GPS tracking with simulated map interfaces to verify physical location boundaries before assignment.
5. **Enterprise SSO Validation**: Organizational-level authentication via Microsoft Azure Active Directory, complete with domain-locking (`@yourcompany.com`).

---

## 🚀 Environment Setup for Developers

If you are cloning this repository to spin up your own instance, follow these steps to configure your Database, Microsoft Azure Auth, and Backend server.

### 1. Database Setup (Supabase / PostgreSQL)
You need a PostgreSQL database. The easiest method is to use a free cloud instance.
1. Go to [Supabase](https://supabase.com) and create a free project.
2. Go to **Project Settings > Database**.
3. Scroll down to Connection String. **Check the box for "Use connection pooling"**.
4. Copy the URL (it will look like `postgresql://postgres.[you]:[password]...`).
5. Open the root folder of this repository, create a `.env` file, and set the Database URL:
   ```env
   DATABASE_URL="your_copied_pooler_url_here"
   ```
6. Run the real schema setup script to construct the `hardware` and `movement_logs` tables along with required triggers:
   ```bash
   node setup_real_schema.js
   ```

### 2. Microsoft Authentication (Azure AD)
The platform is locked to Microsoft Organizational accounts. You must generate your own Azure Client ID.
1. Go to the [Azure Portal](https://portal.azure.com/).
2. Search for **App Registrations** and click **New registration**.
3. Name it (e.g., "Hardware Tracker SSO"). Choose your supported account types (Single Tenant or Multi-Tenant).
4. For the **Redirect URI**, select **Single-page application (SPA)** and enter `http://localhost:5173/` for local testing.
5. Once created, copy the **Application (client) ID** and the **Directory (tenant) ID**.

**Update the Backend Environment Variables:**
Add the Azure credentials to your `.env` file to enforce organizational locking:
```env
MICROSOFT_CLIENT_ID="0cde56fa-1ae9-4e58-a23f-1df78dffe979"
MICROSOFT_TENANT_ID="common"
ALLOWED_DOMAIN="blauplug.com"
ALLOWED_TEST_EMAIL="your_personal_test_email@outlook.com" # Bypass for testing
PORT=3000
```

### 3. Flutter Frontend Configuration
The frontend needs to know where your backend API lives and what your Microsoft Client ID is.

1. **API Connection (`frontend/lib/services/api_service.dart`)**:
   Point this to your local server IP (e.g., `http://192.168.1.xxx:3000/api`) or your live deployed cloud URL (e.g., `https://your-production-backend.onrender.com/api`).
   ```dart
   static const String baseUrl = 'https://your-production-backend.onrender.com/api';
   ```

2. **Auth Intercept (`frontend/lib/screens/login_screen.dart`)**:
   Update the `Config` block in the login screen so Flutter can ping your Azure App.
   ```dart
   final Config config = Config(
      tenant: 'common', 
      clientId: '0cde56fa-1ae9-4e58-a23f-1df78dffe979', 
      scope: 'openid profile email User.Read',
      redirectUri: kIsWeb ? 'http://localhost:5173/' : 'msauth://com.inventory.app/signature',
      navigatorKey: navigatorKey,
   );
   ```

---

## 💻 Running the Application

### Start the Node.js Backend
Ensure your `.env` is configured, then boot the server:
```bash
npm install
npm start
```

### Start the Flutter Frontend (Web)
Open a new terminal and run Flutter on the specific port you registered with Azure (e.g., 5173):
```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port 5173
```

### Build the Android Mobile App (APK)
To package the application for Android deployment so workers can use their phone cameras to scan warehouse barcodes:
```bash
cd frontend
flutter build apk --release
```
The compiled output will be available at:
`frontend\build\app\outputs\flutter-apk\app-release.apk`
