import 'dart:convert';

class Restaurant {
  final String id;
  final String ownerId;
  final String name;
  final String bio;
  final String phone;
  final String address;
  final String? addressLine2;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final String? contactEmail;
  final String? websiteUrl;

  final List<String> cuisineTags;
  final List<String> amenities;

  final int priceRange;
  final bool hasAlcohol;
  final bool hasReservation;
  final String? reservationLink;
  final bool isVerified;
  final bool isComplete;

  final String? logoImage;
  final String? coverImage;
  final List<String> gallery;
  final List<String> foodMenuPics;

  final List<dynamic> openingHours;

  final String? instaLink;
  final String? facebookLink;
  final String? twitterLink;
  final String? websiteUrl2;
  final String? googleMapsLink;

  final String? location; // PostGIS geometry
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Restaurant({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.bio,
    required this.phone,
    required this.address,
    this.addressLine2,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
    this.contactEmail,
    this.websiteUrl,
    required this.cuisineTags,
    required this.amenities,
    required this.priceRange,
    required this.hasAlcohol,
    required this.hasReservation,
    this.reservationLink,
    required this.isVerified,
    required this.isComplete,
    this.logoImage,
    this.coverImage,
    required this.gallery,
    required this.foodMenuPics,
    required this.openingHours,
    this.instaLink,
    this.facebookLink,
    this.twitterLink,
    this.websiteUrl2,
    this.googleMapsLink,
    this.location,
    this.createdAt,
    this.updatedAt,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    dynamic hours = json['openingHours'];

    // Handle STRING or LIST
    if (hours is String) {
      hours = List<dynamic>.from(jsonDecode(hours));
    }

    return Restaurant(
      id: json['id'] ?? '',
      ownerId: json['ownerId'] ?? '',
      name: json['name'] ?? '',
      bio: json['bio'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      addressLine2: json['address_line2'],
      area: json['area'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      contactEmail: json['contactemail'],
      websiteUrl: json['websiteurl'],
      cuisineTags: List<String>.from(json['cuisineTags'] ?? []),
      amenities: List<String>.from(json['amenities'] ?? []),
      priceRange: json['priceRange'] ?? 0,
      hasAlcohol: json['hasAlcohol'] ?? false,
      hasReservation: json['hasReservation'] ?? false,
      reservationLink: json['reservationLink'],
      isVerified: json['isVerified'] ?? false,
      isComplete: json['iscomplete'] ?? false,
      logoImage: json['logoImage'],
      coverImage: json['coverImage'],
      gallery: List<String>.from(json['gallery'] ?? []),
      foodMenuPics: List<String>.from(json['foodMenuPics'] ?? []),
      openingHours: hours ?? [],
      instaLink: json['instaLink'],
      facebookLink: json['facebookLink'],
      twitterLink: json['twitterLink'],
      websiteUrl2: json['websiteurl'],
      googleMapsLink: json['googleMapsLink'],
      location: json['location'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  // Helper to convert to Map for accessing like restaurant['field']
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'bio': bio,
      'phone': phone,
      'address': address,
      'address_line2': addressLine2,
      'area': area,
      'city': city,
      'state': state,
      'pincode': pincode,
      'contactemail': contactEmail,
      'websiteurl': websiteUrl,
      'cuisineTags': cuisineTags,
      'cuisine': cuisineTags, // Alias for compatibility
      'amenities': amenities,
      'priceRange': priceRange,
      'hasAlcohol': hasAlcohol,
      'hasReservation': hasReservation,
      'reservationLink': reservationLink,
      'isVerified': isVerified,
      'iscomplete': isComplete,
      'logoImage': logoImage,
      'coverImage': coverImage,
      'coverimage': coverImage, // Alias
      'image': coverImage, // Alias
      'gallery': gallery,
      'photos': gallery, // Alias for compatibility
      'foodMenuPics': foodMenuPics,
      'menu_photos': foodMenuPics
          .map((url) => {'url': url})
          .toList(), // For _buildFoodMenuGallery
      'openingHours': openingHours,
      'instaLink': instaLink,
      'facebookLink': facebookLink,
      'twitterLink': twitterLink,
      'googleMapsLink': googleMapsLink,
      'location': location,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'cost_for_two': priceRange * 500, // Estimate based on price range
      'costForTwo': priceRange * 500,
      'distance': 0, // This should come from API or calculation
      'sipzy_rating': 4.5, // This should come from API
    };
  }

  // Operator overload to allow restaurant['field'] syntax
  operator [](String key) => toMap()[key];

  // Full address string
  String get fullAddress {
    final parts = [
      address,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2,
      area,
      city,
      state,
      pincode,
    ].where((p) => p?.isNotEmpty ?? false).toList();
    return parts.join(', ');
  }
}
