import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

// Modèle pour les positions historiques
class PositionHistory {
  final LatLng position;
  final DateTime timestamp;
  final double accuracy;
  final String? label;

  PositionHistory({
    required this.position,
    required this.timestamp,
    required this.accuracy,
    this.label,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'accuracy': accuracy,
      'label': label,
    };
  }

  factory PositionHistory.fromJson(Map<String, dynamic> json) {
    return PositionHistory(
      position: LatLng(json['latitude'], json['longitude']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      accuracy: json['accuracy'],
      label: json['label'],
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLoading = true;
  bool _mapReady = false;
  bool _isOffline = false;
  bool _offlineModeEnabled = false;
  String? _error;
  bool _disposed = false;
  bool _isGettingLocation = false;

  // Historique des positions
  List<PositionHistory> _positionHistory = [];
  bool _showHistory = false;
  bool _trackingEnabled = false;
  Timer? _trackingTimer;
  final int _maxHistoryPoints = 30;
  bool _isProcessingHistory = false;

  // Position par défaut (Paris)
  final LatLng _defaultCenter = const LatLng(48.8566, 2.3522);
  final double _defaultZoom = 13.0;

  // Connectivité
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Cache des marqueurs
  List<Marker>? _cachedMarkers;
  List<Polyline>? _cachedPolylines;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _cleanup();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pauseTracking();
    } else if (state == AppLifecycleState.resumed && _trackingEnabled) {
      _resumeTracking();
    }
  }

  void _cleanup() {
    _trackingTimer?.cancel();
    _connectivitySubscription?.cancel();
    _trackingTimer = null;
    _connectivitySubscription = null;
  }

  void _pauseTracking() {
    _trackingTimer?.cancel();
  }

  void _resumeTracking() {
    if (_trackingEnabled && !_disposed) {
      _startPeriodicTracking();
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) {
      setState(fn);
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Initialisation rapide sans attendre la géolocalisation
      await _initConnectivity();
      await _loadPositionHistory();

      // Géolocalisation non-bloquante
      _getCurrentLocationWithFallback();
    } catch (e) {
      debugPrint('Erreur d\'initialisation: $e');
      if (!_disposed) {
        _safeSetState(() {
          _isLoading = false;
          _error = 'Erreur d\'initialisation';
        });
      }
    }
  }

  // Géolocalisation avec fallback et timeout court
  Future<void> _getCurrentLocationWithFallback() async {
    if (_disposed || _isGettingLocation) return;

    _isGettingLocation = true;

    try {
      _safeSetState(() {
        _isLoading = true;
        _error = null;
      });

      // Vérifier d'abord si les services de localisation sont activés
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationServiceDisabledException();
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de géolocalisation refusée');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Permissions de géolocalisation désactivées définitivement',
        );
      }

      Position? position;

      // Essayer d'abord la position la plus récente (rapide)
      try {
        position = await Geolocator.getLastKnownPosition(
          forceAndroidLocationManager: false,
        );

        if (position != null && !_disposed) {
          final age = DateTime.now().difference(
            position.timestamp ?? DateTime.now(),
          );
          if (age.inMinutes < 5) {
            // Si moins de 5 minutes
            _handleLocationSuccess(position, isLastKnown: true);
          }
        }
      } catch (e) {
        debugPrint('Dernière position non disponible: $e');
      }

      // Ensuite, essayer d'obtenir une position actuelle avec timeout court
      if (!_disposed) {
        try {
          position = await _getCurrentPositionWithTimeout();
          if (position != null && !_disposed) {
            _handleLocationSuccess(position, isLastKnown: false);
            return;
          }
        } catch (e) {
          debugPrint('Position actuelle échouée: $e');
          // Ne pas considérer comme une erreur grave, continuer avec la dernière position connue
        }
      }

      // Si aucune position n'est disponible, utiliser la position par défaut
      if (_currentPosition == null && !_disposed) {
        _safeSetState(() {
          _error =
              'Impossible d\'obtenir la position. Utilisation de la position par défaut.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!_disposed) {
        String errorMessage = _getLocationErrorMessage(e);
        _safeSetState(() {
          _error = errorMessage;
          _isLoading = false;
        });
      }
    } finally {
      _isGettingLocation = false;
    }
  }

  // Obtenir la position avec timeout personnalisé
  Future<Position?> _getCurrentPositionWithTimeout() async {
    return await Future.any([
      Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        forceAndroidLocationManager: false,
      ),
      Future.delayed(const Duration(seconds: 5)).then((_) => null),
    ]).timeout(const Duration(seconds: 8), onTimeout: () => null);
  }

  void _handleLocationSuccess(Position position, {bool isLastKnown = false}) {
    if (_disposed) return;

    _safeSetState(() {
      _currentPosition = position;
      _isLoading = false;
      if (isLastKnown) {
        _error =
            'Position récente utilisée (${DateTime.now().difference(position.timestamp ?? DateTime.now()).inMinutes} min)';
      } else {
        _error = null;
      }
    });

    _addPositionToHistory(
      position,
      label: isLastKnown ? 'Position récente' : 'Position actuelle',
    );
    _updateMarkers();

    // Centrer la carte avec un délai pour éviter les problèmes de timing
    if (_mapReady) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_disposed && _mapReady) {
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            _defaultZoom,
          );
        }
      });
    }

    // Effacer le message d'erreur après 3 secondes si c'est juste informatif
    if (isLastKnown) {
      Future.delayed(const Duration(seconds: 3), () {
        if (!_disposed && _error?.contains('Position récente') == true) {
          _safeSetState(() {
            _error = null;
          });
        }
      });
    }
  }

  String _getLocationErrorMessage(dynamic error) {
    if (error is LocationServiceDisabledException) {
      return 'Services de géolocalisation désactivés. Activez-les dans les paramètres.';
    } else if (error is PermissionDeniedException) {
      return 'Permission de géolocalisation refusée.';
    } else if (error is TimeoutException) {
      return 'Délai d\'attente dépassé pour obtenir la position.';
    } else if (error.toString().contains('Permission')) {
      return 'Permission de géolocalisation requise.';
    } else {
      return 'Erreur de géolocalisation. Vérifiez votre connexion.';
    }
  }

  Future<void> _loadPositionHistory() async {
    if (_isProcessingHistory || _disposed) return;

    try {
      _isProcessingHistory = true;
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('position_history');

      if (historyJson != null && !_disposed) {
        final List<dynamic> historyList = json.decode(historyJson);
        final history =
            historyList
                .map((item) => PositionHistory.fromJson(item))
                .take(_maxHistoryPoints)
                .toList();

        if (!_disposed) {
          _safeSetState(() {
            _positionHistory = history;
          });
          _updateMarkers();
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de l\'historique: $e');
    } finally {
      _isProcessingHistory = false;
    }
  }

  Future<void> _savePositionHistory() async {
    try {
      if (_disposed || _isProcessingHistory) return;

      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(
        _positionHistory.map((item) => item.toJson()).toList(),
      );
      await prefs.setString('position_history', historyJson);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde: $e');
    }
  }

  void _addPositionToHistory(Position position, {String? label}) {
    if (_disposed || _isProcessingHistory) return;

    final historyItem = PositionHistory(
      position: LatLng(position.latitude, position.longitude),
      timestamp: DateTime.now(),
      accuracy: position.accuracy,
      label: label,
    );

    // Éviter les doublons proches
    if (_positionHistory.isNotEmpty) {
      final lastPosition = _positionHistory.first;
      final distance = Geolocator.distanceBetween(
        lastPosition.position.latitude,
        lastPosition.position.longitude,
        position.latitude,
        position.longitude,
      );

      if (distance < 10.0) return; // Ignorer si moins de 10 mètres
    }

    _safeSetState(() {
      _positionHistory.insert(0, historyItem);
      if (_positionHistory.length > _maxHistoryPoints) {
        _positionHistory = _positionHistory.take(_maxHistoryPoints).toList();
      }
    });

    _updateMarkers();

    // Sauvegarde asynchrone non-bloquante
    Future.delayed(const Duration(seconds: 1), _savePositionHistory);
  }

  void _toggleTracking() {
    if (_disposed) return;

    _safeSetState(() {
      _trackingEnabled = !_trackingEnabled;
    });

    if (_trackingEnabled) {
      _startPeriodicTracking();
    } else {
      _trackingTimer?.cancel();
    }
  }

  void _startPeriodicTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      _getCurrentLocationForTracking();
    });
  }

  Future<void> _getCurrentLocationForTracking() async {
    if (_disposed || _isGettingLocation) return;

    try {
      final position = await _getCurrentPositionWithTimeout();

      if (position != null && !_disposed) {
        _addPositionToHistory(position, label: 'Auto-tracking');
      }
    } catch (e) {
      debugPrint('Erreur lors du suivi automatique: $e');
    }
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity().timeout(
        const Duration(seconds: 3),
        onTimeout: () => ConnectivityResult.none,
      );

      if (_disposed) return;

      _safeSetState(() {
        _connectionStatus = result;
        _isOffline = result == ConnectivityResult.none;
      });

      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
        ConnectivityResult result,
      ) {
        if (!_disposed) {
          _safeSetState(() {
            _connectionStatus = result;
            _isOffline = result == ConnectivityResult.none;
          });
        }
      });
    } catch (e) {
      debugPrint('Erreur de connectivité: $e');
      if (!_disposed) {
        _safeSetState(() {
          _isOffline = true;
        });
      }
    }
  }

  void _updateMarkers() {
    if (_disposed) return;

    final markers = <Marker>[];
    final polylines = <Polyline>[];

    // Marqueur de position actuelle
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
        ),
      );
    }

    // Marqueurs d'historique
    if (_showHistory && _positionHistory.isNotEmpty) {
      final visibleHistory = _positionHistory.take(15).toList();

      for (int i = 0; i < visibleHistory.length; i++) {
        final historyItem = visibleHistory[i];
        markers.add(
          Marker(
            point: historyItem.position,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: i == 0 ? Colors.red : Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
        );
      }
      
    }

    _cachedMarkers = markers;
    _cachedPolylines = polylines;
  }

  void _centerOnCurrentLocation() async {
    if (_mapReady && !_disposed) {
      if (_currentPosition != null) {
        _mapController.move(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          _defaultZoom,
        );
      } else {
        // Essayer d'obtenir une nouvelle position
        _getCurrentLocationWithFallback();
      }
    }
  }

  void _toggleOfflineMode() {
    if (_disposed) return;

    _safeSetState(() {
      _offlineModeEnabled = !_offlineModeEnabled;
    });
  }

  void _centerOnHistoryPosition(PositionHistory historyItem) {
    if (_mapReady && !_disposed) {
      _mapController.move(historyItem.position, _defaultZoom);
      Navigator.pop(context);
    }
  }

  void _deleteHistoryItem(int index) {
    if (_disposed) return;

    _safeSetState(() {
      _positionHistory.removeAt(index);
    });
    _updateMarkers();
    _savePositionHistory();
  }

  void _clearHistory() {
    if (_disposed) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer'),
            content: const Text('Voulez-vous supprimer tout l\'historique ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  _safeSetState(() {
                    _positionHistory.clear();
                  });
                  _updateMarkers();
                  _savePositionHistory();
                  Navigator.pop(context);
                },
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildHistoryModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Historique des positions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    if (_positionHistory.isNotEmpty)
                      IconButton(
                        onPressed: _clearHistory,
                        icon: const Icon(
                          Icons.delete_sweep,
                          color: Colors.white,
                        ),
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _positionHistory.isEmpty
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Aucun historique disponible',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _positionHistory.length,
                      itemBuilder: (context, index) {
                        final historyItem = _positionHistory[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.cyanAccent,
                            radius: 16,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            historyItem.label ?? 'Position inconnue',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${historyItem.position.latitude.toStringAsFixed(4)}, ${historyItem.position.longitude.toStringAsFixed(4)}',
                              ),
                              Text(
                                '${historyItem.timestamp.day}/${historyItem.timestamp.month} ${historyItem.timestamp.hour}:${historyItem.timestamp.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.location_on,
                                  color: Colors.cyanAccent,
                                ),
                                onPressed:
                                    () => _centerOnHistoryPosition(historyItem),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteHistoryItem(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (_offlineModeEnabled) {
      statusColor = Colors.orange;
      statusText = 'Hors ligne';
      statusIcon = Icons.cloud_off;
    } else if (_isOffline) {
      statusColor = Colors.red;
      statusText = 'Hors ligne';
      statusIcon = Icons.signal_wifi_off;
    } else {
      statusColor = Colors.green;
      statusText = 'En ligne';
      statusIcon = Icons.cloud_done;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _toggleTracking,
            icon: Icon(
              _trackingEnabled ? Icons.gps_fixed : Icons.gps_not_fixed,
              color: _trackingEnabled ? Colors.red : Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => _buildHistoryModal(),
              );
            },
            icon: Stack(
              children: [
                const Icon(Icons.history),
                if (_positionHistory.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_positionHistory.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: _getCurrentLocationWithFallback,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _currentPosition != null
                      ? LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      )
                      : _defaultCenter,
              initialZoom: _defaultZoom,
              maxZoom: 18.0,
              onMapReady: () {
                if (!_disposed) {
                  _safeSetState(() {
                    _mapReady = true;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.speedy.speedy',
              ),

              if (_cachedMarkers != null) MarkerLayer(markers: _cachedMarkers!),

              if (_cachedPolylines != null)
                PolylineLayer(polylines: _cachedPolylines!),
            ],
          ),

          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.cyanAccent),
                    SizedBox(height: 16),
                    Text(
                      'Obtention de votre position...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          if (_error != null)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Card(
                color: _error!.contains('récente') ? Colors.orange : Colors.red,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        _error!.contains('récente')
                            ? Icons.info
                            : Icons.warning,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _safeSetState(() => _error = null),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            top: 16,
            left: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  onPressed: _toggleOfflineMode,
                  backgroundColor:
                      _offlineModeEnabled ? Colors.orange : Colors.grey,
                  heroTag: 'offline',
                  child: Icon(
                    _offlineModeEnabled ? Icons.cloud_off : Icons.cloud,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  onPressed: () {
                    _safeSetState(() {
                      _showHistory = !_showHistory;
                    });
                    _updateMarkers();
                  },
                  backgroundColor: _showHistory ? Colors.green : Colors.grey,
                  heroTag: 'history',
                  child: Icon(
                    _showHistory ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ],
            ),
          ),

          Positioned(top: 16, right: 16, child: _buildConnectionStatus()),

          if (_currentPosition != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.black87,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.cyanAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Position: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.history,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Historique: ${_positionHistory.length} position(s)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          if (_trackingEnabled)
                            const Row(
                              children: [
                                Icon(
                                  Icons.gps_fixed,
                                  color: Colors.red,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Suivi actif',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 30,
            right: 16,
            child: FloatingActionButton(
              onPressed: _centerOnCurrentLocation,
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
              heroTag: 'center',
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
