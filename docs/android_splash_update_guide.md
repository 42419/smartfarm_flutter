# Android 启动图更换指南

本文档记录当前项目 Android 启动图的实现方式，以及后续更换启动图时需要修改的文件和操作步骤。

## 当前实现

项目现在使用 Android 原生启动窗口背景，不使用 Android 12 `SplashScreen API` 的中间图标渲染。

这样做的原因是：

- 可以按原图显示圆角 logo
- 不会被系统按启动图标规则裁切或重排

当前启动图由以下文件控制：

- 启动布局：[android/app/src/main/res/drawable/launch_background.xml](/D:/desktop/smart_farm_flutter/android/app/src/main/res/drawable/launch_background.xml:1)
- Android 5.0+ 启动布局：[android/app/src/main/res/drawable-v21/launch_background.xml](/D:/desktop/smart_farm_flutter/android/app/src/main/res/drawable-v21/launch_background.xml:1)
- 日间主题：[android/app/src/main/res/values/styles.xml](/D:/desktop/smart_farm_flutter/android/app/src/main/res/values/styles.xml:1)
- 夜间主题：[android/app/src/main/res/values-night/styles.xml](/D:/desktop/smart_farm_flutter/android/app/src/main/res/values-night/styles.xml:1)
- Android 12+ 日间主题：[android/app/src/main/res/values-v31/styles.xml](/D:/desktop/smart_farm_flutter/android/app/src/main/res/values-v31/styles.xml:1)
- Android 12+ 夜间主题：[android/app/src/main/res/values-night-v31/styles.xml](/D:/desktop/smart_farm_flutter/android/app/src/main/res/values-night-v31/styles.xml:1)

启动图本体使用的是各密度目录下的 `splash.png`：

- `android/app/src/main/res/drawable-mdpi/splash.png`
- `android/app/src/main/res/drawable-hdpi/splash.png`
- `android/app/src/main/res/drawable-xhdpi/splash.png`
- `android/app/src/main/res/drawable-xxhdpi/splash.png`
- `android/app/src/main/res/drawable-xxxhdpi/splash.png`
- `android/app/src/main/res/drawable-night-mdpi/splash.png`
- `android/app/src/main/res/drawable-night-hdpi/splash.png`
- `android/app/src/main/res/drawable-night-xhdpi/splash.png`
- `android/app/src/main/res/drawable-night-xxhdpi/splash.png`
- `android/app/src/main/res/drawable-night-xxxhdpi/splash.png`

当前源图路径：

- [assets/img/logo.png](/D:/desktop/smart_farm_flutter/assets/img/logo.png:1)

## 更换启动图时要改哪里

如果只更换 Android 启动页中间那张图，需要修改两部分：

1. 替换源图 `assets/img/logo.png`
2. 重新生成所有 `drawable-*` 和 `drawable-night-*` 下的 `splash.png`

如果只改 `assets/img/logo.png`，Android 启动页不会自动更新，因为启动页读取的是原生资源目录里的 PNG，不是 Flutter runtime asset。

## 当前推荐尺寸

当前启动图目标显示大小是 `180dp`。

对应各密度资源尺寸如下：

- `mdpi`: `180 x 180`
- `hdpi`: `270 x 270`
- `xhdpi`: `360 x 360`
- `xxhdpi`: `540 x 540`
- `xxxhdpi`: `720 x 720`

夜间模式目录使用同样的尺寸。

## 操作步骤

### 1. 准备新图

建议新图满足以下条件：

- PNG 格式
- 背景透明
- 如果需要圆角，圆角直接做在 PNG 里
- 画布最好是正方形
- 内容居中

把新图替换到：

- [assets/img/logo.png](/D:/desktop/smart_farm_flutter/assets/img/logo.png:1)

### 2. 生成 Android 启动图资源

在项目根目录执行下面这段 PowerShell：

```powershell
Add-Type -AssemblyName System.Drawing

$sourcePath = 'D:\desktop\smart_farm_flutter\assets\img\logo.png'
$source = [System.Drawing.Bitmap]::FromFile($sourcePath)

$targets = @{
  'D:\desktop\smart_farm_flutter\android\app\src\main\res\drawable-mdpi\splash.png' = 180
  'D:\desktop\smart_farm_flutter\android\app\src\main\res\drawable-hdpi\splash.png' = 270
  'D:\desktop\smart_farm_flutter\android\app\src\main\res\drawable-xhdpi\splash.png' = 360
  'D:\desktop\smart_farm_flutter\android\app\src\main\res\drawable-xxhdpi\splash.png' = 540
  'D:\desktop\smart_farm_flutter\android\app\src\main\res\drawable-xxxhdpi\splash.png' = 720
  'D:\desktop\smart_farm_flutter\android\app\src\main\res\drawable-night-mdpi\splash.png' = 180
  'D:\desktop\smart_farm_flutter\android\app\src\main\res\drawable-night-hdpi\splash.png' = 270
  'D:\desktop\smart_farm_flutter\android\app\src\main\res\drawable-night-xhdpi\splash.png' = 360
  'D:\desktop\smart_farm_flutter\android\app\src\main\res\drawable-night-xxhdpi\splash.png' = 540
  'D:\desktop\smart_farm_flutter\android\app\src\main\res\drawable-night-xxxhdpi\splash.png' = 720
}

foreach ($entry in $targets.GetEnumerator()) {
    $size = [int]$entry.Value
    $bitmap = New-Object System.Drawing.Bitmap $size, $size
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($source, 0, 0, $size, $size)

    $bitmap.Save($entry.Key, [System.Drawing.Imaging.ImageFormat]::Png)

    $graphics.Dispose()
    $bitmap.Dispose()
}

$source.Dispose()
```

这段脚本会把 `assets/img/logo.png` 按当前项目使用的 180dp 规格，生成到全部 Android 启动图资源目录。

### 3. 如需改大或改小

如果你觉得启动图太大或太小，只需要把上面脚本中的基础值整体调整即可。

例如：

- 想更小一点：把 `mdpi` 从 `180` 改为 `160`
- 想更大一点：把 `mdpi` 从 `180` 改为 `200`

其余目录按密度同比例调整：

- `hdpi = mdpi * 1.5`
- `xhdpi = mdpi * 2`
- `xxhdpi = mdpi * 3`
- `xxxhdpi = mdpi * 4`

## 哪些文件通常不用改

以下文件通常不需要改：

- [android/app/src/main/res/drawable/launch_background.xml](/D:/desktop/smart_farm_flutter/android/app/src/main/res/drawable/launch_background.xml:1)
- [android/app/src/main/res/drawable-v21/launch_background.xml](/D:/desktop/smart_farm_flutter/android/app/src/main/res/drawable-v21/launch_background.xml:1)
- [android/app/src/main/res/values/styles.xml](/D:/desktop/smart_farm_flutter/android/app/src/main/res/values/styles.xml:1)
- [android/app/src/main/res/values-night/styles.xml](/D:/desktop/smart_farm_flutter/android/app/src/main/res/values-night/styles.xml:1)
- [android/app/src/main/res/values-v31/styles.xml](/D:/desktop/smart_farm_flutter/android/app/src/main/res/values-v31/styles.xml:1)
- [android/app/src/main/res/values-night-v31/styles.xml](/D:/desktop/smart_farm_flutter/android/app/src/main/res/values-night-v31/styles.xml:1)

除非你要改：

- 启动页背景色
- logo 居中方式
- 是否铺满背景
- 日间/夜间不同效果

## 如果还要改应用图标

启动图和应用图标不是一回事。

如果你还想同时修改 Android 应用图标，需要另外替换这些文件：

- `android/app/src/main/res/mipmap-mdpi/logo.png`
- `android/app/src/main/res/mipmap-hdpi/logo.png`
- `android/app/src/main/res/mipmap-xhdpi/logo.png`
- `android/app/src/main/res/mipmap-xxhdpi/logo.png`
- `android/app/src/main/res/mipmap-xxxhdpi/logo.png`

## 验证方法

修改完成后，建议执行：

```powershell
cd android
.\gradlew.bat :app:assembleDebug
```

如果构建通过，再安装到真机上看启动效果。

## 一句话总结

后续更换启动图时，最关键的是：

- 先替换 [assets/img/logo.png](/D:/desktop/smart_farm_flutter/assets/img/logo.png:1)
- 再重新生成所有 `drawable-*` 和 `drawable-night-*` 下的 `splash.png`

只改 Flutter 的 `assets`，不会自动更新 Android 原生启动页。
