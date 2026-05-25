# ValPay — Agrégateur de Paiement Camerounais

> Plateforme fintech cross-platform (Laravel API + Flutter Mobile/Web) pour le marché camerounais, intégrant CamPay (Orange Money, MTN MoMo, Express Union) et Reloadly (forfaits télécom).

---

## Architecture

```
ValPay/
├── valpay_backend/     # API REST Laravel 11 (PHP 8.2+)
│   ├── app/
│   │   ├── Http/Controllers/Api/   # AuthController, WalletController, PaymentController, TelecomController, QrCodeController
│   │   ├── Models/                  # User, Wallet, Transaction
│   │   ├── Services/                # CamPayService, ReloadlyService, WalletService
│   │   └── Middleware/              # ValidateTransactionPin
│   ├── database/migrations/         # users, wallets, transactions
│   └── routes/api.php               # Routes API v1
│
└── valpay_frontend/    # Flutter (Android + iOS + Web)
    ├── lib/
    │   ├── core/        # Theme, constantes, services API
    │   ├── features/    # auth, wallet, payment, telecom, qr
    │   └── main.dart
    └── pubspec.yaml
```

---

## Variables d'environnement Backend

Copier `valpay_backend/.env.example` vers `valpay_backend/.env` et remplir :

| Variable | Description |
|----------|-------------|
| `DB_HOST` | Host Supabase (ex: `db.xxxx.supabase.co`) |
| `DB_PASSWORD` | Mot de passe Supabase |
| `CAMPAY_APP_USERNAME` | Identifiant API CamPay |
| `CAMPAY_APP_PASSWORD` | Mot de passe API CamPay |
| `CAMPAY_WEBHOOK_SECRET` | Secret pour valider les webhooks |
| `RELOADLY_CLIENT_ID` | Client ID Reloadly |
| `RELOADLY_CLIENT_SECRET` | Client Secret Reloadly |

---

## Installation Backend (Laravel)

### Prérequis
- PHP 8.2+ : [Télécharger PHP pour Windows](https://windows.php.net/download/) → Thread Safe x64, extraire dans `C:\php82` et ajouter au PATH
- Composer : [Télécharger Composer](https://getcomposer.org/Composer-Setup.exe)

### Étapes
```bash
cd valpay_backend

# Installer les dépendances
composer install

# Configurer l'environnement
copy .env.example .env
php artisan key:generate

# Lancer les migrations sur Supabase
php artisan migrate

# (Optionnel) Seed de test
php artisan db:seed

# Démarrer le serveur de développement
php artisan serve
```

---

## Installation Frontend (Flutter)

### Prérequis
- Flutter SDK 3.x : [flutter.dev](https://flutter.dev/docs/get-started/install/windows)
- Android Studio (pour Android) ou Xcode (pour iOS)

### Étapes
```bash
cd valpay_frontend

# Installer les dépendances Dart
flutter pub get

# Lancer sur Android (émulateur ou device)
flutter run

# Lancer sur Web (Chrome)
flutter run -d chrome

# Compiler l'APK de production
flutter build apk --release

# L'APK sera dans : build/app/outputs/flutter-apk/app-release.apk
```

---

## Déploiement

### Backend sur Railway
```bash
# 1. Créer un projet sur railway.app
# 2. Connecter le repo GitHub
# 3. Sélectionner le dossier valpay_backend comme root
# 4. Ajouter les variables d'environnement dans le dashboard
# 5. Railway détecte automatiquement PHP + Composer
```

### Frontend Web sur Vercel
```bash
cd valpay_frontend
flutter build web --release

# Déployer le dossier build/web sur Vercel
npx vercel --prod build/web
```

---

## Tarification

| Opération | Frais |
|-----------|-------|
| Recharge (CamPay) | **0%** |
| Transfert P2P | **1%** (à la charge de l'envoyeur) |
| Retrait (CamPay) | **1%** (prélevé du solde) |
| Achat forfait télécom | **0%** (prix opérateur) |

---

## API Endpoints

| Méthode | Route | Description |
|---------|-------|-------------|
| POST | `/api/v1/auth/register` | Inscription |
| POST | `/api/v1/auth/login` | Connexion |
| GET | `/api/v1/wallet/balance` | Solde du portefeuille |
| GET | `/api/v1/wallet/transactions` | Historique |
| GET | `/api/v1/wallet/export` | Export CSV |
| POST | `/api/v1/payments/deposit` | Recharge via CamPay |
| POST | `/api/v1/payments/transfer` | Transfert P2P |
| POST | `/api/v1/payments/withdraw` | Retrait via CamPay |
| GET | `/api/v1/telecom/plans` | Liste forfaits |
| POST | `/api/v1/telecom/purchase` | Achat forfait |
| GET | `/api/v1/qr/data` | Données QR Code |
| GET | `/pay/{walletId}` | Page de paiement publique |
| POST | `/api/v1/payments/campay/webhook` | Webhook CamPay (interne) |

---

## Sécurité

- Authentification stateless via **Laravel Sanctum** (tokens Bearer)
- Toutes les transactions protégées par **code PIN 4 chiffres** (hashé en base)
- Transferts dans une **DB::transaction()** avec **lockForUpdate()** (anti double-débit)
- Webhooks CamPay validés par **signature HMAC-SHA256**
- CORS configuré pour les domaines autorisés uniquement
