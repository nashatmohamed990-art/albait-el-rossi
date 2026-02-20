// ═══════════════════════════════════════════════
//  البيت الروسي — إعدادات Supabase
//  غيّر القيم أدناه بعد إنشاء مشروعك على supabase.com
// ═══════════════════════════════════════════════

const SUPABASE_URL = 'https://YOUR_PROJECT.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY';

// إعدادات واتساب (Callmebot - مجاني)
const WHATSAPP_PHONE = '966XXXXXXXXX'; // رقمك بدون +
const WHATSAPP_API_KEY = 'YOUR_CALLMEBOT_KEY';

// إعدادات الدفع (MyFatoorah)
const MYFATOORAH_API_KEY = 'YOUR_MYFATOORAH_KEY';
const MYFATOORAH_BASE = 'https://api.myfatoorah.com'; // أو apitest للتجربة

// ─── Supabase Client بسيط بدون مكتبة خارجية ───
const db = {
  async query(table, method = 'GET', body = null, filter = '') {
    const url = `${SUPABASE_URL}/rest/v1/${table}${filter}`;
    const res = await fetch(url, {
      method,
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': method === 'POST' ? 'return=representation' : ''
      },
      body: body ? JSON.stringify(body) : null
    });
    if (!res.ok) {
      const err = await res.text();
      throw new Error(err);
    }
    return method === 'DELETE' ? true : res.json();
  },

  // المنتجات
  async getProducts(category = null) {
    let filter = '?order=created_at.desc';
    if (category) filter += `&category=eq.${encodeURIComponent(category)}`;
    return this.query('products', 'GET', null, filter);
  },

  async getProduct(id) {
    return this.query('products', 'GET', null, `?id=eq.${id}`).then(r => r[0]);
  },

  async addProduct(product) {
    return this.query('products', 'POST', product);
  },

  async updateProduct(id, updates) {
    return this.query('products', 'PATCH', updates, `?id=eq.${id}`);
  },

  async deleteProduct(id) {
    return this.query('products', 'DELETE', null, `?id=eq.${id}`);
  },

  // الطلبات
  async getOrders(status = null) {
    let filter = '?order=created_at.desc';
    if (status) filter += `&status=eq.${status}`;
    return this.query('orders', 'GET', null, filter);
  },

  async createOrder(order) {
    return this.query('orders', 'POST', order).then(r => r[0]);
  },

  async updateOrderStatus(id, status) {
    return this.query('orders', 'PATCH', { status, updated_at: new Date() }, `?id=eq.${id}`);
  },

  // الإحصائيات
  async getStats() {
    const [orders, products] = await Promise.all([
      this.query('orders', 'GET', null, '?select=total,status,created_at'),
      this.query('products', 'GET', null, '?select=id,stock')
    ]);
    const totalRevenue = orders.filter(o => o.status === 'paid').reduce((s, o) => s + o.total, 0);
    const todayOrders = orders.filter(o => new Date(o.created_at).toDateString() === new Date().toDateString());
    return {
      totalOrders: orders.length,
      todayOrders: todayOrders.length,
      totalRevenue,
      totalProducts: products.length,
      lowStock: products.filter(p => p.stock < 5).length
    };
  }
};

// ─── واتساب Callmebot ───
async function sendWhatsApp(message) {
  if (!WHATSAPP_API_KEY || WHATSAPP_API_KEY === 'YOUR_CALLMEBOT_KEY') return;
  const encoded = encodeURIComponent(message);
  const url = `https://api.callmebot.com/whatsapp.php?phone=${WHATSAPP_PHONE}&text=${encoded}&apikey=${WHATSAPP_API_KEY}`;
  try { await fetch(url); } catch (e) { console.log('WhatsApp error:', e); }
}

// ─── MyFatoorah دفع ───
async function initiatePayment(order) {
  const res = await fetch(`${MYFATOORAH_BASE}/v2/SendPayment`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${MYFATOORAH_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      NotificationOption: 'LNK',
      InvoiceValue: order.total,
      CustomerName: order.customer_name,
      CustomerEmail: order.customer_email,
      CustomerMobile: order.customer_phone,
      Language: 'AR',
      CallBackUrl: `${window.location.origin}/success.html`,
      ErrorUrl: `${window.location.origin}/error.html`,
      UserDefinedField: order.id
    })
  });
  const data = await res.json();
  return data.Data?.InvoiceURL;
}
