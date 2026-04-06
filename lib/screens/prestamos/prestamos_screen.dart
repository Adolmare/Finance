import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/clientes_provider.dart';
import '../../providers/prestamos_provider.dart';
import 'package:intl/intl.dart';

class PrestamosScreen extends StatefulWidget {
  const PrestamosScreen({super.key});

  @override
  State<PrestamosScreen> createState() => _PrestamosScreenState();
}

class _PrestamosScreenState extends State<PrestamosScreen> {
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientesProvider>().loadClientes();
      context.read<PrestamosProvider>().loadPrestamos();
    });
  }

  void _mostrarDialogoEditarCliente(BuildContext context, dynamic cliente) {
    String nombre = cliente.nombre;
    String telefono = cliente.telefono;
    String direccion = cliente.direccion;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Cliente"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Nombre Completo"),
                controller: TextEditingController(text: nombre),
                onChanged: (v) => nombre = v,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: "Teléfono"),
                keyboardType: TextInputType.phone,
                controller: TextEditingController(text: telefono),
                onChanged: (v) => telefono = v,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: "Dirección"),
                controller: TextEditingController(text: direccion),
                onChanged: (v) => direccion = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nombre.trim().isNotEmpty && telefono.trim().isNotEmpty) {
                final cModificado = cliente.copyWith(
                  nombre: nombre,
                  telefono: telefono,
                  direccion: direccion,
                );
                context.read<ClientesProvider>().actualizarCliente(cModificado);
                Navigator.pop(context);
              }
            },
            child: const Text("GUARDAR"),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminarCliente(BuildContext context, dynamic cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Cliente"),
        content: Text("¿Estás seguro de eliminar a ${cliente.nombre}? Se borrarán también todos sus préstamos y pagos de forma permanente."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              context.read<ClientesProvider>().eliminarCliente(cliente.id!);
              Navigator.pop(context);
            },
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoNuevoCliente(BuildContext context) {
    String nombre = '';
    String telefono = '';
    String direccion = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nuevo Cliente"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Nombre Completo"),
                onChanged: (v) => nombre = v,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: "Teléfono"),
                keyboardType: TextInputType.phone,
                onChanged: (v) => telefono = v,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: "Dirección"),
                onChanged: (v) => direccion = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nombre.trim().isNotEmpty && telefono.trim().isNotEmpty) {
                context.read<ClientesProvider>().agregarCliente(nombre, telefono, direccion);
                Navigator.pop(context);
              }
            },
            child: const Text("GUARDAR"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientesProvider = context.watch<ClientesProvider>();
    final prestamosProvider = context.watch<PrestamosProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cartera de Clientes"),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoNuevoCliente(context),
        icon: const Icon(Icons.person_add),
        label: const Text("Nuevo Cliente"),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text("Prestado", style: TextStyle(color: Colors.grey)),
                    Text(_currencyFormat.format(prestamosProvider.dineroTotalPrestado), 
                         style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                  ],
                ),
                Container(width: 1, height: 40, color: Colors.grey[700]),
                Column(
                  children: [
                    const Text("Recogido", style: TextStyle(color: Colors.grey)),
                    Text(_currencyFormat.format(prestamosProvider.dineroTotalRecogido), 
                         style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: clientesProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : clientesProvider.clientes.isEmpty
                    ? const Center(
                        child: Text(
                          "No hay clientes registrados.",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: clientesProvider.clientes.length,
                        itemBuilder: (context, index) {
                    final cliente = clientesProvider.clientes[index];
                    final deuda = prestamosProvider.deudaTotalActivaPorCliente(cliente.id!);
                    final activos = prestamosProvider.prestamosPorCliente(cliente.id!).where((p) => p.estado == 'ACTIVO').length;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      borderOnForeground: true,
                      elevation: 4,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pushNamed(context, '/detalle', arguments: cliente);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Text(
                                  cliente.nombre.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cliente.nombre,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Préstamos activos: $activos",
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _currencyFormat.format(deuda),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: deuda > 0 ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text("Deuda Total", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _mostrarDialogoEditarCliente(context, cliente);
                                  } else if (value == 'delete') {
                                    _confirmarEliminarCliente(context, cliente);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
