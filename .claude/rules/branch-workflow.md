# Branch Workflow

## Default Development Flow
- Tum aktif gelistirme `develop` branch'i uzerinde yapilir.
- `main` branch'i stabil ve release'a yakin dal olarak korunur.
- `main` uzerinde dogrudan commit veya deneysel degisiklik yapilmaz.

## Branch Rules
- Gelistirmeye baslamadan once taban branch: `develop`
- Yeni feature/fix branch'leri gerekiyorsa `develop` uzerinden turetilir
- `main` sadece testleri ve kalite kapilari gecmis degisiklikler icin guncellenir

## Merge / Push Policy
- Guncel gelistirmeler once `develop`e push edilir.
- `main`e merge/push oncesi kalite kapilari gecmeli (bkz. ai-workflow.md § Quality Gates)
- Gerekli kod jenerasyonu varsa merge oncesi calistirilir:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

## GitHub Workflow
- Temel aktif branch yapisi: `main` + `develop`
- PR varsayilan hedef branch: `develop`
- `main`e gecis: incelenmis ve testleri gecmis degisikliklerin kontrollu aktarimi
- Acikca hotfix gerekmiyorsa `main`e dogrudan PR acma

## Hotfix Exception
- Kritik production hatalarinda kisa sureli hotfix dogrudan `main` uzerinden alinabilir
- Minimum degisiklik yap, testleri calistir
- Sonrasinda degisikligi `develop`e geri tasi (dallari esitle)

## Operational Notes
- `develop` tek kalici gelistirme branch'i — branch temizliginde korunur
- `main`-`develop` arasi drift olusursa: once farki anla, sonra kontrollu merge yap
- GitHub Actions branch protection bu akisa gore dusunulmeli

> **Ilgili**: git-rules.md (commit format, branch naming), ai-workflow.md (kalite kapilari), release-ops.md (deploy akisi)
