# GitHub Actions Build Notes

這個專案目前提供一條自動建置工作流：

- Android：輸出 `app-release.apk`
- iOS：輸出 `unsigned Runner.app.zip`

## 觸發方式

- 手動：`Actions` -> `Build Release Artifacts` -> `Run workflow`
- 自動發版：push `v*` tag，例如：

```bash
git tag v0.1.0
git push origin v0.1.0
```

## iOS 限制

目前 workflow 沒有接 Apple 開發者憑證與 provisioning profile，所以 iOS 產物是：

- `flutter build ios --release --no-codesign`

也就是未簽章版本。  
這可以拿來做後續打包或側載處理，但不能直接上架 App Store。

如果之後要讓 GitHub Actions 直接產出可安裝的簽章版 iOS 包，需要另外配置：

- Apple Developer 帳號
- signing certificate
- provisioning profile
- GitHub Secrets
