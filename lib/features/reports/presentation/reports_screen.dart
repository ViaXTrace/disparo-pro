import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        actions: [
          IconButton(icon: const Icon(Icons.download_outlined), tooltip: 'Exportar CSV', onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
        children: [
          _PeriodSelector(),
          const SizedBox(height: 16),
          _SummaryCards(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Envios por dia', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(height: 180, child: Center(child: Text('Gráfico disponível após primeiros disparos', style: TextStyle(color: Colors.grey)))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Taxa por canal', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _ChannelRow(channel: 'SMS', color: Colors.blue, sent: 0, delivered: 0),
                  _ChannelRow(channel: 'RCS', color: Colors.purple, sent: 0, delivered: 0),
                  _ChannelRow(channel: 'WhatsApp', color: Colors.green, sent: 0, delivered: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatefulWidget {
  @override
  State<_PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<_PeriodSelector> {
  String _period = '7d';
  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: '7d', label: Text('7 dias')),
        ButtonSegment(value: '30d', label: Text('30 dias')),
        ButtonSegment(value: '90d', label: Text('90 dias')),
        ButtonSegment(value: 'all', label: Text('Tudo')),
      ],
      selected: {_period},
      onSelectionChanged: (v) => setState(() => _period = v.first),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _Card(label: 'Total enviado', value: '0', icon: Icons.send, color: Colors.blue)),
      const SizedBox(width: 8),
      Expanded(child: _Card(label: 'Entregues', value: '0%', icon: Icons.check_circle, color: Colors.green)),
      const SizedBox(width: 8),
      Expanded(child: _Card(label: 'Falhas', value: '0%', icon: Icons.cancel, color: Colors.red)),
    ]);
  }
}

class _Card extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Card({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 6),
      Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
    ])));
  }
}

class _ChannelRow extends StatelessWidget {
  final String channel;
  final Color color;
  final int sent, delivered;
  const _ChannelRow({required this.channel, required this.color, required this.sent, required this.delivered});
  @override
  Widget build(BuildContext context) {
    final rate = sent == 0 ? 0.0 : delivered / sent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(channel, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text('${(rate * 100).toStringAsFixed(1)}% de entrega', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ]),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: rate, color: color, backgroundColor: color.withOpacity(0.15)),
      ]),
    );
  }
}
