abstract final class AppConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const businessUrl = String.fromEnvironment(
    'BUSINESS_WEB_URL',
    defaultValue: 'https://business.yolo-hub.com',
  );
  static const demo = bool.fromEnvironment('DEMO');
  static const tiles = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );
  static bool get configured => url.startsWith('https://') && key.isNotEmpty;
}
