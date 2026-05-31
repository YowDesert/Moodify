# Moodify 🎧🌿

Moodify 是一款以「心情」為核心的 Flutter 音樂推薦 APP。  
使用者可以選擇當下的心情，APP 會透過 AI 推薦適合的歌曲，並搭配心情語錄、歌曲收藏、心情紀錄、天氣主題與呼吸練習等功能，讓音樂成為陪伴情緒的一部分。

---

## 📱 專案簡介

Moodify 的主要目標是讓使用者可以用最直覺的方式記錄自己的心情，並根據不同情緒獲得適合的音樂推薦。

使用者點選心情後，APP 會將心情資料傳給 Gemini API，由 AI 推薦歌曲名稱與歌手，再透過 iTunes Search API 搜尋實際歌曲資料，例如歌曲封面、歌手、專輯資訊與 previewUrl，最後顯示在 APP 畫面中，讓使用者可以直接試聽。

除了音樂推薦外，Moodify 也加入 Firebase 登入、雲端收藏、心情紀錄、天氣主題、深色模式、多主題切換、Spotify / YouTube 搜尋跳轉與呼吸練習功能，讓整體體驗更完整。

---

## ✨ 主要功能

### 🎭 心情選擇

使用者可以在首頁選擇目前的心情，例如：

- 開心
- 難過
- 焦慮
- 疲憊
- 想專心
- 療癒

每一種心情都有自己的 emoji、顏色與推薦關鍵字。

---

### 🤖 AI 音樂推薦

Moodify 使用 Gemini API 根據使用者選擇的心情產生歌曲推薦。

流程如下：

```text
使用者選擇心情
        ↓
Gemini 根據心情推薦歌曲名稱與歌手
        ↓
iTunes Search API 搜尋真實歌曲資料
        ↓
取得歌曲封面與 previewUrl
        ↓
顯示推薦歌曲卡片
```

---

### 🎵 iTunes 試聽播放

透過 iTunes Search API 取得歌曲資料：

- 歌曲名稱
- 歌手名稱
- 專輯名稱
- 專輯封面
- 30 秒 previewUrl

使用者可以直接在 APP 中播放歌曲試聽片段。

---

### ❤️ 收藏歌曲

使用者可以收藏喜歡的歌曲。

收藏方式分成兩種：

```text
未登入使用者 → 儲存在本機 SharedPreferences
已登入使用者 → 儲存在 Firebase Cloud Firestore
```

這樣即使使用者尚未登入，也可以先使用收藏功能；登入後則可以將資料同步到雲端。

---

### 📝 心情紀錄

每次使用者選擇心情時，APP 會自動儲存一筆心情紀錄。

紀錄內容包含：

- 心情名稱
- emoji
- 心情顏色
- 日期
- 時間

使用者可以在紀錄頁面查看自己過去的心情變化。

---

### 💬 心情語錄

Moodify 會根據使用者選擇的心情顯示不同的療癒語錄。

例如：

```text
焦慮：
先不用解決所有事情，先好好呼吸一次，讓自己回到現在。

疲憊：
休息不是停下來，而是讓你有力氣繼續走向想去的地方。
```

這個功能讓 APP 不只是推薦音樂，也能提供情緒上的陪伴感。

---

### 🌦️ 天氣主題

Moodify 使用 Open-Meteo Weather API 取得目前天氣，並根據天氣自動切換 APP 主題。

例如：

- 晴天主題
- 陰天主題
- 雨天主題
- 雷雨主題
- 霧天主題

---

### 🎨 多主題與深色模式

APP 支援多種主題切換，並包含深色模式，讓使用者可以依照喜好調整畫面風格。

主題包含：

- 清新綠
- 晴天黃
- 雨天藍
- 薰衣草紫
- 櫻花粉
- 海洋藍
- 夜晚深色

---

### 🧘 呼吸練習

Moodify 內建簡單的呼吸練習動畫，透過 Timer 與 AnimationController 製作吸氣、停留、吐氣的節奏。

流程如下：

```text
吸氣 4 秒
停留 2 秒
吐氣 6 秒
```

讓使用者在焦慮或疲憊時，可以透過呼吸練習放鬆。

---

### 🔎 Spotify / YouTube 搜尋跳轉

如果使用者想聽完整版歌曲，可以透過按鈕跳轉到 Spotify 或 YouTube 搜尋。

目前使用的是搜尋連結跳轉，不是正式 Spotify Web API 或 YouTube Data API。

---

## 🔌 使用到的 API / 外部服務

| API / 服務 | 用途 |
|---|---|
| Gemini API | 根據心情產生 AI 歌曲推薦 |
| iTunes Search API | 搜尋歌曲、封面與 previewUrl |
| Firebase Authentication | Google 登入驗證 |
| Google Sign-In | 取得 Google 帳號登入資訊 |
| Cloud Firestore | 儲存收藏歌曲與心情紀錄 |
| Open-Meteo Weather API | 取得即時天氣並切換主題 |
| Spotify Search Link | 跳轉 Spotify 搜尋歌曲 |
| YouTube Search Link | 跳轉 YouTube 搜尋歌曲 |

---

## 🛠️ 使用技術

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Google Sign-In
- Gemini API
- iTunes Search API
- Open-Meteo Weather API
- SharedPreferences
- HTTP Request
- audioplayers
- url_launcher
- dotenv
- AnimationController
- Timer
- Material Design 3

---

## 📂 專案結構

```text
lib/
├── main.dart
├── firebase_options.dart
├── models/
│   ├── mood.dart
│   └── song.dart
├── pages/
│   ├── home_page.dart
│   ├── recommend_page.dart
│   ├── favorite_page.dart
│   ├── history_page.dart
│   ├── profile_page.dart
│   └── ai_chat_page.dart
├── services/
│   ├── auth_service.dart
│   ├── gemini_music_recommendation_service.dart
│   ├── music_api_service.dart
│   ├── favorite_service.dart
│   ├── firebase_favorite_service.dart
│   ├── mood_history_service.dart
│   ├── firebase_mood_history_service.dart
│   ├── weather_service.dart
│   ├── spotify_search_service.dart
│   ├── youtube_search_service.dart
│   └── app_theme_controller.dart
└── widgets/
    ├── mood_card.dart
    ├── song_card.dart
    ├── breathing_exercise_sheet.dart
    └── bottom_nav_bar.dart
```

---

## 🚀 安裝與執行

### 1. Clone 專案

```bash
git clone https://github.com/YowDesert/Moodify.git
```

### 2. 進入專案資料夾

```bash
cd Moodify
```

### 3. 安裝套件

```bash
flutter pub get
```

### 4. 建立 `.env` 檔案

請在專案根目錄建立 `.env` 檔案，並放入 Gemini API Key：

```env
GEMINI_API_KEY=你的_Gemini_API_Key
```

### 5. 設定 Firebase

此專案使用 Firebase Authentication 與 Cloud Firestore。  
請自行建立 Firebase 專案，並設定：

- Android App
- Google Sign-In
- SHA-1
- Cloud Firestore
- `google-services.json`

然後將 `google-services.json` 放到：

```text
android/app/google-services.json
```

### 6. 執行專案

```bash
flutter run
```

---

## 📦 主要套件

```yaml
dependencies:
  flutter:
    sdk: flutter

  http:
  flutter_dotenv:
  firebase_core:
  firebase_auth:
  cloud_firestore:
  google_sign_in:
  shared_preferences:
  audioplayers:
  url_launcher:
```

---

## 🧠 核心功能流程

### 心情推薦歌曲流程

```text
MoodCard onTap
        ↓
RecommendPage(mood: mood)
        ↓
GeminiMusicRecommendationService
        ↓
Gemini API 推薦歌曲
        ↓
iTunes Search API 搜尋歌曲資料
        ↓
SongCard 顯示歌曲
```

---

### 收藏歌曲流程

```text
使用者點擊收藏
        ↓
判斷是否登入
        ↓
未登入：SharedPreferences
已登入：Cloud Firestore
        ↓
收藏成功
```

---

### 心情紀錄流程

```text
使用者選擇心情
        ↓
儲存 mood title / emoji / color / date / time
        ↓
未登入：SharedPreferences
已登入：Cloud Firestore
        ↓
紀錄頁面顯示心情紀錄
```

---

## 📸 APP 畫面

可以在這裡放上 APP 截圖：

```markdown
![Home Page](screenshots/home.png)
![Recommend Page](screenshots/recommend.png)
![Favorite Page](screenshots/favorite.png)
![History Page](screenshots/history.png)
```

---

## 📝 開發心得

這次製作 Moodify 的過程中，我學到最多的是如何把多個 API 與 Flutter APP 整合在一起。  
一開始我只是想做一個根據心情推薦音樂的 APP，但實作後才發現，真正的推薦功能不只是呼叫一個 API 而已。

Gemini API 可以根據心情推薦歌曲，但它不會提供歌曲封面與試聽音檔，所以我需要再串接 iTunes Search API，將 Gemini 推薦出來的歌名與歌手拿去搜尋真實歌曲資料。這讓我理解到 API 串接不只是取得資料，也需要處理資料格式、搜尋結果比對、錯誤處理與 fallback 機制。

另外，Firebase Authentication 與 Cloud Firestore 讓我學會如何處理使用者登入與雲端資料同步。未登入時資料存在本機，登入後資料可以同步到雲端，這讓 APP 更接近實際產品的設計方式。

在 UI 設計上，我也花了很多時間調整主題、深色模式、卡片樣式與整體配色，希望 Moodify 不只是功能完整，也能帶給使用者舒服、療癒的使用體驗。

---

## 📌 未來可以改進的方向

- 加入 Spotify Web API，直接取得 Spotify 歌曲資料
- 加入 YouTube Data API，顯示歌曲影片結果
- 加入更多心情分類
- 加入心情統計圖表
- 加入 AI 聊天陪伴功能強化
- 支援更多城市的天氣主題
- 加入通知提醒使用者記錄心情

---

## 👨‍💻 作者

Created by YowDesert

GitHub: [YowDesert](https://github.com/YowDesert)
