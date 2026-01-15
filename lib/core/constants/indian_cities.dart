// lib/core/constants/indian_cities.dart

class IndianCities {
  static const List<String> all = [
    'Agra',
    'Ahmedabad',
    'Allahabad',
    'Amritsar',
    'Aurangabad',
    'Bangalore',
    'Bhopal',
    'Bhubaneswar',
    'Chandigarh',
    'Chennai',
    'Coimbatore',
    'Delhi',
    'Dhanbad',
    'Faridabad',
    'Ghaziabad',
    'Gurgaon',
    'Guwahati',
    'Gwalior',
    'Hyderabad',
    'Indore',
    'Jabalpur',
    'Jaipur',
    'Jamshedpur',
    'Jodhpur',
    'Kalyan-Dombivali',
    'Kanpur',
    'Kochi',
    'Kolkata',
    'Kota',
    'Lucknow',
    'Ludhiana',
    'Madurai',
    'Meerut',
    'Mumbai',
    'Mysore',
    'Nagpur',
    'Nashik',
    'Navi Mumbai',
    'Noida',
    'Patna',
    'Pimpri-Chinchwad',
    'Pune',
    'Raipur',
    'Rajkot',
    'Ranchi',
    'Srinagar',
    'Surat',
    'Thane',
    'Thiruvananthapuram',
    'Vadodara',
    'Varanasi',
    'Vasai-Virar',
    'Vijayawada',
    'Visakhapatnam',
    'Other',
  ];

  /// Get cities by first letter (for search/filter)
  static Map<String, List<String>> get byFirstLetter {
    final Map<String, List<String>> grouped = {};

    for (final city in all) {
      final firstLetter = city[0].toUpperCase();
      if (!grouped.containsKey(firstLetter)) {
        grouped[firstLetter] = [];
      }
      grouped[firstLetter]!.add(city);
    }

    return grouped;
  }

  /// Search cities by name (case-insensitive)
  static List<String> search(String query) {
    if (query.isEmpty) return all;

    final lowerQuery = query.toLowerCase();
    return all
        .where((city) => city.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Top 10 most populous cities (for quick access)
  static const List<String> topCities = [
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Hyderabad',
    'Chennai',
    'Kolkata',
    'Pune',
    'Ahmedabad',
    'Jaipur',
    'Surat',
  ];

  /// Check if a city is in the list
  static bool contains(String city) {
    return all.contains(city);
  }
}
