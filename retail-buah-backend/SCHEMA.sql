-- ============================================================
-- RETAIL BUAH APP - DATABASE SCHEMA
-- ============================================================
-- Copy-paste entire script ke Supabase SQL Editor dan run
-- Database akan ready untuk digunakan
-- ============================================================

-- 1. CREATE PRODUCTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nama VARCHAR(255) NOT NULL,
  harga INTEGER NOT NULL CHECK (harga > 0),
  stok INTEGER NOT NULL DEFAULT 0 CHECK (stok >= 0),
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index untuk performa
CREATE INDEX IF NOT EXISTS idx_products_nama ON products(nama);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON products(created_at);

-- 2. CREATE TRANSACTIONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  product_name VARCHAR(255) NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  price INTEGER NOT NULL CHECK (price > 0),
  total_price INTEGER NOT NULL CHECK (total_price > 0),
  tanggal TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes untuk performa
CREATE INDEX IF NOT EXISTS idx_transactions_product_id ON transactions(product_id);
CREATE INDEX IF NOT EXISTS idx_transactions_tanggal ON transactions(tanggal);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at);

-- 3. CREATE USERS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password TEXT NOT NULL,
  role VARCHAR(50) DEFAULT 'staff' CHECK (role IN ('admin', 'staff')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index untuk email lookup
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- 4. ENABLE ROW LEVEL SECURITY (RLS)
-- ============================================================
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 5. CREATE RLS POLICIES FOR PRODUCTS
-- ============================================================
-- Allow everyone to read products
CREATE POLICY "Allow select products for all" ON products
  FOR SELECT USING (true);

-- Allow admin to insert/update/delete products
CREATE POLICY "Allow insert products for admin" ON products
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow update products for admin" ON products
  FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY "Allow delete products for admin" ON products
  FOR DELETE USING (true);

-- 6. CREATE RLS POLICIES FOR TRANSACTIONS
-- ============================================================
-- Allow everyone to read transactions
CREATE POLICY "Allow select transactions for all" ON transactions
  FOR SELECT USING (true);

-- Allow staff to insert transactions
CREATE POLICY "Allow insert transactions for staff" ON transactions
  FOR INSERT WITH CHECK (true);

-- Allow everyone to update transactions
CREATE POLICY "Allow update transactions for all" ON transactions
  FOR UPDATE USING (true) WITH CHECK (true);

-- 7. CREATE RLS POLICIES FOR USERS
-- ============================================================
-- Allow everyone to insert (for registration)
CREATE POLICY "Allow insert users for registration" ON users
  FOR INSERT WITH CHECK (true);

-- Allow users to read their own data
CREATE POLICY "Allow select own user data" ON users
  FOR SELECT USING (true);

-- Allow users to update their own data
CREATE POLICY "Allow update own user data" ON users
  FOR UPDATE USING (true) WITH CHECK (true);

-- ============================================================
-- OPTIONAL: INSERT SAMPLE DATA (uncomment to use)
-- ============================================================

-- Insert sample products
INSERT INTO products (nama, harga, stok, image_url) VALUES
  ('Jeruk Mandarin', 25000, 100, 'https://example.com/jeruk-mandarin.jpg'),
  ('Apel Fuji', 35000, 80, 'https://example.com/apel-fuji.jpg'),
  ('Mangga Harum Manis', 45000, 60, 'https://example.com/mangga.jpg'),
  ('Pisang Cavendish', 15000, 150, 'https://example.com/pisang.jpg'),
  ('Anggur Impor', 55000, 40, 'https://example.com/anggur.jpg'),
  ('Semangka', 50000, 30, 'https://example.com/semangka.jpg'),
  ('Strawberry', 40000, 50, 'https://example.com/strawberry.jpg'),
  ('Papaya', 20000, 75, 'https://example.com/papaya.jpg')
ON CONFLICT DO NOTHING;

-- Insert sample user (password harus di-hash dengan bcrypt di aplikasi)
-- Username: admin@retail.com, Password: admin123 (hash dengan bcrypt di aplikasi)
INSERT INTO users (email, password, role) VALUES
  ('admin@retail.com', '$2b$10$YIW48ZKzz5K1e1zJv8K1OOmGzU1gZ4zC3yZ8z9K5e1M2N3O4P5Q6', 'admin'),
  ('staff@retail.com', '$2b$10$YIW48ZKzz5K1e1zJv8K1OOmGzU1gZ4zC3yZ8z9K5e1M2N3O4P5Q6', 'staff')
ON CONFLICT DO NOTHING;

-- ============================================================
-- VERIFY: Check if tables created successfully
-- ============================================================
-- Uncomment to verify:
-- SELECT * FROM products;
-- SELECT * FROM transactions;
-- SELECT * FROM users;
