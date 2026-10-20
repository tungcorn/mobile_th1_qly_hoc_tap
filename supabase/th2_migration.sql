-- =============================================================================
-- TH2 MIGRATION - StudyDoc Manager (Supabase)
-- -----------------------------------------------------------------------------
-- CÁCH CHẠY:
--   1. Mở Supabase Dashboard -> chọn project (opfzpgscyxwppgjpefhz)
--   2. Vào mục "SQL Editor" -> "New query"
--   3. Dán toàn bộ nội dung file này vào -> bấm "Run"
--
-- Script được viết theo kiểu idempotent (IF NOT EXISTS / CREATE OR REPLACE /
-- DROP POLICY IF EXISTS) nên có thể chạy lại nhiều lần mà không gây lỗi.
--
-- Nội dung:
--   - Cột mới: documents.tags / location_name / latitude / longitude / is_public /
--     view_count; document_permissions.expires_at; users.fcm_token
--   - Bảng mới: borrow_requests (mượn tài liệu), document_views (lịch sử xem)
--   - RPC record_document_view(p_document_id)
--   - Chính sách RLS mới (quyền hết hạn không còn hiệu lực, tài liệu công khai)
--   - Storage bucket 'documents' (đọc công khai, giới hạn 10MB) + policies
--
-- Danh tính người dùng: client gửi header x-user-id (Firebase UID) và
-- x-user-email; client dùng role anon (không có JWT Supabase Auth).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. CỘT MỚI
-- -----------------------------------------------------------------------------
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS tags text[] NOT NULL DEFAULT '{}';
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS location_name text;
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS latitude double precision;
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS longitude double precision;
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS is_public boolean NOT NULL DEFAULT false;
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS owner_email text;
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS view_count int NOT NULL DEFAULT 0;

ALTER TABLE public.document_permissions ADD COLUMN IF NOT EXISTS expires_at timestamptz;

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS fcm_token text;

-- -----------------------------------------------------------------------------
-- 2. BẢNG MỚI
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.borrow_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id uuid NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
  requester_id text NOT NULL,
  requester_email text NOT NULL DEFAULT '',
  owner_id text NOT NULL,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected', 'returned', 'cancelled')),
  message text DEFAULT '',
  due_date timestamptz,
  created_at timestamptz DEFAULT now(),
  responded_at timestamptz
);

CREATE TABLE IF NOT EXISTS public.document_views (
  id bigserial PRIMARY KEY,
  document_id uuid NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
  user_id text NOT NULL,
  viewed_at timestamptz DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- 3. CHỈ MỤC
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_documents_tags ON public.documents USING GIN (tags);
CREATE INDEX IF NOT EXISTS idx_documents_public ON public.documents(is_public) WHERE is_public;
CREATE INDEX IF NOT EXISTS idx_borrow_owner ON public.borrow_requests(owner_id);
CREATE INDEX IF NOT EXISTS idx_borrow_requester ON public.borrow_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_borrow_document ON public.borrow_requests(document_id);
CREATE INDEX IF NOT EXISTS idx_views_user ON public.document_views(user_id, viewed_at DESC);
CREATE INDEX IF NOT EXISTS idx_views_document ON public.document_views(document_id);

-- -----------------------------------------------------------------------------
-- 4. HÀM TRỢ GIÚP
-- -----------------------------------------------------------------------------
-- Thu hồi hàm cũ kèm các policy phụ thuộc (triệt tiêu lỗi 42P13 khi nâng cấp từ các bản cũ)
DROP FUNCTION IF EXISTS public.check_user_document_permission(uuid, text) CASCADE;
DROP FUNCTION IF EXISTS public.check_user_document_permission(uuid, text, text) CASCADE;
DROP FUNCTION IF EXISTS public.is_document_owner(uuid, text) CASCADE;
DROP FUNCTION IF EXISTS public.is_document_public(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.document_owner_id(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.record_document_view(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.current_app_user_id() CASCADE;
DROP FUNCTION IF EXISTS public.current_app_user_email() CASCADE;
-- User ID: header x-user-id, fallback auth.uid()
CREATE OR REPLACE FUNCTION public.current_app_user_id()
RETURNS text LANGUAGE sql STABLE AS $$
  SELECT coalesce(
    nullif(current_setting('request.headers', true)::json->>'x-user-id', ''),
    auth.uid()::text,
    ''
  );
$$;

-- User email: tra bảng users theo UID, fallback header x-user-email rồi JWT
CREATE OR REPLACE FUNCTION public.current_app_user_email()
RETURNS text LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_uid text;
  v_email text;
BEGIN
  v_uid := public.current_app_user_id();
  IF v_uid <> '' THEN
    SELECT email INTO v_email FROM public.users WHERE id = v_uid LIMIT 1;
  END IF;
  IF coalesce(v_email, '') = '' THEN
    v_email := nullif(current_setting('request.headers', true)::json->>'x-user-email', '');
  END IF;
  IF coalesce(v_email, '') = '' THEN
    v_email := auth.jwt()->>'email';
  END IF;
  RETURN lower(coalesce(v_email, ''));
END;
$$;

-- Kiểm tra chủ sở hữu (SECURITY DEFINER để tránh đệ quy RLS 42P17)
CREATE OR REPLACE FUNCTION public.is_document_owner(doc_id uuid, user_uid text)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.documents WHERE id = doc_id AND owner_id = user_uid
  );
END;
$$;

-- Cấp độ quyền chia sẻ còn hiệu lực (bỏ qua quyền đã hết hạn)
CREATE OR REPLACE FUNCTION public.check_user_document_permission(doc_id uuid, uemail text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_perm text;
BEGIN
  IF uemail IS NULL OR uemail = '' THEN
    RETURN NULL;
  END IF;
  SELECT permission_level INTO v_perm
  FROM public.document_permissions
  WHERE document_id = doc_id
    AND lower(shared_email) = lower(uemail)
    AND (expires_at IS NULL OR expires_at > now())
  LIMIT 1;
  RETURN v_perm;
END;
$$;

-- Tài liệu có công khai không (bypass RLS)
CREATE OR REPLACE FUNCTION public.is_document_public(doc_id uuid)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.documents WHERE id = doc_id AND is_public = true
  );
END;
$$;

-- Chủ sở hữu thực của tài liệu (bypass RLS)
CREATE OR REPLACE FUNCTION public.document_owner_id(doc_id uuid)
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT owner_id FROM public.documents WHERE id = doc_id LIMIT 1;
$$;

-- -----------------------------------------------------------------------------
-- 5. RPC GHI NHẬN LƯỢT XEM
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.record_document_view(p_document_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid text := public.current_app_user_id();
BEGIN
  IF v_uid = '' THEN
    RETURN;
  END IF;
  -- Chỉ ghi nhận khi người dùng thực sự có quyền xem tài liệu
  IF NOT (
    public.is_document_owner(p_document_id, v_uid)
    OR public.check_user_document_permission(p_document_id, public.current_app_user_email()) IS NOT NULL
    OR public.is_document_public(p_document_id)
  ) THEN
    RETURN;
  END IF;

  INSERT INTO public.document_views (document_id, user_id) VALUES (p_document_id, v_uid);
  UPDATE public.documents SET view_count = view_count + 1 WHERE id = p_document_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.record_document_view(uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.current_app_user_id() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.current_app_user_email() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_document_owner(uuid, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.check_user_document_permission(uuid, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_document_public(uuid) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.document_owner_id(uuid) TO anon, authenticated;

-- Quyền truy cập bảng cho role anon/authenticated (RLS vẫn lọc từng dòng)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.borrow_requests TO anon, authenticated;
GRANT SELECT, INSERT ON public.document_views TO anon, authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.document_views_id_seq TO anon, authenticated;

-- -----------------------------------------------------------------------------
-- 6. ROW LEVEL SECURITY
-- -----------------------------------------------------------------------------
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.borrow_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_views ENABLE ROW LEVEL SECURITY;

-- Xóa sạch policy cũ (tên có thể khác nhau giữa các lần chạy TH1) trên các bảng
-- documents / document_permissions / borrow_requests / document_views, vì policy
-- PERMISSIVE được OR với nhau: policy cũ không kiểm tra hết hạn sẽ làm hở quyền.
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT policyname, tablename FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('documents', 'document_permissions', 'borrow_requests', 'document_views')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', r.policyname, r.tablename);
  END LOOP;
END;
$$;

-- ---- users: mọi người đọc được hồ sơ; chỉ tự tạo/sửa hồ sơ của mình ----
DROP POLICY IF EXISTS users_select_all ON public.users;
CREATE POLICY users_select_all ON public.users
  FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS users_insert_self ON public.users;
CREATE POLICY users_insert_self ON public.users
  FOR INSERT TO anon, authenticated WITH CHECK (id = public.current_app_user_id());

DROP POLICY IF EXISTS users_update_self ON public.users;
CREATE POLICY users_update_self ON public.users
  FOR UPDATE TO anon, authenticated
  USING (id = public.current_app_user_id())
  WITH CHECK (id = public.current_app_user_id());

-- ---- documents ----
DROP POLICY IF EXISTS documents_select ON public.documents;
CREATE POLICY documents_select ON public.documents
  FOR SELECT TO anon, authenticated
  USING (
    owner_id = public.current_app_user_id()
    OR public.check_user_document_permission(id, public.current_app_user_email()) IS NOT NULL
    OR is_public = true
  );

DROP POLICY IF EXISTS documents_insert ON public.documents;
CREATE POLICY documents_insert ON public.documents
  FOR INSERT TO anon, authenticated
  WITH CHECK (owner_id = public.current_app_user_id());

DROP POLICY IF EXISTS documents_update ON public.documents;
CREATE POLICY documents_update ON public.documents
  FOR UPDATE TO anon, authenticated
  USING (
    owner_id = public.current_app_user_id()
    OR public.check_user_document_permission(id, public.current_app_user_email()) = 'editor'
  )
  WITH CHECK (
    owner_id = public.current_app_user_id()
    OR public.check_user_document_permission(id, public.current_app_user_email()) = 'editor'
  );

DROP POLICY IF EXISTS documents_delete ON public.documents;
CREATE POLICY documents_delete ON public.documents
  FOR DELETE TO anon, authenticated
  USING (owner_id = public.current_app_user_id());

-- ---- document_permissions: chủ tài liệu quản lý; người nhận xem quyền còn hạn ----
DROP POLICY IF EXISTS permissions_select ON public.document_permissions;
CREATE POLICY permissions_select ON public.document_permissions
  FOR SELECT TO anon, authenticated
  USING (
    public.is_document_owner(document_id, public.current_app_user_id())
    OR (
      lower(shared_email) = public.current_app_user_email()
      AND (expires_at IS NULL OR expires_at > now())
    )
  );

DROP POLICY IF EXISTS permissions_insert ON public.document_permissions;
CREATE POLICY permissions_insert ON public.document_permissions
  FOR INSERT TO anon, authenticated
  WITH CHECK (public.is_document_owner(document_id, public.current_app_user_id()));

DROP POLICY IF EXISTS permissions_update ON public.document_permissions;
CREATE POLICY permissions_update ON public.document_permissions
  FOR UPDATE TO anon, authenticated
  USING (public.is_document_owner(document_id, public.current_app_user_id()))
  WITH CHECK (public.is_document_owner(document_id, public.current_app_user_id()));

DROP POLICY IF EXISTS permissions_delete ON public.document_permissions;
CREATE POLICY permissions_delete ON public.document_permissions
  FOR DELETE TO anon, authenticated
  USING (
    public.is_document_owner(document_id, public.current_app_user_id())
    -- người nhận được tự từ bỏ quyền của mình (vd: trả tài liệu đã mượn)
    OR lower(shared_email) = public.current_app_user_email()
  );

-- ---- borrow_requests ----
DROP POLICY IF EXISTS borrow_select ON public.borrow_requests;
CREATE POLICY borrow_select ON public.borrow_requests
  FOR SELECT TO anon, authenticated
  USING (
    requester_id = public.current_app_user_id()
    OR owner_id = public.current_app_user_id()
  );

-- Người mượn tự tạo yêu cầu cho tài liệu công khai hoặc đã được chia sẻ,
-- không phải chủ sở hữu, và owner_id phải đúng chủ thật của tài liệu.
DROP POLICY IF EXISTS borrow_insert ON public.borrow_requests;
CREATE POLICY borrow_insert ON public.borrow_requests
  FOR INSERT TO anon, authenticated
  WITH CHECK (
    requester_id = public.current_app_user_id()
    AND requester_id <> ''
    AND status = 'pending'
    AND owner_id = public.document_owner_id(document_id)
    AND owner_id <> requester_id
    AND (
      public.is_document_public(document_id)
      OR public.check_user_document_permission(document_id, public.current_app_user_email()) IS NOT NULL
    )
  );

-- Chủ sở hữu: duyệt / từ chối / xác nhận trả. Người mượn: hủy / trả.
DROP POLICY IF EXISTS borrow_update ON public.borrow_requests;
CREATE POLICY borrow_update ON public.borrow_requests
  FOR UPDATE TO anon, authenticated
  USING (
    owner_id = public.current_app_user_id()
    OR requester_id = public.current_app_user_id()
  )
  WITH CHECK (
    (owner_id = public.current_app_user_id() AND status IN ('approved', 'rejected', 'returned'))
    OR (requester_id = public.current_app_user_id() AND status IN ('cancelled', 'returned'))
  );

-- ---- document_views: chỉ thêm/xem lịch sử của chính mình ----
DROP POLICY IF EXISTS views_select_own ON public.document_views;
CREATE POLICY views_select_own ON public.document_views
  FOR SELECT TO anon, authenticated
  USING (user_id = public.current_app_user_id());

DROP POLICY IF EXISTS views_insert_own ON public.document_views;
CREATE POLICY views_insert_own ON public.document_views
  FOR INSERT TO anon, authenticated
  WITH CHECK (user_id = public.current_app_user_id());

-- -----------------------------------------------------------------------------
-- 7. STORAGE BUCKET 'documents'
-- -----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', true)
ON CONFLICT (id) DO NOTHING;

-- Đọc công khai + giới hạn 10MB mỗi tệp
UPDATE storage.buckets
SET public = true, file_size_limit = 10485760
WHERE id = 'documents';

DROP POLICY IF EXISTS documents_bucket_select ON storage.objects;
CREATE POLICY documents_bucket_select ON storage.objects
  FOR SELECT TO anon, authenticated
  USING (bucket_id = 'documents');

DROP POLICY IF EXISTS documents_bucket_insert ON storage.objects;
CREATE POLICY documents_bucket_insert ON storage.objects
  FOR INSERT TO anon, authenticated
  WITH CHECK (bucket_id = 'documents');

DROP POLICY IF EXISTS documents_bucket_update ON storage.objects;
CREATE POLICY documents_bucket_update ON storage.objects
  FOR UPDATE TO anon, authenticated
  USING (bucket_id = 'documents')
  WITH CHECK (bucket_id = 'documents');

DROP POLICY IF EXISTS documents_bucket_delete ON storage.objects;
CREATE POLICY documents_bucket_delete ON storage.objects
  FOR DELETE TO anon, authenticated
  USING (bucket_id = 'documents');

-- -----------------------------------------------------------------------------
-- 8. LÀM MỚI SCHEMA CACHE CỦA POSTGREST
-- -----------------------------------------------------------------------------
NOTIFY pgrst, 'reload schema';
