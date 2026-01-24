import 'dart:convert';

class Restaurant {
  final String id;
  final String name;
  final String bio;
  final String phone;
  final String address;
  final String? addressLine2;
  final String area;
  final String city;
  final String state;
  final String pincode;

  final List<String> cuisineTags;
  final List<String> amenities;

  final int priceRange;
  final bool hasAlcohol;
  final bool hasReservation;

  final String? logoImage;
  final String? coverImage;
  final List<String> gallery;
  final List<String> foodMenuPics;

  final List<dynamic> openingHours;

  final String? instagram;
  final String? facebook;
  final String? twitter;
  final String? website;
  final String? googleMaps;

  Restaurant({
    required this.id,
    required this.name,
    required this.bio,
    required this.phone,
    required this.address,
    required this.addressLine2,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
    required this.cuisineTags,
    required this.amenities,
    required this.priceRange,
    required this.hasAlcohol,
    required this.hasReservation,
    required this.logoImage,
    required this.coverImage,
    required this.gallery,
    required this.foodMenuPics,
    required this.openingHours,
    required this.instagram,
    required this.facebook,
    required this.twitter,
    required this.website,
    required this.googleMaps,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    dynamic hours = json['openingHours'];

    // 🔥 Handle STRING or LIST
    if (hours is String) {
      hours = List<dynamic>.from(
        jsonDecode(hours),
      );
    }

    return Restaurant(
      id: json['id'],
      name: json['name'] ?? '',
      bio: json['bio'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      addressLine2: json['address_line2'],
      area: json['area'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      cuisineTags: List<String>.from(json['cuisineTags'] ?? []),
      amenities: List<String>.from(json['amenities'] ?? []),
      priceRange: json['priceRange'] ?? 0,
      hasAlcohol: json['hasAlcohol'] ?? false,
      hasReservation: json['hasReservation'] ?? false,
      logoImage: json['logoImage'],
      coverImage: json['coverImage'],
      gallery: List<String>.from(json['gallery'] ?? []),
      foodMenuPics: List<String>.from(json['foodMenuPics'] ?? []),
      openingHours: hours ?? [],
      instagram: json['instaLink'],
      facebook: json['facebookLink'],
      twitter: json['twitterLink'],
      website: json['websiteurl'],
      googleMaps: json['googleMapsLink'],
    );
  }
}
