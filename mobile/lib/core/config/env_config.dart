/// App credentials — never commit real values.
/// Copy from your Supabase project: Settings → API
class EnvConfig {
  EnvConfig._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Cloudflare Turnstile site key (public — safe to embed).
  /// Get it from: Cloudflare Dashboard → Turnstile → your site → Site Key
  static const turnstileSiteKey = String.fromEnvironment(
    'TURNSTILE_SITE_KEY',
    defaultValue: '',
  );

  /// Sentry DSN for crash reporting (RS-070).
  /// Get it from: Sentry Dashboard → Project → Settings → Client Keys (DSN)
  /// Leave empty to disable Sentry in development.
  static const sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );
}
