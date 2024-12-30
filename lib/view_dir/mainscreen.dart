import 'dart:async';
import 'dart:convert';
import 'package:firozabadwastemng/appConstants/appconstants.dart';
import 'package:firozabadwastemng/view_dir/startsurvey.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../sqliteFolder/sqlite_model.dart';
import '../sqliteFolder/sqlite_service.dart';
import 'house_holdNumber.dart';

// ------------------------------------ MapScreen --------------------------------------------------

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // State Variables
  Marker? userMarker; // For a single marker
  List<LatLng> polygonPoints = []; // Points for polygon drawing
  bool isPolygonMode = false; // Toggle between marker and polygon mode
  LatLng? currentPosition; // Current user location
  Set<Polygon> polygons = {}; // To store and render the polygon
  bool isLoading = true; // Loading indicator
  final Completer<GoogleMapController> _controller = Completer();
  List<Marker> polygonMarkers = []; // Markers for polygon points
  final Set<Polyline> polylines = {}; // Use Set instead of List

  Set<Marker> markers = {}; // Use a Set instead of a List

  Set<Marker> fetchedMarkers = {}; // Holds fetched markers from SQLite
  Set<Polygon> fetchedPolygons = {}; // Holds fetched polygon data from SQLite

  @override
  void initState() {
    super.initState();
    requestPermissions();
    _loadGeoJson(); // Load GeoJSON data
    _loadTestPolygon(); // Add test polygon
    _loadTaggedLocations(); // Load tagged locations from database
  }

  Future<void> _loadTaggedLocations() async {
    try {
      // Get all locations from the database
      List<FormData> locations = await SqliteService().fetchAllLocations();
      print('Fetched ${locations.length} locations');

      // Loop through the locations and add each location to the map
      for (var location in locations) {
        print("Adding location: ${location.tagged_location}");
        _addLocationFromWKT(location.tagged_location);
      }
    } catch (e) {
      debugPrint('Error fetching locations: $e');
    }
  }

  String cleanWKT(String wkt) {
    return wkt.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _addLocationFromWKT(String wkt) {
    try {
      wkt = cleanWKT(wkt); // Clean WKT data

      // Handle POINT WKT
      if (wkt.startsWith('POINT')) {
        final coords = wkt
            .replaceAll('POINT', '')
            .replaceAll('(', '')
            .replaceAll(')', '')
            .split(' ');
        final lat = double.parse(coords[1]);
        final lon = double.parse(coords[0]);

        setState(() {
          fetchedMarkers.add(
            Marker(
              markerId: MarkerId(LatLng(lat, lon).toString()),
              position: LatLng(lat, lon),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
            ),
          );
        });
      }
      // Handle LINESTRING WKT
      else if (wkt.startsWith('LINESTRING')) {
        final coordsString = wkt
            .replaceAll('LINESTRING', '')
            .replaceAll('(', '')
            .replaceAll(')', '');
        final coordsList = coordsString.split(',');
        List<LatLng> points = [];
        for (var coord in coordsList) {
          final latLon = coord.trim().split(' ');
          final lat = double.parse(latLon[1]);
          final lon = double.parse(latLon[0]);
          points.add(LatLng(lat, lon));
        }

        setState(() {
          polylines.add(
            Polyline(
              polylineId: PolylineId(polylines.length.toString()),
              points: points,
              color: Colors.blue,
              width: 3,
            ),
          );
        });
      }
      // Handle POLYGON WKT
      else if (wkt.startsWith('POLYGON')) {
        final coordsString = wkt
            .replaceAll('POLYGON', '')
            .replaceAll('(', '')
            .replaceAll(')', '');
        final coordsList = coordsString.split(',');
        List<LatLng> points = [];
        for (var coord in coordsList) {
          final latLon = coord.trim().split(' ');
          final lat = double.parse(latLon[1]);
          final lon = double.parse(latLon[0]);
          points.add(LatLng(lat, lon));
        }

        setState(() {
          fetchedPolygons.add(
            Polygon(
              polygonId: PolygonId(polygons.length.toString()),
              points: points,
              fillColor: Colors.blue.shade900.withOpacity(0.3),
              strokeColor: Colors.blue.shade900,
              strokeWidth: 3,
            ),
          );
        });
      }
      // Unsupported WKT type
      else {
        print("Unsupported WKT type: $wkt");
      }
    } catch (e) {
      debugPrint("Error parsing WKT: $e");
    }
  }

  void _loadTestPolygon() {
    // Move camera to the test polygon location
    _controller.future.then((mapController) {
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(const LatLng(27.1592, 78.3957), 18),
      );
    });
  }

  Future<void> _loadGeoJson() async {
    try {
      final String geoJsonString =
          await rootBundle.loadString('assets/Fnn_ward3_layer.geojson');
      final Map<String, dynamic> geoJsonData = jsonDecode(geoJsonString);

      final List features = geoJsonData['features'];
      for (var feature in features) {
        final Map<String, dynamic> geometry = feature['geometry'];
        if (geometry['type'] == 'MultiLineString') {
          _addMultiLineString(geometry['coordinates']);
        }
      }
    } catch (e) {
      debugPrint('Error loading GeoJSON: $e');
    }
  }

  void _addMultiLineString(List coordinates) {
    for (var line in coordinates) {
      List<LatLng> points = [];
      for (var point in line) {
        points.add(LatLng(point[1], point[0]));
      }

      setState(() {
        polylines.add(
          Polyline(
            polylineId: PolylineId(polylines.length.toString()),
            points: points,
            color: Colors.red,
            width: 3,
          ),
        );
      });
    }
  }

  // Request Location Permissions
  Future<void> requestPermissions() async {
    final locationStatus = await Permission.location.request();
    if (locationStatus == PermissionStatus.granted) {
      await getUserLocation();
      setState(() => isLoading = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please allow location access to use this feature.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fetch User Location
  Future<void> getUserLocation() async {
    try {
      var position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        currentPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint("Error fetching location: $e");
    }
  }

  // Toggle Polygon Mode
  void _togglePolygonMode() {
    setState(() {
      isPolygonMode = !isPolygonMode;
      if (!isPolygonMode) {
        polygonPoints.clear(); // Clear points if leaving polygon mode
        polygonMarkers.clear(); // Clear the markers list
      }
    });
  }

  Future<void> _goToCurrentLocation() async {
    if (currentPosition == null) return;
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: currentPosition!,
          zoom: 18.5,
        ),
      ),
    );
  }

  // Convert Polygon Points to WKT
  String convertPolygonToWKT(List<LatLng> points) {
    if (points.isEmpty) return '';
    String wkt = 'POLYGON((';
    for (var point in points) {
      wkt += '${point.longitude} ${point.latitude}, ';
    }
    wkt +=
        '${points.first.longitude} ${points.first.latitude}))'; // Close the polygon
    return wkt;
  }

  // Convert Marker to WKT
  String convertMarkerToWKT(LatLng position) {
    return 'POINT(${position.longitude} ${position.latitude})';
  }

  // Save Data (Marker or Polygon)
  void _saveData() {
    if (isPolygonMode && polygonPoints.length >= 3) {
      String wkt = convertPolygonToWKT(polygonPoints);
      debugPrint('Polygon WKT: $wkt');
      AppConstants.pageTransition(context, FormDetails(wkt: wkt));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Polygon saved successfully!')),
      );
    } else if (!isPolygonMode && userMarker != null) {
      String wkt = convertMarkerToWKT(userMarker!.position);
      debugPrint('Marker WKT: $wkt');
      AppConstants.pageTransition(context, FormDetails(wkt: wkt));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marker saved successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please add a marker or create a polygon before saving.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Clear Polygon Points
  void _clearPolygon() {
    setState(() {
      polygonPoints.clear();
      polygonMarkers.clear(); // Clear the markers list
      polygons.clear();
      userMarker = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        AppConstants.pageTransition(context, const StartSurveyScreen());
        return true;
      },
      child: isLoading
          ? RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
              },
              child: Scaffold(
                appBar: AppBar(
                  title: const Text(
                    "Select Location",
                    style: TextStyle(color: Colors.white),
                  ),
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      AppConstants.pageTransition(
                          context, const StartSurveyScreen());
                    },
                  ),
                  backgroundColor: const Color(0xff228B22),
                  centerTitle: true,
                  toolbarHeight: 80,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(15.0),
                      bottomRight: Radius.circular(15.0),
                    ),
                  ),
                ),
                body: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 5),
                      Text(
                        "Fetching Location",
                        style: TextStyle(fontSize: 20),
                      ),
                      CircularProgressIndicator(),
                    ],
                  ),
                ),
              ),
            )

          // isLoading
          //     ? const Center(child: CircularProgressIndicator())
          : Scaffold(
              appBar: AppBar(
                title: const Text(
                  "Select Location",
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: const Color(0xff228B22),
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    AppConstants.pageTransition(
                        context, const StartSurveyScreen());
                  },
                ),
              ),
              body: Stack(
                children: [
                  GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                    initialCameraPosition: CameraPosition(
                      target: currentPosition ?? const LatLng(27.1592, 78.3957),
                      zoom: 30,
                    ),
                    markers: {
                      if (userMarker != null)
                        userMarker!, // Marker in marker mode
                      ...polygonMarkers, // Polygon point markers
                      ...fetchedMarkers
                    },
                    polygons: {
                      if (polygonPoints.length >= 3)
                        Polygon(
                          polygonId: const PolygonId('user_polygon'),
                          points: polygonPoints,
                          fillColor: Colors.green.withOpacity(0.3),
                          strokeColor: Colors.green,
                          strokeWidth: 3,
                        ),
                      ...fetchedPolygons, // Add fetched polygons to the map
                    },
                    mapType: MapType.satellite,
                    polylines: polylines,
                    onTap: (LatLng position) {
                      setState(() {
                        if (isPolygonMode) {
                          // Add the tapped position to the polygon
                          polygonPoints.add(position);

                          // Add a marker for the polygon point
                          polygonMarkers.add(
                            Marker(
                              markerId: MarkerId(
                                  'polygon_point_${polygonPoints.length}'),
                              position: position,
                              draggable: true, // Make the marker draggable
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueBlue),
                              onDragEnd: (newPosition) {
                                _updatePolygonMarkerPosition(newPosition,
                                    'polygon_point_${polygonPoints.length - 1}');
                              },
                            ),
                          );
                        } else {
                          // Add a single marker in marker mode
                          userMarker = Marker(
                            markerId: const MarkerId('user_marker'),
                            position: position,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueRed),
                          );
                        }
                      });
                    },
                  ),

                  Positioned(
                    top: 40,
                    right: 15,
                    child: ElevatedButton(
                      onPressed: _goToCurrentLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xff228B22), // Green background color
                        foregroundColor: Colors.white, // White icon color
                        padding: const EdgeInsets.all(
                            16), // Equal padding for a circular shape
                        shape: const CircleBorder(), // Circular shape
                        elevation: 8, // Shadow for a floating effect
                        shadowColor: Colors.black54, // Softer shadow color
                      ),
                      child: const Icon(
                        Icons.my_location,
                        size: 24, // Icon size
                      ),
                    ),
                  ),

                  // Polygon Toggle Button
                  Stack(
                    children: [
                      Align(
                        alignment:
                            Alignment.bottomRight, // Align buttons to the right
                        child: Padding(
                          padding: const EdgeInsets.only(
                              right: 5,
                              bottom: 110), // Add padding from the right edgebb
                          child: Column(
                            mainAxisSize: MainAxisSize
                                .min, // Minimize space occupied by the column
                            crossAxisAlignment: CrossAxisAlignment
                                .center, // Align icons in the center
                            children: [
                              ElevatedButton(
                                onPressed: _togglePolygonMode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isPolygonMode
                                      ? Colors.red
                                      : const Color(0xff228B22),
                                  shape:
                                      const CircleBorder(), // Circular button
                                  padding: const EdgeInsets.all(
                                      16), // Padding inside the button
                                ),
                                child: Icon(
                                  isPolygonMode
                                      ? Icons.stop
                                      : Icons.create, // Dynamic icon
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(
                                  height: 10), // Space between buttons
                              ElevatedButton(
                                onPressed: _clearPolygon,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(16),
                                ),
                                child: const Icon(
                                  Icons.clear,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(
                                  height: 10), // Space between buttons
                              ElevatedButton(
                                onPressed: _saveData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff228B22),
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(16),
                                ),
                                child: const Icon(
                                  Icons.save,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
    );
  }

  void _updatePolygonMarkerPosition(LatLng newPosition, String markerId) {
    setState(() {
      // Find the index of the marker by its markerId
      int markerIndex = polygonMarkers.indexWhere(
        (marker) => marker.markerId.value == markerId,
      );

      if (markerIndex != -1) {
        // Update the position of the corresponding polygon point
        polygonPoints[markerIndex] = newPosition;

        // Update the marker in the list
        polygonMarkers[markerIndex] = polygonMarkers[markerIndex].copyWith(
          positionParam: newPosition,
        );
      }
    });
  }
}

extension MarkerCopyWith on Marker {
  Marker copyWith({
    LatLng? positionParam,
    String? markerIdParam,
  }) {
    return Marker(
      markerId: markerIdParam != null ? MarkerId(markerIdParam) : markerId,
      position: positionParam ?? position,
      draggable: draggable,
      icon: icon,
      onDragEnd: onDragEnd,
    );
  }
}
