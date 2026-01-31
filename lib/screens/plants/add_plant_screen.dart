import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/matero_service.dart';

class AddPlantScreen extends StatefulWidget {
  final Map<String, dynamic>? plant;

  const AddPlantScreen({super.key, this.plant});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final MateroService _materoService = MateroService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _imageUrlController;
  late TextEditingController _descriptionController;

  File? _selectedImageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plant?['name'] ?? '');
    _imageUrlController =
        TextEditingController(text: widget.plant?['image_url'] ?? '');
    _descriptionController =
        TextEditingController(text: widget.plant?['description'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
          // Clear URL controller to prioritize file upload, or keep it as fallback?
          // We will update the URL controller AFTER upload.
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<void> _savePlant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Upload new image if selected
      if (_selectedImageFile != null) {
        final uploadedUrl =
            await _materoService.uploadPlantImage(_selectedImageFile!);
        _imageUrlController.text = uploadedUrl;
      }

      // 2. Save/Update Plant
      if (widget.plant == null) {
        // Create
        await _materoService.addPlant(
          _nameController.text.trim(),
          _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('✅ Planta agregada correctamente'),
                backgroundColor: Colors.green),
          );
        }
      } else {
        // Update
        await _materoService.updatePlant(
          widget.plant!['id'],
          _nameController.text.trim(),
          _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('✅ Planta actualizada correctamente'),
                backgroundColor: Colors.green),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to trigger refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.plant != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Planta 🌱' : 'Agregar nueva planta 🌱'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                isEditing
                    ? 'Actualizar datos de tu planta'
                    : 'Dale un nombre a tu planta 🌱',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Image Preview Area
              Center(
                child: GestureDetector(
                  onTap: () => _showImageSourceModal(context),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      image: _selectedImageFile != null
                          ? DecorationImage(
                              image: FileImage(_selectedImageFile!),
                              fit: BoxFit.cover,
                            )
                          : (_imageUrlController.text.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(_imageUrlController.text),
                                  fit: BoxFit.cover,
                                )
                              : null),
                    ),
                    child: _selectedImageFile == null &&
                            _imageUrlController.text.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_a_photo,
                                  size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Toca para agregar foto',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la planta',
                  hintText: 'Ej. Orquídea, Bonsai...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_florist),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (Opcional)',
                  hintText: 'Ej. Regar cada 3 días, luz indirecta...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Optional URL field (hidden or secondary if image is picked)
              ExpansionTile(
                title: const Text('Ingresar URL manualmente'),
                children: [
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL de la imagen',
                      hintText: 'https://...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                    onChanged: (val) => setState(() {}), // Update preview
                  ),
                ],
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _savePlant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEditing ? 'ACTUALIZAR PLANTA' : 'GUARDAR PLANTA'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Cámara'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
