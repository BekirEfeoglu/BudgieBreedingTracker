# Branch Workflow

## Default Development Flow
- Yeni gelistirme, bug fix, refactor ve CI degisiklikleri dogrudan `main` uzerinde yapilmaz.
- Tum aktif gelistirme calismalari `develop` branch'i uzerinde yapilir.
- `main` branch'i her zaman daha stabil ve release'a yakin dal olarak korunur.

## Branch Rules
- Gelistirmeye baslamadan once taban branch olarak `develop` kullan.
- Yeni feature/fix branch'leri gerekiyorsa `develop` uzerinden turetilir.
- `main` sadece testleri ve kalite kapilari gecmis degisiklikler icin guncellenir.
- `main` uzerinde dogrudan commit veya deneysel degisiklik yapma.

## Merge / Push Policy
- Guncel gelistirmeler once `develop`e push edilir.
- Asagidaki kontroller gecmeden `main`e merge/push yapilmaz:
  - `flutter analyze --no-fatal-infos`
  - `flutter test`
  - `python3 scripts/verify_code_quality.py`
  - `python3 scripts/check_l10n_sync.py --strict-keys`
  - `python3 scripts/verify_rules.py --strict`
- Gerekli kod jenerasyonu varsa merge oncesi calistirilir:
  - `dart run build_runner build --delete-conflicting-outputs`

## GitHub Workflow Expectation
- GitHub'da temel aktif branch yapisi:
  - `main`
  - `develop`
- PR acarken varsayilan hedef branch gelistirme surecinde `develop` olmalidir.
- `main`e gecis, testleri gecmis ve incelenmis degisikliklerin kontrollu aktarimi ile yapilir.
- Acikca hotfix gerekmiyorsa `main`e dogrudan PR acma.

## Hotfix Exception
- Kritik production hatalarinda kisa sureli hotfix dogrudan `main` uzerinden alinabilir.
- Boyle bir durumda:
  - minimum degisiklik yap
  - gerekli testleri yine calistir
  - degisikligi sonrasinda `develop`e geri tasiyarak dallari tekrar esitle

## Operational Notes
- Branch temizligi yaparken `develop` korunur; tek kalici gelistirme branch'i olarak kullanilir.
- `main` ve `develop` arasinda drift olusursa once farki anla, sonra kontrollu merge yap.
- GitHub Actions ve branch protection kurallari bu akisa gore dusunulmelidir.
