<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: DejaVu Sans, sans-serif; color: #1a1a2e; font-size: 13px; background: #fff; }

  .header {
    background: linear-gradient(135deg, #0d2247 0%, #2563eb 100%);
    color: white;
    padding: 32px 40px 24px;
    border-radius: 0 0 16px 16px;
  }
  .header h1 { font-size: 28px; font-weight: 700; letter-spacing: 2px; }
  .header p { font-size: 11px; letter-spacing: 3px; color: rgba(255,255,255,0.7); margin-top: 4px; }

  .badge {
    display: inline-block;
    background: #22c55e;
    color: white;
    font-size: 11px;
    font-weight: 700;
    letter-spacing: 1.5px;
    padding: 4px 14px;
    border-radius: 20px;
    margin-top: 16px;
  }

  .body { padding: 32px 40px; }

  .section-title {
    font-size: 10px;
    letter-spacing: 2px;
    color: #6b7280;
    font-weight: 700;
    text-transform: uppercase;
    margin-bottom: 12px;
    margin-top: 24px;
  }

  .card {
    background: #f8fafc;
    border: 1px solid #e2e8f0;
    border-radius: 10px;
    padding: 16px 20px;
  }

  .row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 8px 0;
    border-bottom: 1px solid #f1f5f9;
  }
  .row:last-child { border-bottom: none; }
  .row .label { color: #6b7280; font-size: 12px; }
  .row .value { font-weight: 600; color: #1a1a2e; font-size: 12px; }

  .amount-box {
    background: #eff6ff;
    border: 2px solid #2563eb;
    border-radius: 12px;
    padding: 20px 24px;
    text-align: center;
    margin: 24px 0;
  }
  .amount-box .label { font-size: 11px; color: #2563eb; letter-spacing: 1px; text-transform: uppercase; }
  .amount-box .amount { font-size: 36px; font-weight: 700; color: #0d2247; margin-top: 4px; }

  .ref-box {
    background: #1e293b;
    color: #94a3b8;
    font-family: monospace;
    font-size: 11px;
    letter-spacing: 1px;
    padding: 10px 16px;
    border-radius: 8px;
    text-align: center;
    margin-top: 8px;
  }
  .ref-box span { color: #fff; font-weight: 700; font-size: 13px; }

  .footer {
    margin-top: 40px;
    padding-top: 16px;
    border-top: 1px solid #e2e8f0;
    text-align: center;
    color: #9ca3af;
    font-size: 10px;
  }
  .footer strong { color: #2563eb; }

  .watermark {
    position: fixed;
    bottom: 80px;
    right: 40px;
    opacity: 0.04;
    font-size: 80px;
    font-weight: 900;
    color: #2563eb;
    transform: rotate(-30deg);
    letter-spacing: 4px;
  }
</style>
</head>
<body>

<div class="watermark">VALPAY</div>

<div class="header">
  <h1>VALPAY</h1>
  <p>PAIEMENTS SIMPLIFIÉS — CAMEROUN</p>
  <div class="badge">✓ PAIEMENT CONFIRMÉ</div>
</div>

<div class="body">

  <div class="amount-box">
    <div class="label">Montant payé</div>
    <div class="amount">{{ number_format($amount, 0, ',', ' ') }} FCFA</div>
  </div>

  <div class="ref-box">
    Référence : <span>{{ $reference }}</span>
  </div>

  <div class="section-title">Payeur</div>
  <div class="card">
    <div class="row">
      <span class="label">Nom</span>
      <span class="value">{{ $payer_name }}</span>
    </div>
    <div class="row">
      <span class="label">Téléphone</span>
      <span class="value">{{ $payer_phone }}</span>
    </div>
  </div>

  <div class="section-title">Bénéficiaire</div>
  <div class="card">
    <div class="row">
      <span class="label">Nom</span>
      <span class="value">{{ $recipient_name }}</span>
    </div>
    <div class="row">
      <span class="label">Téléphone</span>
      <span class="value">{{ $recipient_phone }}</span>
    </div>
  </div>

  <div class="section-title">Détails transaction</div>
  <div class="card">
    <div class="row">
      <span class="label">Date & heure</span>
      <span class="value">{{ $date->format('d/m/Y à H:i') }}</span>
    </div>
    <div class="row">
      <span class="label">Réseau</span>
      <span class="value">Mobile Money (CamPay)</span>
    </div>
    <div class="row">
      <span class="label">Frais</span>
      <span class="value">0 FCFA</span>
    </div>
    <div class="row">
      <span class="label">Statut</span>
      <span class="value" style="color: #22c55e;">✓ Complété</span>
    </div>
  </div>

  <div class="footer">
    Ce reçu est généré automatiquement par <strong>ValPay</strong>.<br>
    Il constitue une preuve de paiement valide. Conservez-le précieusement.<br><br>
    ValPay — Douala, Cameroun · support@valpay.cm
  </div>

</div>
</body>
</html>
