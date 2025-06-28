import 'package:location/location.dart';

class LocationService {
  Location location = Location();
  late LocationData _locData;

  Future<void> initialize() async {
    bool _serviceEnabled;
    PermissionStatus _permission;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permission = await location.hasPermission();
    if (_permission == PermissionStatus.denied) {
      _permission = await location.requestPermission();
      if (_permission != PermissionStatus.granted) {
        return;
      }
    }
  }

  Future<String> getLocationString() async {
    _locData = await location.getLocation();
    double? lat = _locData.latitude;
    double? long = _locData.longitude;

    if (lat != null && long != null) {
      return "Lat: ${lat.toStringAsFixed(5)}, Long: ${long.toStringAsFixed(5)}";
    } else {
      return "Unknown Location";
    }
  }

  Future<double?> getLatitude() async {
    _locData = await location.getLocation();
    return _locData.latitude;
  }

  Future<double?> getLongitude() async {
    _locData = await location.getLocation();
    return _locData.longitude;
  }
}
