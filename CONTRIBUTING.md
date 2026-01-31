# Contribuyendo a GotaGota

¡Gracias por tu interés en contribuir a GotaGota! 🌱

## 🚀 Cómo Empezar

1. **Fork el repositorio**
2. **Clona tu fork**
   ```bash
   git clone https://github.com/TU_USUARIO/matero_fixed_new.git
   cd matero_fixed_new
   ```

3. **Configura el proyecto**
   ```bash
   # Instala dependencias
   flutter pub get
   
   # Crea tu archivo .env (copia .env.example)
   cp .env.example .env
   # Edita .env con tus credenciales de Supabase
   ```

4. **Crea una rama para tu feature**
   ```bash
   git checkout -b feature/mi-nueva-funcionalidad
   ```

## 📝 Guías de Desarrollo

### Estilo de Código
- Sigue las convenciones de Dart/Flutter
- Ejecuta `flutter analyze` antes de hacer commit
- Usa nombres descriptivos en español para variables y funciones
- Documenta funciones complejas con comentarios

### Tests
- Agrega tests para nuevas funcionalidades
- Asegúrate de que todos los tests pasen: `flutter test`
- Mantén la cobertura de tests alta

### Commits
Usa mensajes de commit descriptivos en español:
```
feat: Agregar sensor de pH del suelo
fix: Corregir cálculo de próximo riego
docs: Actualizar README con nuevas instrucciones
test: Agregar tests para modelo SensorReading
```

## 🔄 Pull Requests

1. Asegúrate de que tu código pase todos los tests
2. Actualiza la documentación si es necesario
3. Describe claramente los cambios en el PR
4. Referencia issues relacionados si aplica

## 🐛 Reportar Bugs

Usa el template de issues de GitHub e incluye:
- Descripción del problema
- Pasos para reproducir
- Comportamiento esperado vs actual
- Screenshots si aplica
- Versión de Flutter y dispositivo

## 💡 Sugerir Features

Abre un issue describiendo:
- El problema que resuelve
- La solución propuesta
- Alternativas consideradas

## 📄 Licencia

Al contribuir, aceptas que tus contribuciones se licencien bajo la misma licencia MIT del proyecto.
