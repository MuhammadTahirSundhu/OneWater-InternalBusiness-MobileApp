# OneWater Pakistan — Internal Business App

A full-stack mobile business management system for OneWater Pakistan.  
Built with **Flutter + Riverpod** (mobile) and **FastAPI + Supabase** (backend).

---

## 🗂️ Project Structure

```
OneWaterBusinessMobileApp/
├── lib/                    # Flutter app (Dart)
├── onewater_api/           # FastAPI backend (Python)
│   ├── routers/            # API route handlers
│   ├── models/             # Pydantic data models
│   ├── services/           # Business logic (PDF, invoices)
│   ├── scheduler/          # APScheduler background jobs
│   ├── .env                # ← Your credentials go here
│   ├── .env.example        # Template for .env
│   └── requirements.txt
├── supabase/
│   └── migrations/
│       └── 001_initial_schema.sql  # Run this in Supabase SQL Editor
├── seed.py                 # Optional: populate test data
└── pubspec.yaml
```

---

## 🔑 Step 1 — Get Credentials (Supabase)

The backend uses **Supabase** as the database and file storage provider.

### 1.1 Create a Supabase Project

1. Go to **[https://supabase.com](https://supabase.com)** and sign in (free tier is enough)
2. Click **"New Project"** → fill in a name (e.g. `onewater-pakistan`) → choose a region → set a database password → click **Create**
3. Wait ~2 minutes for the project to provision

### 1.2 Get Your Keys

Once the project is ready, go to:

> **Project Settings → API**

Copy these three values:

| Key | Where to find it | Used for |
|-----|-----------------|----------|
| **Project URL** | `https://xxxx.supabase.co` | `SUPABASE_URL` |
| **anon / public key** | Under "Project API Keys" | `SUPABASE_ANON_KEY` |
| **service_role key** | Under "Project API Keys" (⚠️ keep secret!) | `SUPABASE_SERVICE_KEY` |

> ⚠️ **Never commit the `service_role` key to Git.** It bypasses Row Level Security.

### 1.3 Set Up the Database Schema

1. In Supabase, go to **SQL Editor**
2. Click **"New query"**
3. Open the file [`supabase/migrations/001_initial_schema.sql`](file:///c:/Users/tahir/Desktop/OneWater/OneWaterBusinessMobileApp/supabase/migrations/001_initial_schema.sql)
4. Paste its contents into the editor and click **Run**

### 1.4 Create a Storage Bucket

1. Go to **Storage** in the Supabase sidebar
2. Click **"New bucket"** → name it `invoices` → make it **Private**
3. Click **Create**

---

## ⚙️ Step 2 — Configure the Backend

### 2.1 Copy the `.env` file

```powershell
# Run from the project root
Copy-Item onewater_api\.env.example onewater_api\.env
```

### 2.2 Fill in your `.env`

Open [`onewater_api/.env`](file:///c:/Users/tahir/Desktop/OneWater/OneWaterBusinessMobileApp/onewater_api/.env) and fill in:

```env
SUPABASE_URL=https://your-project.supabase.co        ← from Step 1.2
SUPABASE_SERVICE_KEY=your-service-role-key-here       ← from Step 1.2
SUPABASE_ANON_KEY=your-anon-key-here                  ← from Step 1.2
JWT_SECRET=any-long-random-string-here                ← make up anything secure
JWT_ALGORITHM=HS256
JWT_EXPIRY_HOURS=24
JWT_REFRESH_EXPIRY_DAYS=30
BUSINESS_NAME=OneWater Pakistan
BUSINESS_PHONE=+92-300-0000000
BUSINESS_ADDRESS=Pakistan
INVOICE_PREFIX=OW
INVOICE_START_NUMBER=1
ENVIRONMENT=development
```

> For `JWT_SECRET`, use any strong random string e.g.:  
> `python -c "import secrets; print(secrets.token_hex(32))"`

---

## 🚀 Step 3 — Start the Backend (FastAPI)

### 3.1 Create a Python virtual environment

```powershell
cd onewater_api
python -m venv venv
.\venv\Scripts\Activate.ps1
```

### 3.2 Install dependencies

```powershell
pip install -r requirements.txt
```

### 3.3 Start the server

```powershell
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at:
- **Local**: `http://localhost:8000`
- **Docs (Swagger UI)**: `http://localhost:8000/docs`
- **Android Emulator**: `http://10.0.2.2:8000` ← automatically configured in the app

### 3.4 (Optional) Seed test data

With the server running, open a second terminal:

```powershell
cd ..             # back to project root
python seed.py
```

This creates sample users, customers, products, and transactions.

**Default admin credentials (after seeding):**
| Field | Value |
|-------|-------|
| Username | `admin` |
| Password | `admin123` |

---

## 📱 Step 4 — Run the Flutter App

### 4.1 Prerequisites

Make sure you have:
- **Flutter 3.x** installed → run `flutter doctor` to verify
- **Android Studio** with an emulator **OR** a physical Android device with USB debugging enabled

### 4.2 Install Flutter packages

```powershell
# From the project root
flutter pub get
```

### 4.3 Start the emulator (or connect a device)

```powershell
# List available emulators
flutter emulators

# Launch one
flutter emulators --launch <emulator-id>
```

Or open **Android Studio → Device Manager → Play button** on any emulator.

### 4.4 Run the app

```powershell
flutter run
```

> **Note**: The app connects to `http://10.0.2.2:8000` by default, which is how the Android emulator reaches `localhost` on your PC.  
> If using a **physical device** on the same Wi-Fi, update [`lib/core/constants/api_endpoints.dart`](file:///c:/Users/tahir/Desktop/OneWater/OneWaterBusinessMobileApp/lib/core/constants/api_endpoints.dart):
> ```dart
> static const String baseUrl = 'http://YOUR_PC_IP:8000';
> // Find your PC IP: ipconfig → look for "IPv4 Address"
> ```

---

## 🏃 Quick Start Checklist

```
□  1. Create Supabase project at supabase.com
□  2. Run supabase/migrations/001_initial_schema.sql in Supabase SQL Editor
□  3. Create "invoices" storage bucket in Supabase Storage
□  4. Copy .env.example → .env and fill in SUPABASE_URL, SERVICE_KEY, ANON_KEY
□  5. cd onewater_api && python -m venv venv && .\venv\Scripts\Activate.ps1
□  6. pip install -r requirements.txt
□  7. uvicorn main:app --reload --host 0.0.0.0 --port 8000
□  8. (Optional) python seed.py  ← from project root
□  9. flutter pub get
□ 10. flutter run
□ 11. Login with  admin / admin123
```

---

## 🌐 Production Deployment

The backend is pre-configured for **Render.com** deployment:
- Config file: [`onewater_api/render.yaml`](file:///c:/Users/tahir/Desktop/OneWater/OneWaterBusinessMobileApp/onewater_api/render.yaml)
- Connect your GitHub repo to Render, set the same `.env` variables as **Environment Variables** in Render dashboard
- Update `baseUrl` in `api_endpoints.dart` to your Render URL

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile App | Flutter 3 + Riverpod + GoRouter |
| Backend API | FastAPI (Python) |
| Database | Supabase (PostgreSQL) |
| File Storage | Supabase Storage |
| PDF Generation | ReportLab |
| Offline Cache | Hive |
| Background Jobs | WorkManager (mobile) + APScheduler (server) |
| Auth | JWT (access + refresh tokens) |
