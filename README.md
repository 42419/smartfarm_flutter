# Smart Farm Flutter

一个基于 Flutter 开发的智能农场管理应用。

## 项目简介

Smart Farm Flutter 是一款现代化的智能农场监控与管理应用，提供设备控制、数据监控、概览查看、警报中心和个人资料管理等功能。

## 主要功能

- **设备控制** - 远程控制农场设备
- **数据监控** - 实时监控农场环境数据
- **概览页面** - 查看农场整体状态
- **警报中心** - 接收和管理系统警报
- **个人资料** - 用户账户管理

## 技术栈

- **框架**: Flutter ^3.11.5
- **语言**: Dart
- **主要依赖**:
  - `dio` - HTTP 网络请求
  - `web_socket_channel` - WebSocket 通信
  - `fl_chart` - 数据图表展示
  - `cupertino_icons` - iOS 风格图标

## 项目结构

```
lib/
├── main.dart              # 应用入口
├── routes/
│   └── route.dart         # 路由配置
└── pages/
    ├── main_page.dart     # 主页面
    ├── login_page.dart    # 登录页面
    └── pageViews/
        ├── device_control_page.dart  # 设备控制
        ├── overview_page.dart        # 概览页面
        ├── alert_center_page.dart    # 警报中心
        ├── profile_page.dart         # 个人资料
        └── data_monitor_page.dart    # 数据监控
```

## 环境要求

- Flutter SDK: ^3.11.5
- Dart SDK: ^3.11.5

## 安装与运行

### 1. 克隆项目

```bash
git clone <repository-url>
cd smart_farm_flutter
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 运行应用

```bash
flutter run
```

## 构建发布版本

### Android

```bash
flutter build apk --release
```

或构建 App Bundle:

```bash
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

## 资源目录

- `assets/img/` - 图片资源目录

## 开发指南

### 代码格式化

```bash
flutter format .
```

### 代码分析

```bash
flutter analyze
```

### 运行测试

```bash
flutter test
```

## 相关资源

- [Flutter 官方文档](https://docs.flutter.dev/)
- [Dart 语言指南](https://dart.dev/guides)
- [Flutter 学习资源](https://docs.flutter.dev/reference/learning-resources)

## 许可证

本项目仅供学习和开发使用。

## 联系方式

如有问题或建议，请通过项目仓库提交 Issue。
