import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final dio = Dio();
  List logs = [];
  String get url => kIsWeb ? 'http://localhost:3000/api/transactions' : 'http://10.0.2.2:3000/api/transactions';

  @override
  void initState() { super.initState(); fetch(); }

  Future<void> fetch() async {
    final res = await dio.get(url);
    setState(() => logs = res.data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Laporan Penjualan"), backgroundColor: Colors.purple),
      body: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (ctx, i) => ListTile(
          title: Text(logs[i]['namaBuah']),
          subtitle: Text("Terjual: ${logs[i]['jumlah']} | Total: Rp ${logs[i]['totalHarga']}"),
          trailing: Text(logs[i]['tanggal'].toString().substring(0, 10)),
        ),
      ),
    );
  }
}