const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const app = express();

// 1. MIDDLEWARE
app.use(cors()); // Agar bisa diakses dari Flutter Web/Mobile
app.use(express.json()); // Agar bisa baca JSON
// Agar folder 'uploads' bisa diakses publik (contoh: http://localhost:3000/uploads/gbr.jpg)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// 2. CEK FOLDER UPLOADS
// Buat folder 'uploads' otomatis jika belum ada
const uploadDir = 'uploads';
if (!fs.existsSync(uploadDir)){
    fs.mkdirSync(uploadDir);
}

// 3. KONFIGURASI MULTER (UPLOAD GAMBAR)
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/'); // Simpan di folder uploads
  },
  filename: (req, file, cb) => {
    // Format nama file: timestamp + ekstensi asli (agar unik)
    cb(null, Date.now() + path.extname(file.originalname));
  }
});
const upload = multer({ storage: storage });

// 4. MODEL DATABASE
const User = mongoose.model('User', new mongoose.Schema({
  username: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['admin', 'staff'], default: 'staff' }
}));

const Product = mongoose.model('Product', new mongoose.Schema({
  nama: { type: String, required: true },
  harga: { type: Number, required: true },
  stok: { type: Number, required: true },
  gambar: { type: String, default: '' } // Field baru untuk nama file gambar
}, { timestamps: true }));

const Transaction = mongoose.model('Transaction', new mongoose.Schema({
  productId: mongoose.Schema.Types.ObjectId,
  namaBuah: String,
  jumlah: Number,
  totalHarga: Number,
  tanggal: { type: Date, default: Date.now }
}));

// 5. KONEKSI MONGODB
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('✅ Terhubung ke MongoDB'))
  .catch((err) => console.error('❌ Gagal Koneksi:', err));

const JWT_SECRET = 'rahasia_toko_buah_super_aman';

// ================= ROUTES =================

// --- AUTH ---
app.post('/api/auth/register', async (req, res) => {
  try {
    const { username, password, role } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = new User({ username, password: hashedPassword, role });
    await user.save();
    res.status(201).json({ message: "User berhasil dibuat" });
  } catch (err) {
    res.status(400).json({ message: "Username sudah ada" });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const user = await User.findOne({ username: req.body.username });
    if (!user || !(await bcrypt.compare(req.body.password, user.password))) {
      return res.status(401).json({ message: "Username/Password Salah" });
    }
    const token = jwt.sign({ id: user._id, role: user.role }, JWT_SECRET);
    res.json({ token, role: user.role, username: user.username });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// --- PRODUK (CRUD + GAMBAR) ---

// GET: Ambil semua produk
app.get('/api/products', async (req, res) => {
  const products = await Product.find().sort({ createdAt: -1 });
  res.json(products);
});

// POST: Tambah Produk (Support Upload Gambar)
app.post('/api/products', upload.single('image'), async (req, res) => {
  try {
    const { nama, harga, stok } = req.body;
    // req.file berisi info gambar yg diupload
    const gambar = req.file ? req.file.filename : ''; 

    const newProduct = new Product({ nama, harga, stok, gambar });
    await newProduct.save();
    res.status(201).json(newProduct);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// PUT: Update Produk (Bisa update gambar atau tidak)
app.put('/api/products/:id', upload.single('image'), async (req, res) => {
  try {
    const { nama, harga, stok } = req.body;
    let updateData = { nama, harga, stok };

    // Jika user upload gambar baru, update field gambarnya
    if (req.file) {
      updateData.gambar = req.file.filename;
    }

    const updated = await Product.findByIdAndUpdate(req.params.id, updateData, { new: true });
    res.json(updated);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// DELETE: Hapus Produk
app.delete('/api/products/:id', async (req, res) => {
  try {
    // Opsional: Bisa tambahkan logika untuk hapus file gambar dari folder 'uploads' juga disini
    await Product.findByIdAndDelete(req.params.id);
    res.json({ message: "Produk dihapus" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// --- TRANSAKSI (PENJUALAN) ---
app.post('/api/transactions', async (req, res) => {
  try {
    const { productId, jumlah } = req.body;
    const product = await Product.findById(productId);

    if (!product) return res.status(404).json({ message: "Produk tidak ditemukan" });
    if (product.stok < jumlah) return res.status(400).json({ message: "Stok tidak cukup" });

    // 1. Kurangi Stok
    product.stok -= jumlah;
    await product.save();

    // 2. Simpan Transaksi
    const trx = new Transaction({
      productId,
      namaBuah: product.nama,
      jumlah,
      totalHarga: product.harga * jumlah
    });
    await trx.save();

    res.status(201).json(trx);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.get('/api/transactions', async (req, res) => {
  const trxs = await Transaction.find().sort({ tanggal: -1 });
  res.json(trxs);
});

// 6. JALANKAN SERVER
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Server jalan di http://localhost:${PORT}`));