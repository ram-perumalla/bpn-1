class BleScanData {
  String id = ''; // always empty from the client side
  String deviceId;
  String name;
  int rssi;
  String deviceType;
  int timestamp;
  BleScanData({required this.deviceId, required this.name, required this.rssi, required this.deviceType, required this.timestamp});
  Map<String, dynamic> toJson() => {
    'id': id,
    'deviceId' : deviceId,
    'name': name,
    'rssi': rssi,
    'deviceType': deviceType,
    'timestamp': timestamp,
  };
}