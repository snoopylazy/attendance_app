import 'package:location/location.dart';

class LocationService {
  Location location = Location();
  late LocationData _locData;

  /// Returns true if location service is ready, false otherwise.
  Future<bool> initialize() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        // Service not enabled, can't proceed
        return false;
      }
    }

    PermissionStatus permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
      if (permission != PermissionStatus.granted) {
        // Permission denied, can't proceed
        return false;
      }
    }

    if (permission == PermissionStatus.deniedForever) {
      // Permissions permanently denied, cannot request again
      return false;
    }

    return true;
  }

  /// Safely get location, returns null if failed
  Future<LocationData?> getLocation() async {
    try {
      _locData = await location.getLocation();
      return _locData;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // GetLocation
  Future<String> getLocationString() async {
    LocationData? locData = await getLocation();
    if (locData == null) return "Unknown Location";

    double? lat = locData.latitude;
    double? long = locData.longitude;

    if (lat != null && long != null) {
      return "Lat: ${lat.toStringAsFixed(5)}, Long: ${long.toStringAsFixed(5)}";
    } else {
      return "Unknown Location";
    }
  }

  // Fetch Lat
  Future<double?> getLatitude() async {
    LocationData? locData = await getLocation();
    return locData?.latitude;
  }

  // Fetch Lon
  Future<double?> getLongitude() async {
    LocationData? locData = await getLocation();
    return locData?.longitude;
  }
}
