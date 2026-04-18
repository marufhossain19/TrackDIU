# 🚌 TrackDIU — Campus Transit Tracker

Welcome to **TrackDIU**, your ultimate companion for real-time campus transit tracking! 📍✨ This application helps students and faculty effortlessly locate campus buses securely, accurately, and in real-time.

---

## ✨ Key Features

- **🗺️ Real-Time Tracking:** Leveraging Google Maps and live GPS tracking (`geolocator`), you can monitor the bus's live location on the interactive map.
- **☁️ Supabase Backend:** Secure database management and seamless real-time syncing.
- **⚡ Supercharged State Management:** Powered by `flutter_riverpod` for a smooth, lag-free experience.
- **🗃️ Local Caching:** Built with `hive_flutter` for lighting-fast data retrieval. 
- **🎨 Beautiful UI & Animations:** Fluid interfaces and charming animations via `lottie` and `animations`, paired with `google_fonts` for an exquisite look.
- **🛣️ Route Details:** Uses `flutter_polyline_points` for accurate visual representations of transit routes to campus.

## 🛠️ Tech Stack & Dependencies

- **Framework:** Flutter (Dart)
- **Backend:** Supabase (`supabase_flutter`)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Mapping & Location:** Google Maps (`google_maps_flutter`), Geolocator, Geocoding
- **Storage:** Hive (`hive_flutter`)

---

## 🚀 Getting Started (For Developers)

To run this application locally, ensure you have Flutter strictly installed.

1. **Clone the repository:**
   ```bash
   git clone <your-repo-link>
   cd diu_smartbus
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the App:**
   ```bash
   flutter run
   ```

---

## 📱 Installation Guide (For Android Users)

Want to install the app directly via APK onto your Android device? Follow these quick and easy steps! 🚀

1. **Download the APK file** point to the `.apk` file that is downloaded.
2. ⚠️ **Enable Unknown Sources:** Since the app is not downloaded from the Google Play Store, you need to grant your device permission to install it. 
   - Open your phone's **Settings ⚙️** > **Apps** (or **Security** / **Privacy** depending on the device).
   - Tap on **Special app access**.
   - Find the **Install Unknown Apps** button.
   - Select the app you used to download the APK (e.g., Chrome, Google Drive, or your local File Manager) and toggle on **"Allow from this source"** ✅.
3. **Install the App:** Tap the downloaded `.apk` file from your device's interface and explicitly hit **Install**.
4. **Launch & Ride:** Once installed, open the newly labeled **TrackDIU** app, grant the required location/GPS permissions 📍, and start tracking your campus bus with ease! 🌟

---

## 🤝 Contributing & Feedback

Contributions, bug reports, and feature requests are gracefully accepted! Let's make catching the bus easier for everyone. 

**Made with ❤️ for seamless campus commutes! 🎓🚌**
