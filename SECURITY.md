# Política de Seguridad

## 🔐 Reportar Vulnerabilidades

Si descubres una vulnerabilidad de seguridad en GotaGota, por favor **NO** abras un issue público.

En su lugar:

1. **Envía un email a**: molinafloresrandy99@gmail.com
2. **Incluye**:
   - Descripción detallada de la vulnerabilidad
   - Pasos para reproducir
   - Impacto potencial
   - Sugerencias de solución (si las tienes)

## ⏱️ Tiempo de Respuesta

- Confirmaremos la recepción en **48 horas**
- Evaluaremos y responderemos en **7 días**
- Trabajaremos en un fix y te mantendremos informado

## 🛡️ Mejores Prácticas de Seguridad

### Para Usuarios

1. **Nunca compartas tu archivo `.env`**
   - Contiene credenciales sensibles de Supabase
   - Está en `.gitignore` por defecto

2. **Usa credenciales únicas**
   - No reutilices passwords entre servicios
   - Rota tus API keys periódicamente

3. **Mantén actualizado**
   - Actualiza Flutter regularmente
   - Actualiza dependencias: `flutter pub upgrade`

### Para Desarrolladores

1. **Variables de Entorno**
   - NUNCA hagas commit de `.env`
   - Usa `.env.example` como plantilla
   - Documenta todas las variables necesarias

2. **Supabase Security**
   - Habilita Row Level Security (RLS)
   - Revisa políticas de acceso regularmente
   - Usa el `anon` key solo para operaciones públicas

3. **Código**
   - No hardcodees credenciales
   - Valida inputs del usuario
   - Sanitiza datos antes de mostrarlos

## 🔒 Configuración Segura

### Supabase RLS Policies

Asegúrate de que las políticas RLS estén habilitadas:

```sql
-- Usuarios solo ven sus propias plantas
CREATE POLICY "Users can view their own plants"
  ON plants FOR SELECT USING (auth.uid() = user_id);

-- Lecturas de sensores filtradas por planta del usuario
CREATE POLICY "Allow authenticated select"
  ON matero_readings FOR SELECT TO authenticated 
  USING (
    plant_id IN (
      SELECT id FROM plants WHERE user_id = auth.uid()
    )
  );
```

### Variables de Entorno

Tu archivo `.env` debe contener:

```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu_anon_key_aqui
```

**IMPORTANTE**: 
- ✅ `.env` está en `.gitignore`
- ✅ `.env.example` se puede compartir (sin valores reales)
- ❌ NUNCA subas `.env` a GitHub

## 📋 Checklist de Seguridad

Antes de hacer deploy o compartir:

- [ ] `.env` está en `.gitignore`
- [ ] No hay credenciales hardcodeadas en el código
- [ ] RLS está habilitado en todas las tablas de Supabase
- [ ] Las políticas RLS filtran por `user_id`
- [ ] Los tests pasan: `flutter test`
- [ ] El análisis no muestra warnings: `flutter analyze`

## 🆘 Soporte

Para preguntas de seguridad no urgentes, abre un issue con el tag `security`.

---

**Gracias por ayudar a mantener GotaGota seguro!** 🌱🔒
