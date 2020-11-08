import 'package:flutter/widgets.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';

class LocationProvider with ChangeNotifier {
  Location_mod location = Location_mod(lat: 0, address: "", long: 0, name: "");

  Future<Location_mod> getLocation() async {
    try {
      if (!location.isaval) {
        LocationPermission permission = await checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          await requestPermission();
          return location;
        } else {
          Position position =
              await getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

          final coordinates =
              new Coordinates(position.latitude, position.longitude);
          final addresses =
              await Geocoder.local.findAddressesFromCoordinates(coordinates);
          final first = addresses.first;
          location = Location_mod(
            name: first.featureName,
            address: first.addressLine,
            lat: position.latitude,
            long: position.longitude,
            isaval: true,
          );
          return location;
        }
      } else {
        return location;
      }
    } catch (e) {
      print(e);
      throw e;
    }
  }
}
