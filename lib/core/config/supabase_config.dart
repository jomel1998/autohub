class SupabaseConfig {
  static const String url = 'https://wyjgfbpkhqrluzeexsyt.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind5amdmYnBraHFybHV6ZWV4c3l0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUwMTU0MzcsImV4cCI6MjA5MDU5MTQzN30.iuXlRI60cw5YKc817PxdETatb5RYzMxC7x7G3HVXZoE';

  // Storage bucket name (create this in Supabase Dashboard → Storage)
  static const String carImagesBucket = 'car-images';

  // Table name
  static const String carsTable = 'cars';
  static const String usersTable = 'users';
}
