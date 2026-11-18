# Google sign-in setup for LearnCodz

The app-side browser OAuth flow is implemented in v1.0.4. Google must be enabled in your own Supabase project before it can work.

## 1. Google Auth Platform

Open https://console.cloud.google.com/auth/clients and select your Google Cloud project.
If prompted, click Get started. Use LearnCodz as the app name and your email for support/contact. Choose External for ordinary Gmail users.

In Clients, create an OAuth client with type **Web application**, named LearnCodz Supabase.
Add this Authorized redirect URI exactly:

https://tcxlovxkmnenwfaljfwy.supabase.co/auth/v1/callback

The current implementation uses a browser OAuth flow through Supabase. It does not use the native Google Sign-In SDK, so a Web OAuth client is intentional.
If the Google app is in Testing mode, add the Google accounts you will use under Audience > Test users.

## 2. Supabase Google provider

Open https://supabase.com/dashboard/project/tcxlovxkmnenwfaljfwy/auth/providers
Open Google and enable it. Paste the Web Client ID into Client IDs and the Client Secret into Client Secret (for OAuth), then Save.
Leave Skip nonce checks and Allow users without an email OFF.
Keep the client secret only in the provider configuration. Do not put it in chat, source code, the APK or GitHub.

## 3. Supabase redirect allowlist

Open Authentication > URL Configuration and add this exact Redirect URL:

com.learncodz.app://login-callback/

For Chrome/web testing, also allow the actual local web origin, e.g. http://localhost:52731. The Android callback above is for the APK.

## 4. Test on the phone

Install LearnCodz-v1.0.4.apk as an Update. Tap Continue with Google.
Choose your account in the external browser and approve sign-in. The callback should reopen LearnCodz and load that Supabase user's progress.
Cancelling does not create an app session. You can retry or use email/password.

Check Authentication > Users for the Google identity, and Table Editor > learncodz_backups for the user's private progress row after syncing.
For an existing email/password account, use the same email and verify that the user ID and progress remain the same. The app does not move progress between different user IDs.

## Troubleshooting

- Google sign-in not enabled: check the Google provider toggle, Client ID/Secret and Save in Supabase.
- redirect_uri_mismatch: the Google client must contain the HTTPS Supabase callback, not the app's custom callback.
- Browser does not reopen LearnCodz: check the Supabase redirect allowlist and install the updated APK.
- Access blocked while testing: add the account under the Google project's test users and review the console's consent configuration.
- No browser opens / no internet: the email sign-in form remains usable; reconnect and retry.

## Verification and limitations

Automated tests simulate the OAuth session event and verify account preparation, cloud restore, disabled-provider handling and browser launch failure/cancellation recovery. Opening a browser is never treated as successful authentication.
Google was disabled when setup was checked. A real end-to-end Google sign-in requires the owner's OAuth provider configuration and a phone/browser test.
The current management connector cannot configure this project because it is connected to another account.

Official references:
https://supabase.com/docs/guides/auth/social-sign-in/auth-google
https://supabase.com/docs/reference/dart/auth-signinwithoauth
https://supabase.com/docs/guides/auth/native-mobile-deep-linking
https://docs.flutter.dev/ui/navigation/deep-linking
