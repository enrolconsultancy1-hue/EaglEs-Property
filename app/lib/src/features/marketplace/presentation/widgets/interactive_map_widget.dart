import 'package:flutter/material.dart';

class InteractiveMapWidget extends StatefulWidget {
  final List<MapMarker> markers;
  final ValueChanged<MapMarker> onMarkerTap;

  const InteractiveMapWidget({
    super.key,
    required this.markers,
    required this.onMarkerTap,
  });

  @override
  State<InteractiveMapWidget> createState() => _InteractiveMapWidgetState();
}

class _InteractiveMapWidgetState extends State<InteractiveMapWidget> {
  // Placeholder for an actual map controller (e.g. GoogleMapController)
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Stack(
        children: [
          // Simulated Map Background
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                painter: _MapGridPainter(
                  gridColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
          // Render Simulated Markers
          ...widget.markers.map((marker) {
            // Randomly position for simulation if no real lat/lng mapping
            final top = (marker.lat % 90) * 4; 
            final left = (marker.lng % 180) * 2;
            return Positioned(
              top: 50 + top.abs(),
              left: 50 + left.abs(),
              child: GestureDetector(
                onTap: () => widget.onMarkerTap(marker),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                          )
                        ],
                      ),
                      child: Text(
                        marker.label,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          // Map Controls Placeholder
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'map_zoom_in',
                  onPressed: () {},
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'map_zoom_out',
                  onPressed: () {},
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MapMarker {
  final String id;
  final String label;
  final double lat;
  final double lng;

  MapMarker({
    required this.id,
    required this.label,
    required this.lat,
    required this.lng,
  });
}

class _MapGridPainter extends CustomPainter {
  final Color gridColor;

  _MapGridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    const spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EthiopianCities {
  static final addisAbaba = MapMarker(id: 'addis', label: 'Addis Ababa', lat: 8.9806, lng: 38.7578);
  static final direDawa = MapMarker(id: 'dire', label: 'Dire Dawa', lat: 9.6009, lng: 41.8501);
  static final bahirDar = MapMarker(id: 'bahir', label: 'Bahir Dar', lat: 11.5936, lng: 37.3908);
  static final hawassa = MapMarker(id: 'hawassa', label: 'Hawassa', lat: 7.0504, lng: 38.4682);
  static final mekelle = MapMarker(id: 'mekelle', label: 'Mekelle', lat: 13.4967, lng: 39.4753);
  static final adama = MapMarker(id: 'adama', label: 'Adama', lat: 8.5414, lng: 39.2705);
  static final gondar = MapMarker(id: 'gondar', label: 'Gondar', lat: 12.6000, lng: 37.4667);

  static List<MapMarker> get all => [
    addisAbaba, direDawa, bahirDar, hawassa, mekelle, adama, gondar
  ];
}
