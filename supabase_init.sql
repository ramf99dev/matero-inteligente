-- ========================================
-- GOTAGOTA (MATERO INTELIGENTE) - SCHEMA COMPLETO
-- ========================================

-- 1. PROFILES TABLE (Para datos de usuario)
-- Supabase maneja usuarios en 'auth.users', esta tabla se vincula a ella
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL PRIMARY KEY,
  email TEXT,
  username TEXT,
  avatar_url TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone."
  ON profiles FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile."
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile."
  ON profiles FOR UPDATE USING (auth.uid() = id);

-- 2. PLANTS TABLE (Plantas de cada usuario)
CREATE TABLE IF NOT EXISTS public.plants (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  image_url TEXT,
  description TEXT,
  last_watered TIMESTAMPTZ,
  watering_frequency INT DEFAULT 3, -- días entre riegos
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.plants ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para plants
CREATE POLICY "Users can view their own plants"
  ON plants FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own plants"
  ON plants FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own plants"
  ON plants FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own plants"
  ON plants FOR DELETE USING (auth.uid() = user_id);

-- 3. MATERO READINGS TABLE (Lecturas de sensores)
CREATE TABLE IF NOT EXISTS public.matero_readings (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  plant_id BIGINT REFERENCES plants(id) ON DELETE CASCADE,
  temperature FLOAT8,
  humidity FLOAT8,
  soil_moisture INT,
  light_level INT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.matero_readings ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para matero_readings
-- Permitir inserciones anónimas (para ESP32)
CREATE POLICY "Allow anonymous inserts"
  ON public.matero_readings FOR INSERT TO anon WITH CHECK (true);

-- Permitir lecturas anónimas (para ESP32)
CREATE POLICY "Allow anonymous select"
  ON public.matero_readings FOR SELECT TO anon USING (true);

-- Permitir inserciones autenticadas
CREATE POLICY "Allow authenticated inserts"
  ON public.matero_readings FOR INSERT TO authenticated WITH CHECK (true);

-- Permitir lecturas autenticadas (solo de sus propias plantas)
CREATE POLICY "Allow authenticated select"
  ON public.matero_readings FOR SELECT TO authenticated 
  USING (
    plant_id IN (
      SELECT id FROM plants WHERE user_id = auth.uid()
    )
  );

-- 4. STORAGE BUCKET para imágenes de plantas
INSERT INTO storage.buckets (id, name, public)
VALUES ('plant_images', 'plant_images', true)
ON CONFLICT (id) DO NOTHING;

-- Políticas de storage
CREATE POLICY "Anyone can view plant images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'plant_images');

CREATE POLICY "Authenticated users can upload plant images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'plant_images' AND
    auth.role() = 'authenticated'
  );

CREATE POLICY "Users can update their own plant images"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'plant_images' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete their own plant images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'plant_images' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- 5. TRIGGER para auto-crear perfil al registrarse
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, username)
  VALUES (new.id, new.email, new.raw_user_meta_data->>'username');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Eliminar trigger si existe para evitar duplicados
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 6. ÍNDICES para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_plants_user_id ON plants(user_id);
CREATE INDEX IF NOT EXISTS idx_matero_readings_plant_id ON matero_readings(plant_id);
CREATE INDEX IF NOT EXISTS idx_matero_readings_created_at ON matero_readings(created_at DESC);

-- ========================================
-- NOTAS DE MIGRACIÓN
-- ========================================
-- Si ya tienes datos en matero_readings sin plant_id:
-- 1. Primero crea una planta de prueba para cada usuario
-- 2. Luego actualiza los registros existentes:
--    UPDATE matero_readings SET plant_id = 1 WHERE plant_id IS NULL;
-- 3. Finalmente, puedes hacer plant_id NOT NULL si lo deseas:
--    ALTER TABLE matero_readings ALTER COLUMN plant_id SET NOT NULL;
