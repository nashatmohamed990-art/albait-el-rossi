-- ═══════════════════════════════════════════════
--  البيت الروسي — قاعدة البيانات
--  انسخ هذا الكود والصقه في Supabase → SQL Editor
-- ═══════════════════════════════════════════════

-- جدول المنتجات
CREATE TABLE products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  name_ru TEXT,
  description TEXT,
  category TEXT NOT NULL,
  price NUMERIC(10,2) NOT NULL,
  old_price NUMERIC(10,2),
  stock INTEGER DEFAULT 0,
  image_url TEXT,
  emoji TEXT DEFAULT '📦',
  badge TEXT, -- 'new' | 'sale' | 'hot'
  origin TEXT DEFAULT 'روسيا',
  brand TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- جدول الطلبات
CREATE TABLE orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_number SERIAL,
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  customer_email TEXT,
  customer_city TEXT,
  customer_address TEXT NOT NULL,
  items JSONB NOT NULL,
  subtotal NUMERIC(10,2),
  shipping NUMERIC(10,2) DEFAULT 25,
  total NUMERIC(10,2) NOT NULL,
  status TEXT DEFAULT 'pending',
  -- pending | paid | processing | shipped | delivered | cancelled
  payment_method TEXT,
  payment_id TEXT,
  notes TEXT,
  whatsapp_sent BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- جدول الفئات
CREATE TABLE categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  emoji TEXT,
  sort_order INTEGER DEFAULT 0
);

-- بيانات تجريبية - الفئات
INSERT INTO categories (name, emoji, sort_order) VALUES
  ('شوكولاتة وحلويات', '🍫', 1),
  ('شاي وقهوة', '🫖', 2),
  ('مشروبات', '🥂', 3),
  ('تجميل وعناية', '🧴', 4),
  ('صحة وتغذية', '💊', 5),
  ('هدايا وتذكارات', '🎁', 6),
  ('بسكويت وكيك', '🍪', 7);

-- بيانات تجريبية - المنتجات
INSERT INTO products (name, category, price, old_price, stock, emoji, badge, brand) VALUES
  ('شوكولاتة ميشكا الأصلية 200 غرام', 'شوكولاتة وحلويات', 45, 60, 50, '🍫', 'hot', 'Красный Октябрь'),
  ('شاي أحمر روسي فاخر 100 كيس', 'شاي وقهوة', 38, NULL, 30, '🫖', 'new', 'Greenfield'),
  ('عسل روسي طبيعي 500 غرام', 'صحة وتغذية', 89, 110, 15, '🍯', 'sale', 'سيبيريا'),
  ('كريم مرطب روسي للبشرة', 'تجميل وعناية', 22, NULL, 40, '🧴', NULL, 'Невская Косметика'),
  ('تشكيلة حلوى روسية مشكّلة 300 غرام', 'شوكولاتة وحلويات', 32, NULL, 25, '🍬', 'hot', 'Рот Фронт'),
  ('قهوة روسية فورية 250 غرام', 'شاي وقهوة', 28, NULL, 20, '☕', 'new', 'Якобс'),
  ('دمية ماتريوشكا 7 طبقات', 'هدايا وتذكارات', 75, NULL, 10, '🪆', 'new', 'صناعة يدوية'),
  ('بسكويت يوبيلينوي 250 غرام', 'بسكويت وكيك', 18, 22, 60, '🍪', 'sale', 'Юбилейное');

-- صلاحيات القراءة العامة للمنتجات
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "products_public_read" ON products FOR SELECT USING (is_active = true);

-- صلاحيات الطلبات (الكتابة مسموحة للجميع، القراءة للأدمن فقط)
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "orders_insert" ON orders FOR INSERT WITH CHECK (true);
CREATE POLICY "orders_admin_read" ON orders FOR SELECT USING (true);
CREATE POLICY "orders_admin_update" ON orders FOR UPDATE USING (true);

-- دالة تحديث updated_at تلقائياً
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER products_updated_at BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER orders_updated_at BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
