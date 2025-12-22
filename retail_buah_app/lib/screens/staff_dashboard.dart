import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:intl/intl.dart'; // Untuk format Rupiah
import '../models/product_model.dart';
import 'auth_screen.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});
  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  final dio = Dio();
  List<Product> products = [];
  List<Product> filteredProducts = [];
  TextEditingController searchController = TextEditingController();

  // Konfigurasi URL Server & Gambar
  String get baseUrl => kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
  String get productUrl => '$baseUrl/api/products';
  String get transactionUrl => '$baseUrl/api/transactions';
  String get imageUrl => '$baseUrl/uploads/';

  @override
  void initState() {
    super.initState();
    fetch();
  }

  // Ambil Data Produk
  Future<void> fetch() async {
    try {
      final res = await dio.get(productUrl);
      setState(() {
        products = (res.data as List).map((e) => Product.fromJson(e)).toList();
        filteredProducts = products;
      });
    } catch (e) {
      print("Gagal ambil data: $e");
    }
  }

  // Filter Pencarian
  void _filter(String query) {
    setState(() {
      filteredProducts = products.where((p) => 
        p.nama.toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  // Helper Format Rupiah
  String formatRupiah(int number) {
    return NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(number);
  }

  // Dialog Transaksi Jual
  void _showSellDialog(Product product) {
    final qtyController = TextEditingController(text: "1"); // Default 1 kg
    
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text("Jual ${product.nama}"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tampilkan Gambar Kecil di Dialog
          if (product.gambar != null && product.gambar!.isNotEmpty)
            Container(
              height: 100, width: 100,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage('$imageUrl${product.gambar}'),
                  fit: BoxFit.cover
                )
              ),
            ),
          Text("Stok Tersedia: ${product.stok} kg", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          TextField(
            controller: qtyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Jumlah (kg)",
              border: OutlineInputBorder(),
              suffixText: "kg"
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () async {
            final jumlah = int.tryParse(qtyController.text) ?? 0;
            if (jumlah <= 0) return; // Validasi sederhana
            if (jumlah > product.stok) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Stok tidak cukup!"), backgroundColor: Colors.red)
              );
              return;
            }
            
            await _processTransaction(product.id, jumlah);
            Navigator.pop(ctx);
          }, 
          child: const Text("KONFIRMASI JUAL", style: TextStyle(color: Colors.white))
        )
      ],
    ));
  }

  // Proses Kirim Data ke Backend
  Future<void> _processTransaction(String id, int jumlah) async {
    try {
      await dio.post(transactionUrl, data: {
        "productId": id,
        "jumlah": jumlah
      });
      fetch(); // Refresh data stok
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Berhasil menjual $jumlah kg!"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal transaksi!"), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Staff - Kasir", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushAndRemoveUntil(
              context, 
              MaterialPageRoute(builder: (_) => const AuthScreen()), 
              (r) => false
            )
          )
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Cari nama buah...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey[100]
              ),
              onChanged: _filter,
            ),
          ),
          
          // List Produk
          Expanded(
            child: filteredProducts.isEmpty 
              ? const Center(child: Text("Produk tidak ditemukan"))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: filteredProducts.length,
                  itemBuilder: (ctx, i) {
                    final p = filteredProducts[i];
                    final bool isLowStock = p.stok < 5; // Cek stok menipis

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            // 1. Gambar Produk
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 70, height: 70,
                                color: Colors.grey[200],
                                child: (p.gambar != null && p.gambar!.isNotEmpty)
                                  ? Image.network(
                                      '$imageUrl${p.gambar}', 
                                      fit: BoxFit.cover,
                                      errorBuilder: (c,o,s) => const Icon(Icons.broken_image, color: Colors.grey),
                                    )
                                  : const Icon(Icons.storefront, size: 30, color: Colors.blueGrey),
                              ),
                            ),
                            
                            const SizedBox(width: 15),

                            // 2. Detail Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.nama, 
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatRupiah(p.harga),
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  // Indikator Stok
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isLowStock ? Colors.red.shade100 : Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(4)
                                    ),
                                    child: Text(
                                      "Sisa Stok: ${p.stok} kg",
                                      style: TextStyle(
                                        color: isLowStock ? Colors.red : Colors.blue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),

                            // 3. Tombol Jual
                            ElevatedButton(
                              onPressed: p.stok > 0 ? () => _showSellDialog(p) : null, // Disable jika stok 0
                              style: ElevatedButton.styleFrom(
                                backgroundColor: p.stok > 0 ? Colors.blue : Colors.grey,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                              ),
                              child: const Text("JUAL", style: TextStyle(color: Colors.white)),
                            )
                          ],
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