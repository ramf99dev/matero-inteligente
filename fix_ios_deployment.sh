#!/bin/bash
echo "🔧 Corrigiendo deployment target..."

# Actualizar Podfile
sed -i '' 's/platform :ios, .*/platform :ios, '"'12.0'"'/' ios/Podfile

# Actualizar project.pbxproj
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = [^;]*;/IPHONEOS_DEPLOYMENT_TARGET = 12.0;/g' ios/Runner.xcodeproj/project.pbxproj

# Actualizar Info.plist si existe la clave
if grep -q "MinimumOSVersion" ios/Runner/Info.plist; then
    sed -i '' 's/<string>[^<]*<\/string>/<string>12.0<\/string>/' ios/Runner/Info.plist
else
    # Agregar la clave si no existe
    /usr/libexec/PlistBuddy -c "Add :MinimumOSVersion string 12.0" ios/Runner/Info.plist 2>/dev/null || true
fi

echo "✅ Deployment target actualizado a 12.0"
