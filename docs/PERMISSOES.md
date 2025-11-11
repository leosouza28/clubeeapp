# Permissões do App Clubee

Este documento descreve todas as permissões configuradas no aplicativo e suas finalidades.

## 📱 Android

### Internet e Conectividade
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```
**Uso:** Comunicação com APIs, download de dados, sincronização.

---

### Câmera
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```
**Uso:** 
- Tirar fotos de documentos
- Capturar imagens para perfil
- Recursos de check-in com foto

**Nota:** `android:required="false"` permite que o app funcione em dispositivos sem câmera.

---

### Armazenamento e Galeria
```xml
<!-- Android 12 e inferior -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />

<!-- Android 13+ (API 33+) - Permissões granulares -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
```
**Uso:**
- Selecionar fotos da galeria
- Upload de imagens
- Salvar comprovantes e documentos

**Compatibilidade:**
- **Android ≤ 9 (API 28):** Usa `WRITE_EXTERNAL_STORAGE`
- **Android 10-12 (API 29-32):** Usa `READ_EXTERNAL_STORAGE`
- **Android 13+ (API 33+):** Usa permissões granulares (`READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`)

---

### Bluetooth (Impressoras Térmicas)
```xml
<!-- Android 11 e inferior -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />

<!-- Android 12+ (API 31+) - Novas permissões -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />

<uses-feature android:name="android.hardware.bluetooth" android:required="false" />
```
**Uso:**
- Conectar a impressoras térmicas Bluetooth
- Imprimir ingressos e comprovantes
- Gestão de dispositivos pareados

**Notas:**
- `neverForLocation` indica que o Bluetooth não é usado para rastreamento de localização
- `android:required="false"` permite que o app funcione em dispositivos sem Bluetooth

**Compatibilidade:**
- **Android ≤ 11 (API 30):** Usa `BLUETOOTH` e `BLUETOOTH_ADMIN`
- **Android 12+ (API 31+):** Usa novas permissões granulares (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `BLUETOOTH_ADVERTISE`)

---

### Push Notifications
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```
**Uso:**
- Notificações push via Firebase Cloud Messaging
- Alertas de eventos e promoções
- Notificações de reservas e check-ins
- Vibração e som para notificações

**Notas:**
- `POST_NOTIFICATIONS` é obrigatória no Android 13+ (API 33+) para exibir notificações
- `RECEIVE_BOOT_COMPLETED` permite que notificações agendadas sejam restauradas após reinicialização
- `WAKE_LOCK` mantém o dispositivo acordado para processar notificações

---

## 🍎 iOS

### Camera
```xml
<key>NSCameraUsageDescription</key>
<string>Precisamos acessar sua câmera para tirar fotos de documentos e perfil.</string>
```
**Uso:** Captura de fotos

---

### Photo Library
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Precisamos acessar suas fotos para você selecionar imagens da galeria.</string>
```
**Uso:** Seleção de imagens da galeria

---

### Bluetooth
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Precisamos acessar o Bluetooth para conectar a impressoras térmicas e imprimir ingressos.</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>Precisamos acessar o Bluetooth para conectar a impressoras térmicas.</string>
```
**Uso:** Conexão com impressoras térmicas

---

### Location (Background - se necessário)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Precisamos acessar sua localização para mostrar eventos próximos a você.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Precisamos acessar sua localização em segundo plano para enviar notificações de eventos próximos.</string>
```
**Uso:** Recursos baseados em localização (se implementado)

---

## 🔐 Solicitação de Permissões em Runtime

### Android (API 23+)
Permissões que requerem solicitação em runtime:
- ✅ `CAMERA`
- ✅ `READ_EXTERNAL_STORAGE` / `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO`
- ✅ `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT` (Android 12+)
- ✅ `POST_NOTIFICATIONS` (Android 13+)

### iOS
Todas as permissões sensíveis requerem solicitação em runtime:
- ✅ Camera
- ✅ Photo Library
- ✅ Bluetooth
- ✅ Location (se implementado)

---

## 📦 Packages Relacionados

### Câmera e Galeria
```yaml
dependencies:
  image_picker: ^latest
  camera: ^latest
```

### Bluetooth
```yaml
dependencies:
  flutter_blue_plus: ^latest
  # ou
  blue_thermal_printer: ^latest
```

### Notificações
```yaml
dependencies:
  firebase_messaging: ^latest
  flutter_local_notifications: ^latest
```

### Permissões
```yaml
dependencies:
  permission_handler: ^latest
```

---

## 🛠️ Como Solicitar Permissões

### Exemplo com permission_handler
```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> requestCameraPermission() async {
  final status = await Permission.camera.request();
  if (status.isGranted) {
    // Permissão concedida
  } else if (status.isDenied) {
    // Permissão negada
  } else if (status.isPermanentlyDenied) {
    // Usuário negou permanentemente, abrir configurações
    openAppSettings();
  }
}

Future<void> requestStoragePermission() async {
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      // Android 13+
      await Permission.photos.request();
    } else {
      // Android 12 e inferior
      await Permission.storage.request();
    }
  } else {
    await Permission.photos.request();
  }
}

Future<void> requestBluetoothPermission() async {
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 31) {
      // Android 12+
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
    } else {
      // Android 11 e inferior
      await Permission.bluetooth.request();
    }
  } else {
    await Permission.bluetooth.request();
  }
}

Future<void> requestNotificationPermission() async {
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      // Android 13+
      await Permission.notification.request();
    }
  } else {
    await Permission.notification.request();
  }
}
```

---

## 📋 Checklist de Implementação

### Android
- [x] Permissões declaradas no `AndroidManifest.xml`
- [ ] Solicitação de permissões em runtime implementada
- [ ] Tratamento de permissões negadas
- [ ] Redirecionamento para configurações quando necessário
- [ ] Teste em diferentes versões do Android (9, 11, 12, 13, 14)

### iOS
- [x] Strings de uso configuradas no `Info.plist`
- [ ] Solicitação de permissões em runtime implementada
- [ ] Tratamento de permissões negadas
- [ ] Teste em diferentes versões do iOS

---

## 🔍 Verificação

### Verificar permissões no Android
```bash
# Via ADB
adb shell dumpsys package com.guaraapp | grep permission
adb shell dumpsys package com.valedasminas | grep permission
```

### Verificar no código
```bash
# AndroidManifest.xml
grep "uses-permission" android/app/src/main/AndroidManifest.xml

# Info.plist
grep "UsageDescription" ios/Runner/Info.plist
```

---

## 📚 Referências

### Android
- [Permissions Overview](https://developer.android.com/guide/topics/permissions/overview)
- [Request Runtime Permissions](https://developer.android.com/training/permissions/requesting)
- [Bluetooth Permissions](https://developer.android.com/guide/topics/connectivity/bluetooth/permissions)
- [Photo Picker (Android 13+)](https://developer.android.com/training/data-storage/shared/photopicker)

### iOS
- [Requesting Authorization](https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy/requesting_access_to_protected_resources)
- [Camera and Microphone Access](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/requesting_authorization_for_media_capture_on_ios)
- [Bluetooth](https://developer.apple.com/documentation/corebluetooth)

### Flutter
- [permission_handler package](https://pub.dev/packages/permission_handler)
- [image_picker package](https://pub.dev/packages/image_picker)
- [flutter_blue_plus package](https://pub.dev/packages/flutter_blue_plus)
