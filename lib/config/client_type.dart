enum ClientType {
  guara,
  valeDasMinas;

  String get displayName {
    switch (this) {
      case ClientType.guara:
        return 'Guará';
      case ClientType.valeDasMinas:
        return 'Vale das Minas';
    }
  }

  String get id {
    switch (this) {
      case ClientType.guara:
        return 'guara';
      case ClientType.valeDasMinas:
        return 'vale_das_minas';
    }
  }
}
