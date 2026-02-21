-- =====================================================
-- مكتب النخبة للمحاماة - Supabase Database Schema
-- نسخ هذا الكود كاملاً في Supabase → SQL Editor → Run
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ===== STAFF / USERS =====
CREATE TABLE staff (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_en TEXT,
  title TEXT DEFAULT 'محامي',
  role TEXT DEFAULT 'lawyer' CHECK (role IN ('admin','lawyer','assistant')),
  phone TEXT,
  email TEXT,
  years_exp INTEGER DEFAULT 0,
  bar_number TEXT,
  specialization TEXT,
  avatar_color TEXT DEFAULT '#C9A84C',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===== CLIENTS =====
CREATE TABLE clients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  name_en TEXT,
  type TEXT DEFAULT 'individual' CHECK (type IN ('individual','company','government')),
  civil_id TEXT,
  commercial_reg TEXT,
  phone TEXT,
  phone2 TEXT,
  email TEXT,
  address TEXT,
  notes TEXT,
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES staff(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===== CASES =====
CREATE TABLE cases (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  case_number TEXT NOT NULL UNIQUE,
  year INTEGER DEFAULT EXTRACT(YEAR FROM NOW()),
  client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
  opponent_name TEXT,
  case_type TEXT CHECK (case_type IN ('commercial','labor','criminal','personal','admin','civil','other')),
  court TEXT,
  circuit TEXT,
  role_number TEXT,
  lawyer_id UUID REFERENCES staff(id) ON DELETE SET NULL,
  co_lawyer_id UUID REFERENCES staff(id) ON DELETE SET NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active','postponed','closed','won','lost','settled')),
  agreed_fees DECIMAL(10,3) DEFAULT 0,
  paid_fees DECIMAL(10,3) DEFAULT 0,
  filing_date DATE,
  next_hearing DATE,
  summary TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===== HEARINGS =====
CREATE TABLE hearings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  case_id UUID REFERENCES cases(id) ON DELETE CASCADE,
  hearing_date DATE NOT NULL,
  court TEXT,
  circuit TEXT,
  role_number TEXT,
  lawyer_id UUID REFERENCES staff(id) ON DELETE SET NULL,
  decision TEXT,
  decision_type TEXT CHECK (decision_type IN ('postponed','argument','reserved','judgment','other')),
  next_hearing_date DATE,
  next_role_number TEXT,
  verdict TEXT,
  verdict_result TEXT CHECK (verdict_result IN ('won','lost','partial',NULL)),
  notes TEXT,
  transferred BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===== INVOICES =====
CREATE TABLE invoices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  invoice_number TEXT NOT NULL UNIQUE,
  client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
  case_id UUID REFERENCES cases(id) ON DELETE SET NULL,
  lawyer_id UUID REFERENCES staff(id) ON DELETE SET NULL,
  issue_date DATE DEFAULT CURRENT_DATE,
  due_date DATE,
  status TEXT DEFAULT 'unpaid' CHECK (status IN ('unpaid','paid','partial','overdue','cancelled')),
  subtotal DECIMAL(10,3) DEFAULT 0,
  tax DECIMAL(10,3) DEFAULT 0,
  discount DECIMAL(10,3) DEFAULT 0,
  total DECIMAL(10,3) DEFAULT 0,
  paid_amount DECIMAL(10,3) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===== INVOICE ITEMS =====
CREATE TABLE invoice_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  invoice_id UUID REFERENCES invoices(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  quantity INTEGER DEFAULT 1,
  unit_price DECIMAL(10,3) DEFAULT 0,
  total DECIMAL(10,3) DEFAULT 0,
  sort_order INTEGER DEFAULT 0
);

-- ===== DOCUMENTS =====
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  doc_type TEXT,
  case_id UUID REFERENCES cases(id) ON DELETE SET NULL,
  client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
  file_url TEXT,
  file_size INTEGER,
  file_type TEXT,
  confidentiality TEXT DEFAULT 'normal' CHECK (confidentiality IN ('normal','confidential','top_secret')),
  uploaded_by UUID REFERENCES staff(id),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===== TASKS =====
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('critical','high','normal','low')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','in_progress','done','cancelled')),
  due_date DATE,
  case_id UUID REFERENCES cases(id) ON DELETE SET NULL,
  assigned_to UUID REFERENCES staff(id) ON DELETE SET NULL,
  created_by UUID REFERENCES staff(id),
  reminder_days INTEGER DEFAULT 1,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===== DEADLINES (المدد القانونية) =====
CREATE TABLE deadlines (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  case_id UUID REFERENCES cases(id) ON DELETE CASCADE,
  deadline_type TEXT NOT NULL,
  start_date DATE NOT NULL,
  days_count INTEGER NOT NULL DEFAULT 30,
  end_date DATE NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active','done','missed','extended')),
  notes TEXT,
  alert_days INTEGER DEFAULT 7,
  created_by UUID REFERENCES staff(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===== TAWKEEL (التوكيلات) =====
CREATE TABLE tawkeel (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tawkeel_number TEXT UNIQUE,
  client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
  lawyer_id UUID REFERENCES staff(id) ON DELETE SET NULL,
  case_id UUID REFERENCES cases(id) ON DELETE SET NULL,
  tawkeel_type TEXT DEFAULT 'special',
  permissions TEXT[],
  issue_date DATE DEFAULT CURRENT_DATE,
  expiry_date DATE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active','expired','cancelled','needs_renewal')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===== EXPENSES =====
CREATE TABLE expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  description TEXT NOT NULL,
  category TEXT,
  amount DECIMAL(10,3) NOT NULL,
  expense_date DATE DEFAULT CURRENT_DATE,
  case_id UUID REFERENCES cases(id) ON DELETE SET NULL,
  paid_by UUID REFERENCES staff(id) ON DELETE SET NULL,
  payment_method TEXT DEFAULT 'cash',
  receipt_url TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===== APPOINTMENTS =====
CREATE TABLE appointments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
  lawyer_id UUID REFERENCES staff(id) ON DELETE SET NULL,
  case_id UUID REFERENCES cases(id) ON DELETE SET NULL,
  appt_type TEXT DEFAULT 'consultation',
  appt_date TIMESTAMPTZ NOT NULL,
  duration_minutes INTEGER DEFAULT 60,
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled','confirmed','done','cancelled','no_show')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===== MESSAGES LOG =====
CREATE TABLE messages_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
  channel TEXT DEFAULT 'whatsapp',
  message_type TEXT,
  message_text TEXT,
  sent_by UUID REFERENCES staff(id),
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  read_at TIMESTAMPTZ,
  status TEXT DEFAULT 'sent'
);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) - حماية البيانات
-- =====================================================
ALTER TABLE staff        ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients      ENABLE ROW LEVEL SECURITY;
ALTER TABLE cases        ENABLE ROW LEVEL SECURITY;
ALTER TABLE hearings     ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices     ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents    ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks        ENABLE ROW LEVEL SECURITY;
ALTER TABLE deadlines    ENABLE ROW LEVEL SECURITY;
ALTER TABLE tawkeel      ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses     ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages_log ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to access all data
CREATE POLICY "auth_all" ON staff        FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON clients      FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON cases        FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON hearings     FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON invoices     FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON invoice_items FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON documents    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON tasks        FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON deadlines    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON tawkeel      FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON expenses     FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON appointments FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "auth_all" ON messages_log FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- =====================================================
-- FUNCTIONS & TRIGGERS
-- =====================================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_cases_updated    BEFORE UPDATE ON cases    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_clients_updated  BEFORE UPDATE ON clients  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_invoices_updated BEFORE UPDATE ON invoices FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_tasks_updated    BEFORE UPDATE ON tasks    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_staff_updated    BEFORE UPDATE ON staff    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Auto-generate invoice number
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.invoice_number IS NULL OR NEW.invoice_number = '' THEN
    NEW.invoice_number := 'INV-' || TO_CHAR(NOW(),'YYYY') || '-' || LPAD(NEXTVAL('invoice_seq')::TEXT, 4, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE SEQUENCE IF NOT EXISTS invoice_seq START 1;
CREATE TRIGGER trg_invoice_number BEFORE INSERT ON invoices FOR EACH ROW EXECUTE FUNCTION generate_invoice_number();

-- =====================================================
-- SAMPLE DATA - بيانات تجريبية
-- (اختياري - احذفها إذا أردت البدء من صفر)
-- =====================================================

-- Note: تحتاج تضيف staff بعد إنشاء حساب المستخدم
-- يمكن إضافة البيانات التجريبية من لوحة إدارة Supabase

-- =====================================================
-- STORAGE BUCKET للمستندات
-- =====================================================
-- اذهب لـ Supabase → Storage → New Bucket
-- اسم: documents
-- Public: false
INSERT INTO storage.buckets (id, name, public) 
VALUES ('documents', 'documents', false)
ON CONFLICT DO NOTHING;

CREATE POLICY "auth_storage" ON storage.objects
FOR ALL TO authenticated USING (bucket_id = 'documents');

-- =====================================================
-- ✅ انتهى! الآن ارجع للتطبيق وأدخل بياناتك
-- =====================================================
