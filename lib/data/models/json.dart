typedef Json = Map<String, dynamic>;

DateTime? parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

List<T> parseList<T>(Object? value, T Function(Json) fromJson) =>
    value is List ? value.whereType<Json>().map(fromJson).toList() : <T>[];

List<String> parseStrings(Object? value) =>
    value is List ? value.whereType<String>().toList() : <String>[];

/// Drops null entries so request bodies only carry fields that are set.
Json compact(Json json) => {
      for (final e in json.entries)
        if (e.value != null) e.key: e.value,
    };
