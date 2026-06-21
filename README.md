
# 🧠 Memno — Save Links as Notes with Metadata Previews
<p align="center">
    <img src="assets/branding.png" width="640" />
   
</p>

- Memno is a **Flutter-based mobile and desktop app** for saving important links along with personal notes. It auto-fetches rich metadata for each link, supports offline usage, and generates unique 6-digit codes for easy fetching.

- Think of it as your personal link + note vault with instant previews—now fully supported on **Android and Windows**.

![GitHub stars](https://img.shields.io/github/stars/jydv402/memno?style=social)
![GitHub forks](https://img.shields.io/github/forks/jydv402/memno?style=social)
![License](https://img.shields.io/github/license/jydv402/memno?cacheBust=2)
![Platform](https://img.shields.io/badge/platform-flutter-blue)

---

## ✨ Features

- 🔗 **Save links** with title, description, and image previews
- 🧾 **Write notes** for each saved item
- ⚡ **Instant metadata fetching** from any URL
- 🔒 **6-digit short code** to easily acces the saved URLs
- 🌗 **Dark mode support**
- 💾 **Offline-first design**
- 🖥️ **Desktop Support (Windows)** with a dedicated, highly optimized widescreen interface:
  - ⚓ **Floating Dock**: Collapsible/expandable sidebar navigation.
  - 🔍 **Spotlight-like Search**: Open a central floating search bar with `Ctrl + F`.
  - ⌨️ **Keyboard Shortcuts**: Complete desktop navigation (`Ctrl + N` for new page, `Ctrl + ,` for settings, etc.).
- 🛠 Built entirely with **Flutter** and **Dart**

---

## 📸 Screenshots

<p float="left">
    <img src="assets/screenshots/home.png" width="250" style="padding-right: 10px; padding-bottom: 10px;"/>
    <img src="assets/screenshots/preview.png" width="250" style="padding-right: 10px;padding-bottom: 10px;"/>
    <img src="assets/screenshots/add_link.png" width="250" style="padding-bottom: 10px;"/>
    <img src="assets/screenshots/settings.jpg" width="250" style="padding-bottom: 10px;"/>
    <img src="assets/screenshots/update.jpeg" width="250" style="padding-bottom: 10px;"/>
    <img src="assets/screenshots/download.jpg" width="250" style="padding-bottom: 10px;"/>
</p>

---
## 🧠 Use Cases

- 🔖 Save useful articles, videos, and tutorials with personal annotations

- 🧰 Maintain a curated list of tools, links, or references for quick access

- ✍️ Jot down thoughts or reminders tied to specific websites or content

- 🔗 Save links with context for later reading (a smarter “read later” list)

- 🧠 Use as a personal knowledge base that stays with you, even offline

- 🕵️‍♂️ Archive interesting finds from Reddit, Twitter, or blogs with commentary

- 🎓 Keep study materials or academic resources grouped with notes

- 🧪 Save experimental ideas for future reference

- 🛍 Create a wish list of products with custom notes before purchase

- 🧑‍🍳 Save recipe links with modifications or ingredient replacements

---
## 🔧 Installation

### 🤖 Android
- Download the APK file from [here](https://github.com/jydv402/memno/releases/latest).
- Install it and you're good to go!

### 💻 Windows
- Download the installer (`memno-windows-x64-...exe`) from [here](https://github.com/jydv402/memno/releases/latest).
- Run the installer. It supports dual-mode installation (install for **"Just me"** without requiring admin rights or **"All users"** under standard Program Files).
- Complete the setup wizard and you're ready to use Memno on your desktop! 

---


## 📂 Project Structure

```
lib/
├── components/          # Shared & mobile UI components
├── database/            # Hive database models
├── desktop/             # Desktop-specific UI & layout
│   ├── components/      # Desktop sidebar dock, notification cards, file tiles
│   ├── pages/           # Desktop pages (Home, Settings, Search overlay, Note editor)
│   └── desktop_shell.dart
├── functionality/       # Code generators & preview services
├── home.dart
├── main.dart
└── theme/               # Theme & color assets

```

---

## 🧩 Built With

* Flutter
* Dart
* Provider
* Hive local database

---

## 🤝 Contributing

Contributions are welcome and appreciated!

To get started:

1. Fork this repository
2. Create a new branch (`git checkout -b memno-feature-xyz`)
3. Make your changes
4. Commit and push (`git commit -m "Added xyz"` → `git push origin memno-feature-xyz`)
5. Open a Pull Request

---

## 🛡 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 📣 Support & Feedback

If you find this app useful:

- 🌟 Star the repo
- 🐞 Report any issues
- 📢 Spread the word with your friends
- ❤️ Love the app and wanna share your support for keeping the app going? <a href="https://buymeachai.ezee.li/jydv402" target="_blank">
  <img src="https://buymeachai.ezee.li/assets/images/buymeachai-button.png" alt="Buy Me A Chai" width="120" height="40">
</a>


Let’s build something beautiful, simple, and helpful together.

Currently a user? Leave in your experience [here](https://forms.gle/8XHvADGkSAq3QfBm8)

---

> **Built with ❤️ by [JD](https://github.com/jydv402)** — striving to create tools that make life a little simpler.
