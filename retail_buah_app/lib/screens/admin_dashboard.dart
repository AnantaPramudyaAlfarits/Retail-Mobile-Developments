import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import '../models/product_model.dart';
import 'auth_screen.dart';
import 'report_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final dio = Dio();
  List<Product> products = [];
  List<Product> filteredProducts = [];
  
  // URL Server (Sesuaikan dengan IP kamu)
  String get baseUrl => kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
  String get productUrl => '$baseUrl/api/products';
  String get imageUrl => '$baseUrl/uploads/'; // Folder gambar di server

  // Variable untuk Image Picker
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() { super.initState(); fetch(); }

  Future<void> fetch() async {
    try {
      final res = await dio.get(productUrl);
      setState(() {
        products = (res.data as List).map((e) => Product.fromJson(e)).toList();
        filteredProducts = products;
      });
    } catch (e) { print(e); }
  }

  // Fungsi Pilih & Kompres Gambar
  Future<void> _pickImage(StateSetter setStateModal) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 25, // KOMPRESI: Turunkan kualitas ke 25% agar ringan
    );
    if (image != null) {
      setStateModal(() => _selectedImage = image); // Update UI dalam Dialog
    }
  }

  void _filter(String q) {
    setState(() => filteredProducts = products.where((p) => p.nama.toLowerCase().contains(q.toLowerCase())).toList());
  }

  void _showForm({Product? product}) {
    // Reset gambar saat buka form baru
    _selectedImage = null;
    
    final n = TextEditingController(text: product?.nama);
    final h = TextEditingController(text: product?.harga.toString());
    final s = TextEditingController(text: product?.stok.toString());

    showDialog(context: context, builder: (ctx) {
      return StatefulBuilder( // StatefulBuilder agar bisa update tampilan preview gambar di dialog
        builder: (context, setStateModal) {
          return AlertDialog(
            title: Text(product == null ? "Tambah Produk" : "Edit Produk"),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // PREVIEW GAMBAR
                GestureDetector(
                  onTap: () => _pickImage(setStateModal),
                  child: Container(
                    height: 100, width: 100,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                    child: _selectedImage != null
                        ? kIsWeb 
                            ? Image.network(_selectedImage!.path, fit: BoxFit.cover) // Preview Web
                            : Image.file(File(_selectedImage!.path), fit: BoxFit.cover) // Preview Mobile
                        : (product?.gambar != null && product!.gambar!.isNotEmpty)
                            ? Image.network('$imageUrl${product.gambar}', fit: BoxFit.cover)
                            : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 10),
                const Text("Ketuk kotak di atas untuk upload foto", style: TextStyle(fontSize: 12, color: Colors.grey)),
                
                TextField(controller: n, decoration: const InputDecoration(labelText: "Nama Buah")),
                TextField(controller: h, decoration: const InputDecoration(labelText: "Harga"), keyboardType: TextInputType.number),
                TextField(controller: s, decoration: const InputDecoration(labelText: "Stok Awal"), keyboardType: TextInputType.number),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
              ElevatedButton(onPressed: () async {
                // 1. SIAPKAN FORM DATA (MULTIPART)
                FormData formData = FormData.fromMap({
                  "nama": n.text,
                  "harga": h.text,
                  "stok": s.text,
                });

                // 2. CEK JIKA ADA GAMBAR BARU YG DIPILIH
                if (_selectedImage != null) {
                  // Teknik khusus agar jalan di Web & Mobile
                  final bytes = await _selectedImage!.readAsBytes();
                  formData.files.add(MapEntry(
                    "image", 
                    MultipartFile.fromBytes(bytes, filename: _selectedImage!.name)
                  ));
                }

                try {
                  if (product == null) {
                    await dio.post(productUrl, data: formData);
                  } else {
                    await dio.put('$productUrl/${product.id}', data: formData);
                  }
                  if (context.mounted) Navigator.pop(ctx);
                  fetch();
                } catch (e) {
                  print("Error upload: $e");
                }
              }, child: const Text("Simpan"))
            ],
          );
        }
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"), backgroundColor: Colors.red,
        actions: [
          IconButton(icon: const Icon(Icons.bar_chart), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()))),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()))),
        ],
      ),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(8), child: TextField(decoration: const InputDecoration(hintText: "Cari buah...", prefixIcon: Icon(Icons.search)), onChanged: _filter)),
          Expanded(
            child: ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (ctx, i) {
                final p = filteredProducts[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    // MENAMPILKAN GAMBAR DI LIST
                    leading: Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]),
                      child: (p.gambar != null && p.gambar!.isNotEmpty)
                          ? Image.network('$imageUrl${p.gambar}', fit: BoxFit.cover, errorBuilder: (c,o,s) => const Icon(Icons.error))
                          : const Icon(Icons.apple, color: Colors.red),
                    ),
                    title: Text(p.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Rp ${p.harga} | Stok: ${p.stok} kg"),
                    onTap: () => _showForm(product: p),
                    trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async { await dio.delete('$productUrl/${p.id}'); fetch(); }),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showForm(), child: const Icon(Icons.add)),
    );
  }
}