class Service {
  String name;
  String? type;
  String? address;
  Map<String, String?> metadata;
  String discoverySource;

  Service(this.name, this.type, this.address, this.metadata, this.discoverySource);

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'address': address,
        'metadata': metadata,
        'discoverySource': discoverySource.toString()
      };

  @override
  String toString() {
    return 'Service{name: $name, type: $type, address: $address, metadata: $metadata, discoverySource: $discoverySource}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Service &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          address == other.address &&
          discoverySource == other.discoverySource;

  @override
  int get hashCode => type.hashCode ^ address.hashCode ^ discoverySource.hashCode;
}
