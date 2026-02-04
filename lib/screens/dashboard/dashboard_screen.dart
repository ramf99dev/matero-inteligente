import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/plant.dart';
import '../../models/sensor_reading.dart';
import '../../services/matero_service.dart';
import '../../config/constants.dart';
import '../plants/add_plant_screen.dart';
import '../devices/qr_scanner_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MateroService _materoService = MateroService();

  List<Plant> _plants = [];
  Plant? _selectedPlant;
  bool _isLoadingPlants = true;

  SensorReading? _currentSensorData;

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  //CARGA DE PLANTAS
  Future<void> _loadPlants() async {
    setState(() => _isLoadingPlants = true);
    try {
      final plants = await _materoService.getPlants();
      setState(() {
        _plants = plants;
        if (_plants.isNotEmpty) {
          // Si ya había una seleccionada, intentamos mantenerla
          if (_selectedPlant != null) {
            _selectedPlant = _plants.firstWhere(
                (p) => p.id == _selectedPlant!.id,
                orElse: () => _plants.first);
          } else {
            _selectedPlant = _plants.first;
          }
        } else {
          _selectedPlant = null;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando plantas: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingPlants = false);
    }
  }

  // CONFIGURAR WIFI (WiFiManager)
  Future<void> _openWifiSetup() async {
    final Uri url = Uri.parse(PlantThresholds.wifiSetupURL);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Conectar Matero a Wi-Fi"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("1. Ve a la configuración Wi-Fi de tu celular."),
            SizedBox(height: 8),
            Text("2. Conéctate a la red '${PlantThresholds.wifiSetupSSID}'."),
            SizedBox(height: 8),
            Text("3. Vuelve aquí y presiona 'Configurar'."),
            SizedBox(height: 8),
            Text(
                "4. Ingresa tu red WiFi y contraseña en la página que se abre."),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                if (mounted) {
                  _showTopNotification('No se pudo abrir el navegador',
                      const Color.fromARGB(255, 162, 37, 28));
                }
              }
            },
            child: const Text("Abrir Configuración"),
          ),
        ],
      ),
    );
  }

  Future<void> _waterPlant() async {
    if (_selectedPlant == null) return;

    try {
      await _materoService.waterPlant(_selectedPlant!.id!);
      if (mounted) {
        _showTopNotification('💧 Planta regada correctamente', Colors.blue);
        _loadPlants(); // Recargar para actualizar last_watered
      }
    } catch (e) {
      if (mounted) {
        _showTopNotification(
            '❌ Error al regar: $e', const Color.fromARGB(255, 152, 41, 33));
      }
    }
  }

  void _showTopNotification(String message, Color color) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(
        Duration(milliseconds: PlantThresholds.notificationDurationMs), () {
      overlayEntry.remove();
    });
  }

  String get _currentRecommendation {
    if (_currentSensorData == null) return 'Esperando datos...';
    return _materoService.getRecommendation(
      _currentSensorData!.soilMoisture,
      _currentSensorData!.temperature,
    );
  }

  Color get _recommendationColor {
    final recommendation = _currentRecommendation;
    if (recommendation.contains('🚨')) {
      return Colors.red;
    }
    if (recommendation.contains('💧') || recommendation.contains('⚠️')) {
      return Colors.orange;
    }
    return Colors.green;
  }

  void _navigateToAddPlant() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPlantScreen()),
    );
    if (result == true) {
      _loadPlants();
    }
  }

  void _editPlant(Plant plant) async {
    // Convertir Plant a Map para compatibilidad con AddPlantScreen
    final plantMap = {
      'id': plant.id,
      'name': plant.name,
      'image_url': plant.imageUrl,
      'description': plant.description,
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddPlantScreen(plant: plantMap)),
    );
    if (result == true) {
      _loadPlants();
    }
  }

  void _confirmDeletePlant(Plant plant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Planta'),
        content: Text('¿Estás seguro de que quieres eliminar "${plant.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePlant(plant.id!);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePlant(int id) async {
    try {
      await _materoService.deletePlant(id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Planta eliminada')),
      );

      setState(() {
        _plants.removeWhere((p) => p.id == id);
        if (_selectedPlant?.id == id) {
          _selectedPlant = _plants.isNotEmpty ? _plants.first : null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error eliminando: $e')),
      );
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = date.difference(today).inDays;

    if (diff == 0) {
      return 'Hoy ${DateFormat('HH:mm').format(dt)}';
    }
    if (diff == 1) {
      return 'Mañana';
    }
    if (diff == -1) {
      return 'Ayer';
    }
    return DateFormat('d/MM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        backgroundColor: const Color.fromARGB(255, 42, 126, 45),
        foregroundColor: const Color.fromARGB(255, 237, 235, 235),
        elevation: 2,
        actions: [
          // BOTON PARA CONFIGURAR WIFI
          IconButton(
            icon: const Icon(Icons.wifi_tethering),
            onPressed: _openWifiSetup,
            tooltip: 'Configurar Wi-Fi Matero',
          ),
          // BOTON PARA CERRAR SESIÓN
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: _isLoadingPlants
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _plants.isEmpty
              ? _buildEmptyState()
              : _buildDashboardContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPlant,
        backgroundColor: Colors.green,
        tooltip: 'Agregar Nueva Planta',
        child: const Icon(Icons.add, color: Color.fromARGB(255, 253, 249, 0)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_florist_outlined,
              size: 80, color: Color.fromARGB(255, 141, 140, 140)),
          const SizedBox(height: 20),
          const Text(
            '¡No tienes plantas registradas!',
            style: TextStyle(
                fontSize: 18, color: Color.fromARGB(255, 141, 140, 140)),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
              onPressed: _openWifiSetup,
              icon: const Icon(Icons.wifi),
              label: const Text("Configurar Wi-Fi del Dispositivo")),
          ElevatedButton.icon(
            onPressed: _navigateToAddPlant,
            icon: const Icon(Icons.add),
            label: const Text('Agregar mi primer Matero'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicator(
          onRefresh: _loadPlants,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Selector de Planta
                Card(
                  elevation: 2,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedPlant?.id,
                        isExpanded: true,
                        hint: const Text('Selecciona una planta'),
                        items: _plants.map((plant) {
                          return DropdownMenuItem<int>(
                            value: plant.id,
                            child: Row(
                              children: [
                                const Icon(Icons.local_florist,
                                    color: Colors.green),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    plant.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPlant =
                                _plants.firstWhere((p) => p.id == value);
                          });
                        },
                      ),
                    ),
                  ),
                ),

                // Información de la Planta (Imagen y Descripción)
                if (_selectedPlant != null) ...[
                  const SizedBox(height: 10),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          if (_selectedPlant!.imageUrl != null &&
                              _selectedPlant!.imageUrl!.isNotEmpty)
                            Container(
                              height: 150,
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image:
                                      NetworkImage(_selectedPlant!.imageUrl!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          if (_selectedPlant!.description != null &&
                              _selectedPlant!.description!.isNotEmpty)
                            Text(
                              _selectedPlant!.description!,
                              style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text('Editar'),
                                onPressed: () => _editPlant(_selectedPlant!),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.delete,
                                    size: 18, color: Colors.red),
                                label: const Text('Eliminar',
                                    style: TextStyle(color: Colors.red)),
                                onPressed: () =>
                                    _confirmDeletePlant(_selectedPlant!),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Tarjeta de Estado Actual con StreamBuilder
                if (_selectedPlant != null) _buildSensorDataCard(),

                const SizedBox(height: 20),

                // Tarjeta de Recomendación
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: _recommendationColor.withAlpha(25),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: _recommendationColor,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'RECOMENDACIÓN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentRecommendation,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: _recommendationColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Tarjeta de Riego
                if (_selectedPlant != null) _buildWateringCard(),

                const SizedBox(height: 20),

                // Información adicional
                Text(
                  'Última actualización: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                // Espacio extra para el FAB
                const SizedBox(height: 60),
              ],
            ),
          ),
        ));
  }

  void _linkDevice() async {
    if (_selectedPlant == null) return;
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QRScannerScreen()),
      );

      if (result != null) {
        await _materoService.linkDeviceToPlant(_selectedPlant!.id!, result);
        if (mounted) {
          _showTopNotification(
              "✅ Vinculado al dispositivo: $result", Colors.green);
          _loadPlants(); // Recargar para actualizar el device_id de la planta seleccionada
        }
      }
    } catch (e) {
      if (mounted) {
        _showTopNotification("❌ Error vinculando: $e", Colors.red);
      }
    }
  }

  // ... (existing methods)

  // StreamBuilder para datos en tiempo real
  Widget _buildSensorDataCard() {
    return StreamBuilder<SensorReading?>(
      stream: _materoService.getRealtimeData(_selectedPlant!.deviceId),
      builder: (context, snapshot) {
        final bool isLoading =
            snapshot.connectionState == ConnectionState.waiting;

        if (snapshot.hasData && snapshot.data != null) {
          _currentSensorData = snapshot.data;
        }

        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.sensors,
                          color: snapshot.hasData ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ESTADO EN VIVO',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: snapshot.hasData
                                  ? Colors.green
                                  : Colors.grey),
                        ),
                      ],
                    ),
                    if (isLoading)
                      const SizedBox(
                          height: 15,
                          width: 15,
                          child: CircularProgressIndicator(strokeWidth: 2))
                  ],
                ),
                const SizedBox(height: 20),
                if (_selectedPlant!.deviceId == null) ...[
                  Column(
                    children: [
                      const Icon(Icons.link_off,
                          size: 40, color: Colors.orange),
                      const SizedBox(height: 10),
                      const Text(
                        'Planta no vinculada a un Matero',
                        style: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _linkDevice,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Vincular Matero'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  )
                ] else if (_currentSensorData != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSensorCard(
                          '🌡️ Temp',
                          '${_currentSensorData!.temperature.toStringAsFixed(1)}°C',
                          Colors.orange,
                          Icons.thermostat),
                      _buildSensorCard(
                          '💧 Aire',
                          '${_currentSensorData!.humidity.toStringAsFixed(1)}%',
                          Colors.blue,
                          Icons.water_drop),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSensorCard(
                          '🌱 Suelo',
                          '${_currentSensorData!.soilMoisture}%',
                          Colors.brown,
                          Icons.grass),
                      _buildSensorCard(
                          '☀️ Luz',
                          '${_currentSensorData!.lightLevel}',
                          Colors.amber,
                          Icons.light_mode),
                    ],
                  ),
                ] else ...[
                  const Text(
                    'Esperando datos del ESP32...',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Asegúrate de que el dispositivo esté conectado y enviando datos.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSensorCard(
      String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(76)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWateringCard() {
    final lastWatered = _selectedPlant!.lastWatered;
    final nextWatering = _selectedPlant!.nextWatering;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'HISTORIAL DE RIEGO',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Último Riego',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 5),
                    Text(
                      lastWatered != null ? _formatDate(lastWatered) : 'Nunca',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Container(
                    width: 1, height: 40, color: Colors.grey.withAlpha(50)),
                Column(
                  children: [
                    const Text('Próximo Riego',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 5),
                    Text(
                      nextWatering != null ? _formatDate(nextWatering) : 'Hoy',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: (nextWatering != null &&
                                nextWatering.isBefore(DateTime.now()))
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _waterPlant,
              icon: const Icon(Icons.water_drop),
              label: const Text('REGAR HOY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
