import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/cliente.dart';
import '../../models/prestamo.dart';
import '../../models/pago.dart';
import '../../providers/prestamos_provider.dart';

class DetalleClienteScreen extends StatefulWidget {
  const DetalleClienteScreen({super.key});

  @override
  State<DetalleClienteScreen> createState() => _DetalleClienteScreenState();
}

class _DetalleClienteScreenState extends State<DetalleClienteScreen> {
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final _dateFormat = DateFormat('dd/MM/yyyy');

  Cliente? _cliente;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final params = ModalRoute.of(context)?.settings.arguments;
    if (params is Cliente) {
      _cliente = params;
    }
  }

  void _mostrarDialogoNuevoPrestamo(BuildContext context) {
    String montoStr = '';
    String semanasStr = '';
    String interesStr = '15.0'; // Valor sugerido

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Registrar Nuevo Préstamo", style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Monto a prestar",
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => montoStr = v,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Plazo",
                    suffixText: "semanas",
                    prefixIcon: const Icon(Icons.date_range),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => semanasStr = v,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Interés",
                    suffixText: "%",
                    prefixIcon: const Icon(Icons.percent),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  controller: TextEditingController(text: interesStr),
                  onChanged: (v) => interesStr = v,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final monto = double.tryParse(montoStr) ?? 0;
              final semanas = int.tryParse(semanasStr) ?? 0;
              final interes = double.tryParse(interesStr) ?? 15.0;

              if (monto > 0 && semanas > 0 && interes >= 0) {
                context.read<PrestamosProvider>().otorgarPrestamo(
                  clienteId: _cliente!.id!, 
                  monto: monto, 
                  interes: interes, 
                  semanas: semanas
                );
                Navigator.pop(context);
              }
            },
            child: const Text("GENERAR PLAN"),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoPagos(BuildContext context, Prestamo prestamo) async {
    final provider = context.read<PrestamosProvider>();
    List<Pago> pagos = await provider.obtenerPagosDePrestamo(prestamo.id!);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Cronograma de Pagos - Prestamo #${prestamo.id}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: pagos.length,
                        separatorBuilder: (c, i) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final p = pagos[index];
                          final bool isPagado = p.estado == 'PAGADO';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isPagado ? Colors.green.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
                              child: Icon(
                                isPagado ? Icons.check : Icons.warning_amber,
                                color: isPagado ? Colors.green : Colors.amber,
                                size: 20,
                              ),
                            ),
                            title: Text("Cuota ${p.numeroCuota}"),
                            subtitle: Text("Vence: ${_dateFormat.format(p.fechaVencimiento)}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currencyFormat.format(p.monto),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                if (!isPagado)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () async {
                                      await provider.registrarPago(p.id!, p.monto, p.prestamoId);
                                      // Refrescar modal
                                      final updated = await provider.obtenerPagosDePrestamo(p.prestamoId);
                                      setModalState(() {
                                        pagos = updated;
                                      });
                                    },
                                    child: const Text("PAGAR"),
                                  )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cliente == null) return const Scaffold(body: Center(child: Text("Error")));

    final prestamosProvider = context.watch<PrestamosProvider>();
    final misPrestamos = prestamosProvider.prestamosPorCliente(_cliente!.id!);

    return Scaffold(
      appBar: AppBar(
        title: Text(_cliente!.nombre),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoNuevoPrestamo(context),
        icon: const Icon(Icons.monetization_on),
        label: const Text("Nuevo Préstamo"),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: CustomScrollView(
            slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Información de Contacto", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16),
                          const SizedBox(width: 8),
                          Text(_cliente!.telefono, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 8),
                          Text(_cliente!.direccion, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text("Historial de Préstamos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          misPrestamos.isEmpty
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text("Este cliente no tiene préstamos registrados.", style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final prestamo = misPrestamos[index];
                      final bool isActivo = prestamo.estado == 'ACTIVO';
                      final double progreso = prestamo.totalPagado / prestamo.totalAPagar;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _mostrarDialogoPagos(context, prestamo),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        "Préstamo ${_currencyFormat.format(prestamo.monto)}",
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isActivo ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            prestamo.estado,
                                            style: TextStyle(
                                              color: isActivo ? Colors.green : Colors.grey,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (isActivo)
                                          IconButton(
                                            icon: const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                                            tooltip: 'Aplicar Mora/Multa',
                                            onPressed: () {
                                              String moraStr = '';
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text("Aplicar Mora/Recargo"),
                                                  content: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Text("Se creará una cuota extra con el monto de la multa al final del calendario de pagos."),
                                                      const SizedBox(height: 16),
                                                      TextField(
                                                        decoration: const InputDecoration(
                                                          labelText: "Monto de la multa",
                                                          prefixText: "\$ ",
                                                        ),
                                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                        onChanged: (v) => moraStr = v,
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: const Text("CANCELAR"),
                                                    ),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                                                      onPressed: () {
                                                        final mora = double.tryParse(moraStr) ?? 0;
                                                        if (mora > 0) {
                                                          context.read<PrestamosProvider>().aplicarMora(prestamo.id!, mora);
                                                          Navigator.pop(context);
                                                        }
                                                      },
                                                      child: const Text("APLICAR", style: TextStyle(color: Colors.black)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text("Eliminar Préstamo"),
                                                content: const Text("¿Estás seguro de eliminar este préstamo de manera permanente? Todas las cuotas generadas y los pagos también serán eliminados."),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text("CANCELAR"),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                                                    onPressed: () {
                                                      context.read<PrestamosProvider>().eliminarPrestamo(prestamo.id!);
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text("ELIMINAR", style: TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Total a Pagar: ${_currencyFormat.format(prestamo.totalAPagar)} (${prestamo.cuotas} cuotas)",
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Progreso", style: TextStyle(color: Colors.grey[400])),
                                    Text("${(progreso * 100).toStringAsFixed(1)}%"),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: progreso,
                                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Pagado", style: TextStyle(fontSize: 12)),
                                        Text(_currencyFormat.format(prestamo.totalPagado),
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text("Restante", style: TextStyle(fontSize: 12)),
                                        Text(_currencyFormat.format(prestamo.totalRestante),
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                                      ],
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: misPrestamos.length,
                  ),
                ),
        ],
          ),
        ),
      ),
    );
  }
}
