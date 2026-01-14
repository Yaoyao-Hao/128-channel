# QtBLE-128Channel
> A 128-channel BLE signal processing system developed with Qt + SimpleBLE driver, supporting spike detection, AP detection, visual display, threshold configuration, impedance testing, log recording, filter configuration, data playback and other functions.
<img width="1657" height="1019" alt="8ce5a0f96907e478a064346179d1a54c" src="https://github.com/user-attachments/assets/e224946d-f768-4668-a45f-705472a3fc45" />

## 🚀 Features
- ✅ Real-time acquisition of 128-channel BLE signals (based on SimpleBLE driver)
- ✅ Anomaly detection: Spike Detection, AP Detection with configurable thresholds
- ✅ Data visualization: Real-time signal waveform plotting implemented via QCustomPlot
- ✅ Log recording: Integrated QsLog for hierarchical logging (Debug/Info/Error) with support for persistent log file storage
- ✅ Data file processing: Supports reading, parsing, exporting of signal data and real-time display on the interface
- ✅ Visual GUI: Provides an operation interface supporting parameter configuration and channel status monitoring

## 🛠️ Tech Stack
### Core Frameworks/Languages
- Programming Language: C++ (C++17)
- Development Framework: Qt 6 (Qt Core/Qt Widgets)
- Visualization Component: QCustomPlot (open-source plotting library)
- Logging Component: QsLog (lightweight logging library for Qt)

### Development Environment
- Compiler: MSVC
- Build Tool: qmake (QtBLE.pro)
- System Support: Windows

## 🔧 Installation & Run
### Prerequisites
- Install Qt 6.9.1 (Qt Widgets module must be included)
- Install the corresponding compiler (e.g., MSVC 2019)
- Install SimpleBLE driver. Refer to: https://github.com/simpleble/simpleble
- Ensure that Qt environment variables are configured in the development environment (qmake can be called globally)

### Local Compilation and Running Steps
1. Clone the repository
```bash
git clone https://github.com/Yaoyao-Hao/128-channel.git
cd QtBLE-128Channel
```

2. Generate build files (qmake)
```bash
qmake QtBLE.pro -spec win32-msvc "CONFIG+=release"
```

3. Compile the project
```bash
# Windows (MSVC)
nmake
```

4. Deployment and running (Qt programs require dependency library deployment)
```bash
# Method 1: Use Qt's built-in windeployqt (Windows)
windeployqt release/QtBLE-128Channel.exe

# Method 2: Run directly in Qt Creator (recommended, automatically handles dependencies)
# Open Qt Creator → Open QtBLE.pro → Build → Run
```

5. Launch the program
```bash
release/QtBLE-128Channel.exe
```

## 📖 Usage Examples
### Example: Basic Signal Detection Process
1. After launching the program, click **Start Scanning**. The program will scan nearby Bluetooth devices. Select the target device and click **Connect Device**;
2. Click **Start Acquisition** to collect 128-channel signals;
3. View real-time signal waveforms (plotted by QCustomPlot) on the interface, or export data to files.

## 🤝 Contributing
Developers are welcome to participate in project optimization. The contribution process is as follows:
1. Fork this repository
2. Create a feature branch (`git checkout -b feature/AddNewFilter`)
3. Commit your changes (`git commit -m 'feat: xxxxxx'`)
4. Push to the branch (`git push origin feature/AddNewFilter`)
5. Open a Pull Request

### Contribution Guidelines
- Follow the official Qt C++ coding standards;
- Supplement corresponding comments for new features, and add usage examples for core classes;
- Avoid introducing redundant dependencies, and prioritize using native Qt APIs;
- Follow the **type: description** format for commit messages (feat/fix/docs/refactor, etc.).

## 📞 Contact
- Note: For technical communication, please submit a detailed issue description in the Issues section.

