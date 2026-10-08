import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TrazosApp());
}

// ============================================================
// MODELO DE OBRA
// ============================================================

class Obra {
  final String id;
  final String titulo;
  final String descripcion;
  final String categoria;
  final String imagenBase64;

  Obra({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    required this.imagenBase64,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'categoria': categoria,
      'imagenBase64': imagenBase64,
    };
  }

  factory Obra.fromJson(Map<String, dynamic> json) {
    return Obra(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      categoria: json['categoria'] ?? 'Pintura',
      imagenBase64: json['imagenBase64'] ?? '',
    );
  }
}

// ============================================================
// APP
// ============================================================

class TrazosApp extends StatelessWidget {
  const TrazosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TRAZOS',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F1EC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC9784A),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const TrazosHome(),
    );
  }
}

// ============================================================
// HOME PRINCIPAL
// ============================================================

class TrazosHome extends StatefulWidget {
  const TrazosHome({super.key});

  @override
  State<TrazosHome> createState() => _TrazosHomeState();
}

class _TrazosHomeState extends State<TrazosHome> {
  int _currentIndex = 0;

  bool _cargando = true;

  List<Obra> _obras = [];

  String _nombre = 'Jesús';
  String _usuario = '@artista';
  String _bio = 'Todavía no agregaste una biografía.';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // ==========================================================
  // CARGAR DATOS
  // ==========================================================

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();

    final nombre = prefs.getString('perfil_nombre');
    final usuario = prefs.getString('perfil_usuario');
    final bio = prefs.getString('perfil_bio');

    final obrasGuardadas = prefs.getString('obras');

    List<Obra> obras = [];

    if (obrasGuardadas != null && obrasGuardadas.isNotEmpty) {
      try {
        final List<dynamic> lista = jsonDecode(obrasGuardadas);

        obras = lista.map((item) {
          return Obra.fromJson(item);
        }).toList();
      } catch (_) {
        obras = [];
      }
    }

    if (!mounted) return;

    setState(() {
      _nombre = nombre ?? 'Jesús';
      _usuario = usuario ?? '@artista';
      _bio = bio ?? 'Todavía no agregaste una biografía.';
      _obras = obras;
      _cargando = false;
    });
  }

  // ==========================================================
  // GUARDAR PERFIL
  // ==========================================================

  Future<void> _guardarPerfil(
    String nombre,
    String usuario,
    String bio,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('perfil_nombre', nombre);
    await prefs.setString('perfil_usuario', usuario);
    await prefs.setString('perfil_bio', bio);

    if (!mounted) return;

    setState(() {
      _nombre = nombre;
      _usuario = usuario;
      _bio = bio;
    });
  }

  // ==========================================================
  // PUBLICAR OBRA
  // ==========================================================

  Future<void> _agregarObra(Obra obra) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _obras = [..._obras, obra];
    });

    final datos = _obras.map((obra) {
      return obra.toJson();
    }).toList();

    await prefs.setString(
      'obras',
      jsonEncode(datos),
    );
  }

  // ==========================================================
  // ELIMINAR OBRA
  // ==========================================================

  Future<void> _eliminarObra(String id) async {
    setState(() {
      _obras.removeWhere(
        (obra) => obra.id == id,
      );
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'obras',
      jsonEncode(
        _obras.map((obra) {
          return obra.toJson();
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          InicioPage(
            obras: _obras,
          ),

          GaleriaPage(
            obras: _obras,
          ),

          PublicarPage(
            onPublicar: _agregarObra,
          ),

          PerfilPage(
            nombre: _nombre,
            usuario: _usuario,
            bio: _bio,
            obras: _obras,
            onGuardarPerfil: _guardarPerfil,
            onEliminarObra: _eliminarObra,
          ),
        ],
      ),

      // ========================================================
      // BARRA INFERIOR
      // ========================================================

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,

        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: 'Galería',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Publicar',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// INICIO
// ============================================================

class InicioPage extends StatelessWidget {
  final List<Obra> obras;

  const InicioPage({
    super.key,
    required this.obras,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TRAZOS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Descubrí nuevos TRAZOS.',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Una galería para descubrir artistas y obras locales.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Obras destacadas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            if (obras.isEmpty)
              _obraVacia()
            else
              SizedBox(
                height: 210,

                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: obras.length,

                  itemBuilder: (context, index) {
                    return _obraDestacada(
                      obras[index],
                    );
                  },
                ),
              ),

            const SizedBox(height: 30),

            const Text(
              'Categorías',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                _categoria(
                  'Pintura',
                  Icons.brush,
                ),

                const SizedBox(width: 10),

                _categoria(
                  'Dibujo',
                  Icons.edit,
                ),

                const SizedBox(width: 10),

                _categoria(
                  'Foto',
                  Icons.camera_alt,
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              'Artistas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                _artista('Artista 01'),

                const SizedBox(width: 12),

                _artista('Artista 02'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _obraVacia() {
    return Container(
      height: 180,
      width: double.infinity,

      decoration: BoxDecoration(
        color: const Color(0xFFE7E1D8),
        borderRadius: BorderRadius.circular(18),
      ),

      child: const Center(
        child: Text(
          'Todavía no hay obras publicadas',
          style: TextStyle(
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _obraDestacada(Obra obra) {
    final Uint8List bytes = base64Decode(
      obra.imagenBase64,
    );

    return Container(
      width: 190,

      margin: const EdgeInsets.only(
        right: 14,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),

      clipBehavior: Clip.antiAlias,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Expanded(
            child: Image.memory(
              bytes,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),

            child: Text(
              obra.titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,

              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoria(
    String nombre,
    IconData icono,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 18,
        ),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),

        child: Column(
          children: [
            Icon(icono),

            const SizedBox(height: 8),

            Text(nombre),
          ],
        ),
      ),
    );
  }

  Widget _artista(String nombre) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),

        child: Row(
          children: [
            const CircleAvatar(
              child: Icon(Icons.person),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                nombre,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// GALERÍA
// ============================================================

class GaleriaPage extends StatelessWidget {
  final List<Obra> obras;

  const GaleriaPage({
    super.key,
    required this.obras,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Galería',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: obras.isEmpty
          ? const Center(
              child: Text(
                'Todavía no hay obras publicadas.',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),

              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),

              itemCount: obras.length,

              itemBuilder: (context, index) {
                final obra = obras[index];

                return _tarjetaObra(
                  obra,
                );
              },
            ),
    );
  }

  Widget _tarjetaObra(Obra obra) {
    final bytes = base64Decode(
      obra.imagenBase64,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),

      clipBehavior: Clip.antiAlias,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Expanded(
            child: Image.memory(
              bytes,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  obra.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  obra.categoria,

                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PUBLICAR
// ============================================================

class PublicarPage extends StatefulWidget {
  final Future<void> Function(Obra obra) onPublicar;

  const PublicarPage({
    super.key,
    required this.onPublicar,
  });

  @override
  State<PublicarPage> createState() =>
      _PublicarPageState();
}

class _PublicarPageState
    extends State<PublicarPage> {
  final TextEditingController _tituloController =
      TextEditingController();

  final TextEditingController
      _descripcionController =
      TextEditingController();

  String _categoria = 'Pintura';

  Uint8List? _imagen;

  bool _publicando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();

    super.dispose();
  }

  // ==========================================================
  // SELECCIONAR IMAGEN
  // ==========================================================

  Future<void> _seleccionarImagen() async {
    final archivo = await FilePicker.pickFile(
      type: FileType.image,
    );

    if (archivo == null) {
      return;
    }

    final bytes = await archivo.readAsBytes();

    setState(() {
      _imagen = bytes;
    });
  }

  // ==========================================================
  // PUBLICAR
  // ==========================================================

  Future<void> _publicar() async {
    final titulo =
        _tituloController.text.trim();

    final descripcion =
        _descripcionController.text.trim();

    if (_imagen == null) {
      _mostrarMensaje(
        'Primero seleccioná una imagen.',
      );
      return;
    }

    if (titulo.isEmpty) {
      _mostrarMensaje(
        'Escribí el nombre de la obra.',
      );
      return;
    }

    setState(() {
      _publicando = true;
    });

    final obra = Obra(
      id: DateTime.now()
          .millisecondsSinceEpoch
          .toString(),

      titulo: titulo,

      descripcion: descripcion,

      categoria: _categoria,

      imagenBase64: base64Encode(
        _imagen!,
      ),
    );

    try {
      await widget.onPublicar(
        obra,
      );

      _tituloController.clear();
      _descripcionController.clear();

      setState(() {
        _imagen = null;
        _categoria = 'Pintura';
        _publicando = false;
      });

      if (!mounted) return;

      _mostrarMensaje(
        '¡Obra publicada correctamente!',
      );
    } catch (_) {
      setState(() {
        _publicando = false;
      });

      _mostrarMensaje(
        'No se pudo publicar la obra.',
      );
    }
  }

  void _mostrarMensaje(
    String mensaje,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Publicar obra',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ==================================================
            // IMAGEN
            // ==================================================

            GestureDetector(
              onTap: _seleccionarImagen,

              child: Container(
                height: 280,
                width: double.infinity,

                decoration: BoxDecoration(
                  color:
                      const Color(0xFFE7E1D8),
                  borderRadius:
                      BorderRadius.circular(20),
                ),

                clipBehavior:
                    Clip.antiAlias,

                child: _imagen == null
                    ? const Column(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,

                        children: [
                          Icon(
                            Icons
                                .add_photo_alternate_outlined,
                            size: 50,
                          ),

                          SizedBox(height: 12),

                          Text(
                            'Agregar imagen',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            'Tocá para seleccionar una imagen',
                          ),
                        ],
                      )
                    : Image.memory(
                        _imagen!,
                        width:
                            double.infinity,
                        height:
                            double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // TÍTULO
            // ==================================================

            const Text(
              'Nombre de la obra',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller:
                  _tituloController,

              decoration:
                  const InputDecoration(
                hintText:
                    'Ejemplo: Mi obra',
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // DESCRIPCIÓN
            // ==================================================

            const Text(
              'Descripción',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller:
                  _descripcionController,

              maxLines: 4,

              decoration:
                  const InputDecoration(
                hintText:
                    'Contá algo sobre tu obra...',
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // CATEGORÍA
            // ==================================================

            const Text(
              'Categoría',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: _categoria,

              decoration:
                  const InputDecoration(),

              items: const [
                DropdownMenuItem(
                  value: 'Pintura',
                  child: Text(
                    'Pintura',
                  ),
                ),

                DropdownMenuItem(
                  value: 'Dibujo',
                  child: Text(
                    'Dibujo',
                  ),
                ),

                DropdownMenuItem(
                  value: 'Fotografía',
                  child: Text(
                    'Fotografía',
                  ),
                ),
              ],

              onChanged: (valor) {
                if (valor == null) {
                  return;
                }

                setState(() {
                  _categoria = valor;
                });
              },
            ),

            const SizedBox(height: 30),

            // ==================================================
            // BOTÓN PUBLICAR
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(
                onPressed: _publicando
                    ? null
                    : _publicar,

                child: _publicando
                    ? const SizedBox(
                        width: 22,
                        height: 22,

                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Publicar obra',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PERFIL
// ============================================================

class PerfilPage extends StatefulWidget {
  final String nombre;
  final String usuario;
  final String bio;
  final List<Obra> obras;

  final Future<void> Function(
    String nombre,
    String usuario,
    String bio,
  ) onGuardarPerfil;

  final Future<void> Function(
    String id,
  ) onEliminarObra;

  const PerfilPage({
    super.key,
    required this.nombre,
    required this.usuario,
    required this.bio,
    required this.obras,
    required this.onGuardarPerfil,
    required this.onEliminarObra,
  });

  @override
  State<PerfilPage> createState() =>
      _PerfilPageState();
}

class _PerfilPageState
    extends State<PerfilPage> {
  bool _editando = false;

  late TextEditingController
      _nombreController;

  late TextEditingController
      _usuarioController;

  late TextEditingController
      _bioController;

  @override
  void initState() {
    super.initState();

    _crearControllers();
  }

  void _crearControllers() {
    _nombreController =
        TextEditingController(
      text: widget.nombre,
    );

    _usuarioController =
        TextEditingController(
      text: widget.usuario,
    );

    _bioController =
        TextEditingController(
      text: widget.bio,
    );
  }

  @override
  void didUpdateWidget(
    covariant PerfilPage oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (!_editando) {
      _nombreController.text =
          widget.nombre;

      _usuarioController.text =
          widget.usuario;

      _bioController.text =
          widget.bio;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _usuarioController.dispose();
    _bioController.dispose();

    super.dispose();
  }

  // ==========================================================
  // GUARDAR PERFIL
  // ==========================================================

  Future<void> _guardar() async {
    final nombre =
        _nombreController.text.trim();

    final usuario =
        _usuarioController.text.trim();

    final bio =
        _bioController.text.trim();

    await widget.onGuardarPerfil(
      nombre.isEmpty
          ? 'Jesús'
          : nombre,

      usuario.isEmpty
          ? '@artista'
          : usuario,

      bio.isEmpty
          ? 'Todavía no agregaste una biografía.'
          : bio,
    );

    if (!mounted) return;

    setState(() {
      _editando = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Perfil guardado correctamente.',
        ),
      ),
    );
  }

  void _cancelar() {
    _nombreController.text =
        widget.nombre;

    _usuarioController.text =
        widget.usuario;

    _bioController.text =
        widget.bio;

    setState(() {
      _editando = false;
    });
  }

  // ==========================================================
  // ELIMINAR OBRA
  // ==========================================================

  Future<void> _confirmarEliminar(
    Obra obra,
  ) async {
    final confirmar =
        await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Eliminar obra',
          ),

          content: Text(
            '¿Querés eliminar "${obra.titulo}"?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },

              child: const Text(
                'Cancelar',
              ),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },

              child: const Text(
                'Eliminar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    await widget.onEliminarObra(
      obra.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Obra eliminada correctamente.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            // ==================================================
            // AVATAR
            // ==================================================

            const CircleAvatar(
              radius: 55,
              backgroundColor:
                  Color(0xFFE1D7CC),

              child: Icon(
                Icons.person,
                size: 55,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 15),

            if (!_editando) ...[
              // =================================================
              // PERFIL NORMAL
              // =================================================

              Text(
                widget.nombre,

                style: const TextStyle(
                  fontSize: 25,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                widget.usuario,

                style: TextStyle(
                  color:
                      Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 15),

              Text(
                widget.bio,
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,

                child:
                    OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _editando = true;
                    });
                  },

                  child: const Text(
                    'Editar perfil',
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Align(
                alignment:
                    Alignment.centerLeft,

                child: Text(
                  'Mis obras',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              if (widget.obras.isEmpty)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(
                    25,
                  ),

                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),

                  child: const Text(
                    'Todavía no publicaste ninguna obra.',
                    textAlign:
                        TextAlign.center,
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,

                  physics:
                      const NeverScrollableScrollPhysics(),

                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.78,
                  ),

                  itemCount:
                      widget.obras.length,

                  itemBuilder:
                      (context, index) {
                    final obra =
                        widget.obras[index];

                    return _obraPerfil(
                      obra,
                    );
                  },
                ),
            ] else ...[
              // =================================================
              // EDITAR PERFIL
              // =================================================

              const Align(
                alignment:
                    Alignment.centerLeft,

                child: Text(
                  'Editar perfil',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller:
                    _nombreController,

                decoration:
                    const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Jesús',
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller:
                    _usuarioController,

                decoration:
                    const InputDecoration(
                  labelText: 'Usuario',
                  hintText: '@artista',
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller:
                    _bioController,

                maxLines: 4,

                decoration:
                    const InputDecoration(
                  labelText: 'Biografía',
                  hintText:
                      'Contá algo sobre vos...',
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,

                child:
                    ElevatedButton(
                  onPressed: _guardar,

                  child: const Text(
                    'Guardar',
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 50,

                child:
                    OutlinedButton(
                  onPressed: _cancelar,

                  child: const Text(
                    'Cancelar',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // TARJETA DE OBRA EN PERFIL
  // ==========================================================

  Widget _obraPerfil(
    Obra obra,
  ) {
    final bytes =
        base64Decode(
      obra.imagenBase64,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(15),
      ),

      clipBehavior:
          Clip.antiAlias,

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Expanded(
            child: Image.memory(
              bytes,
              width:
                  double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              8,
              6,
              4,
              4,
            ),

            child: Row(
              children: [
                Expanded(
                  child: Text(
                    obra.titulo,

                    maxLines: 1,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                IconButton(
                  tooltip:
                      'Eliminar obra',

                  icon: const Icon(
                    Icons
                        .delete_outline,
                    size: 21,
                  ),

                  onPressed: () {
                    _confirmarEliminar(
                      obra,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}