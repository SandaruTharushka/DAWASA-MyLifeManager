# Privacy policy — DAWASA

DAWASA (Daily Life Manager) is developed by Sandaru Tharushka. It is free,
contains no advertising and requires no account.

## What DAWASA stores

Everything you enter — accounts, transactions, budgets, bills, tasks,
shopping lists, savings goals, loans, habits, important dates, receipt
photos and settings — is stored **only on your phone**, in DAWASA's private
app storage. Other apps cannot read it.

## What DAWASA sends

* **No personal or financial data is ever sent anywhere.** There is no
  login, no cloud sync, no analytics, no crash reporting, no advertising
  and no tracking.
* **Updates (optional):** if an update server is configured, DAWASA
  downloads a small description file (`manifest.json`) from that server, at
  most once a day when automatic checks are on, and the new app file when
  you choose to update. These requests contain no identifiers or personal
  data. Like any website, the server can see your IP address and the app
  version. You can turn automatic checks off in Settings → App updates.

## Backups

* Android's own cloud backup and device-to-device transfer are **switched
  off** for DAWASA's data.
* A DAWASA backup is a file you create and keep yourself. It is encrypted
  with AES-256-GCM using a key derived from **your password** (Argon2id).
  Without the password nobody — including the developer — can read it. The
  password cannot be recovered.

## Security

* Optional PIN lock. Only a salted Argon2id hash of the PIN is kept, in
  Android Keystore-protected storage. The lock is a privacy screen for
  people who use your phone; your data is additionally protected by
  Android's storage encryption.
* Optional fingerprint/face unlock uses Android's system prompt. DAWASA
  never sees your fingerprint or face data.
* Optional screen protection blocks screenshots and hides DAWASA in the
  recent-apps view.

## Permissions

| Permission | Why |
|------------|-----|
| Notifications (`POST_NOTIFICATIONS`, `VIBRATE`) | Reminders for tasks, bills, budgets, loans, savings, habits and important dates. Asked only when you turn reminders on. |
| Run at startup (`RECEIVE_BOOT_COMPLETED`) | Re-creates your reminders after the phone restarts. |
| Biometrics (`USE_BIOMETRIC`) | Optional fingerprint/face unlock. |
| Internet, network state (`INTERNET`, `ACCESS_NETWORK_STATE`) | Only for checking and downloading updates (and "Wi-Fi only"). |
| Install apps (`REQUEST_INSTALL_PACKAGES`) | Lets Android show its own "update DAWASA" screen for a verified update. You always confirm. |

Receipt photos are taken with the system camera or chosen with the system
photo picker; DAWASA does not need camera or storage permissions.

## Deleting your data

* Settings → Data → **Delete all personal data** erases every record,
  photo, PIN, backup cache and setting from the phone.
* Uninstalling DAWASA or clearing its storage also deletes everything
  (Android may offer to keep the data when uninstalling). Keep a backup file
  if you want to restore later.

## Children

DAWASA does not knowingly collect any information from anyone, including
children, because it collects no information at all.

## Changes

If this policy changes, the new version is included with the app update
and shown under Settings → About → Privacy.
