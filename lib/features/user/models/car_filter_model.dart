class CarFilter {
  final List<String> companies;
  final RangeValues? enginePowerRange;
  final List<String> colors;
  final List<String> conditions;
  final List<String> locations;
  final RangeValues? priceRange;
  final String? fuelType;
  final int? yearMin;
  final int? yearMax;
  final String? sortBy;
  final bool sortAscending;

  const CarFilter({
    this.companies = const [],
    this.enginePowerRange,
    this.colors = const [],
    this.conditions = const [],
    this.locations = const [],
    this.priceRange,
    this.fuelType,
    this.yearMin,
    this.yearMax,
    this.sortBy,
    this.sortAscending = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'companies': companies,
      'enginePowerRange': enginePowerRange != null 
          ? {'start': enginePowerRange!.start, 'end': enginePowerRange!.end}
          : null,
      'colors': colors,
      'conditions': conditions,
      'locations': locations,
      'priceRange': priceRange != null 
          ? {'start': priceRange!.start, 'end': priceRange!.end}
          : null,
      'fuelType': fuelType,
      'yearMin': yearMin,
      'yearMax': yearMax,
      'sortBy': sortBy,
      'sortAscending': sortAscending,
    };
  }

  factory CarFilter.fromJson(Map<String, dynamic> json) {
    return CarFilter(
      companies: List<String>.from(json['companies'] ?? []),
      enginePowerRange: json['enginePowerRange'] != null 
          ? RangeValues(
              json['enginePowerRange']['start'], 
              json['enginePowerRange']['end']
            )
          : null,
      colors: List<String>.from(json['colors'] ?? []),
      conditions: List<String>.from(json['conditions'] ?? []),
      locations: List<String>.from(json['locations'] ?? []),
      priceRange: json['priceRange'] != null 
          ? RangeValues(
              json['priceRange']['start'], 
              json['priceRange']['end']
            )
          : null,
      fuelType: json['fuelType'],
      yearMin: json['yearMin'],
      yearMax: json['yearMax'],
      sortBy: json['sortBy'],
      sortAscending: json['sortAscending'] ?? true,
    );
  }

  CarFilter copyWith({
    List<String>? companies,
    RangeValues? enginePowerRange,
    List<String>? colors,
    List<String>? conditions,
    List<String>? locations,
    RangeValues? priceRange,
    String? fuelType,
    int? yearMin,
    int? yearMax,
    String? sortBy,
    bool? sortAscending,
  }) {
    return CarFilter(
      companies: companies ?? this.companies,
      enginePowerRange: enginePowerRange ?? this.enginePowerRange,
      colors: colors ?? this.colors,
      conditions: conditions ?? this.conditions,
      locations: locations ?? this.locations,
      priceRange: priceRange ?? this.priceRange,
      fuelType: fuelType ?? this.fuelType,
      yearMin: yearMin ?? this.yearMin,
      yearMax: yearMax ?? this.yearMax,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  bool get hasActiveFilters {
    return companies.isNotEmpty ||
           enginePowerRange != null ||
           colors.isNotEmpty ||
           conditions.isNotEmpty ||
           locations.isNotEmpty ||
           priceRange != null ||
           fuelType != null ||
           yearMin != null ||
           yearMax != null;
  }

  CarFilter clearAll() {
    return const CarFilter();
  }
}

class RangeValues {
  final double start;
  final double end;

  const RangeValues(this.start, this.end);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RangeValues && other.start == start && other.end == end;
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}
