# CLAUDE.md — ValPay Technical Reference

## Project Overview

ValPay is a cross-platform fintech aggregator for the Cameroonian market.
- **Backend**: Laravel 11 API (PHP 8.2), PostgreSQL via Supabase
- **Frontend**: Flutter 3.x (Android, iOS, Web)
- **Payments**: CamPay (Orange Money, MTN MoMo, Express Union)
- **Telecom**: Reloadly API (Orange/MTN Cameroon data & voice bundles)

---

## Backend Architecture

### Key Design Decisions

**1. Service Layer Pattern**
All business logic lives in `app/Services/`, never in controllers.
- `CamPayService` — CamPay API calls (collect, disburse, webhook validation)
- `ReloadlyService` — Reloadly API with 1h plan cache (reduces API calls)
- `WalletService` — Wallet operations with DB transactions and lockForUpdate()

**2. Fee Model**
- Deposits: 0% — CamPay charges the sender directly
- P2P Transfers: 1% — Sender pays `amount + fee`, receiver gets exact `amount`
- Withdrawals: 1% — `amount + fee` deducted from wallet, `amount` sent to Mobile Money
- Airtime: 0% — users pay exactly the plan price from their wallet

**3. Transaction Safety**
Every wallet mutation uses `DB::transaction()` with `lockForUpdate()` on the wallet row to prevent race conditions and double-spend attacks.

**4. Webhook Security**
CamPay webhooks are authenticated using HMAC-SHA256 signature verification against `CAMPAY_WEBHOOK_SECRET`. Wallets are only credited after successful webhook — never on API response alone.

**5. PIN Security**
The 4-digit transaction PIN is stored hashed using Laravel's `bcrypt` (via the `hashed` cast on the `pin_code` field). The `ValidateTransactionPin` middleware rejects requests if no PIN is set.

---

## Database Schema

### users
| Column | Type | Notes |
|--------|------|-------|
| id | bigint | Auto-increment PK |
| name | string | |
| email | string unique | |
| phone_number | string unique | Format: +237XXXXXXXXX |
| password | string | hashed |
| pin_code | string nullable | hashed, 4 digits |
| deleted_at | timestamp | Soft deletes |

### wallets
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | PK |
| user_id | bigint FK | unique — 1 wallet per user |
| balance | decimal(15,2) | unsigned, default 0 |
| currency | string | XAF |
| is_frozen | boolean | fraud protection |

### transactions
| Column | Type | Notes |
|--------|------|-------|
| id | uuid | PK |
| reference | string unique | VP-YYYYMMDD-RANDOM |
| sender_wallet_id | uuid nullable FK | null for deposits |
| receiver_wallet_id | uuid nullable FK | null for withdrawals |
| type | enum | deposit, withdrawal, p2p_transfer, airtime_purchase |
| amount | decimal(15,2) | gross amount |
| fee | decimal(15,2) | 0 or 1% |
| net_amount | decimal(15,2) | amount received |
| status | enum | pending, completed, failed |
| provider | string | campay, reloadly, internal |
| metadata | json | phone number, operator, etc. |

---

## API Routes Summary

All routes are prefixed with `/api/v1/`.

**Public routes** (no auth):
- `POST /auth/register` — creates user + wallet
- `POST /auth/login` — returns Sanctum token
- `POST /payments/campay/webhook` — HMAC protected
- `GET /pay/{walletId}` — payment link info
- `POST /pay/{walletId}` — external payer

**Auth required** (`Bearer {token}`):
- All `/wallet/*`, `/payments/*`, `/telecom/*`, `/qr/*` routes
- `/payments/*` and `/telecom/purchase` additionally require middleware `pin` (PIN must be set)

---

## Flutter Architecture

### Folder structure
```
lib/
├── core/
│   ├── api/         # Dio client, interceptors, base service
│   ├── theme/       # Color tokens, text styles
│   └── constants.dart
├── features/
│   ├── auth/        # Login, Register, PIN setup screens
│   ├── wallet/      # Dashboard, History, Export
│   ├── payment/     # Deposit, Transfer, Withdraw flows
│   ├── telecom/     # Plan catalog, Purchase
│   └── qr/          # QR generator, QR scanner
└── main.dart         # kIsWeb routing split
```

### Key packages
- `dio` — HTTP client with auth interceptor
- `flutter_bloc` — state management (BLoC/Cubit pattern)
- `mobile_scanner` — QR code scanning (camera)
- `qr_flutter` — QR code generation
- `fl_chart` — Balance history charts
- `pdf` — Transaction receipt PDF export

### Web vs Mobile
The app uses `kIsWeb` at the `main.dart` level to route to separate widget trees:
- `MobileApp` — Bottom nav: Dashboard, QR, Forfaits, Historique
- `WebApp` — Sidebar nav: Landing, Dashboard, Transactions, Paiement par lien

---

## Environment & Deployment

### Local development
```bash
# Backend
cd valpay_backend && php artisan serve  # → http://localhost:8000

# Flutter mobile
cd valpay_frontend && flutter run

# Flutter web
cd valpay_frontend && flutter run -d chrome
```

### Production deployment
- **Backend**: Railway (auto-detects PHP + Composer, set env vars in dashboard)
- **Web Frontend**: `flutter build web` → deploy `build/web/` to Vercel
- **Mobile**: `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`

---

## Pending: PHP Installation Required

The terminal environment has no internet access. To complete the backend setup, the developer must:

1. Download PHP 8.2 Thread Safe x64 from https://windows.php.net/download/
   - Extract to `C:\php82`
   - Copy `php.ini-production` → `php.ini`
   - Enable extensions: `extension=pdo_pgsql`, `extension=pgsql`, `extension=openssl`, `extension=mbstring`, `extension=fileinfo`, `extension=curl`, `extension=zip`
   - Add `C:\php82` to Windows PATH

2. Download Composer from https://getcomposer.org/Composer-Setup.exe and run installer

3. Then run:
   ```bash
   cd C:\Users\NTS\ValPay\valpay_backend
   composer install
   copy .env.example .env
   php artisan key:generate
   php artisan migrate
   ```
