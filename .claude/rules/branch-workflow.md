# Branch Workflow

## Default Development Flow
- Kalici branch stratejisi main-only: GitHub remote'da yalnizca `main` kalici daldir.
- Aktif gelistirme `main` tabanindan yapilir.
- Kisa sureli feature/fix branch'leri yalnizca PR/review veya riskli deneme gerektiginde acilir.
- Branch temizligi sonrasi Dependabot veya gecici ajan dallari kalici kabul edilmez.

## Branch Rules
- Gelistirmeye baslamadan once taban branch: `main`
- Yeni feature/fix branch'leri gerekiyorsa guncel `main` uzerinden turetilir
- `main`e push sadece ilgili kalite kapilari gecince yapilir
- Remote branch temizliginde korunacak tek kalici dal: `main`

## Merge / Push Policy
- `main`e merge/push oncesi kalite kapilari gecmeli (bkz. ai-workflow.md § Quality Gates)
- `main`e push oncesi `git diff --name-status` task-owned kirli dosya gostermemeli; final commit sonrasi `git diff --cached --name-status` bos olmali
- Gerekli kod jenerasyonu varsa merge oncesi calistirilir:
  ```bash
  dart run build_runner build
  ```
- `main`e push yapildiginda exact commit SHA icin tum status/check-run'lar tamamlanmadan branch temiz kabul edilmez
- Push/handoff sonrasi local `git status --short --branch` tekrar okunmali; clean-tree isteniyorsa unrelated pre-existing/user degisiklikleri isimli stash veya ayri branch ile korunup ref'i raporlanmali
- Branch protection bypass edilirse bu bir istisnadir; push sonrasi remote dogrulama zorunlulugu ortadan kalkmaz

## GitHub Workflow
- Temel aktif branch yapisi: `main`
- PR varsayilan hedef branch: `main`
- Gecici dallar merge sonrasi silinir
- Dependabot dallari incelenmedikce kalici tutulmaz; stale branch cleanup `main` disindakileri temizleyebilir

## Hotfix Exception
- Kritik production hatalarinda hotfix dogrudan `main` uzerinden alinabilir
- Minimum degisiklik yap, testleri calistir
- Push sonrasi exact commit durumunu `python3 scripts/check_remote_status.py` ile dogrula

## Operational Notes
- GitHub Actions branch filtreleri main-only akisa gore tutulmali
- Branch protection required check listesi CI job isimleri degisince guncellenmeli
- Remote branch listesini temizlerken once `git ls-remote --heads origin` ile oku, sonra `git push origin --delete <branch>` kullan
- Silme sonrasi `git fetch --prune origin` ve `git branch -r` ile yerel remote-tracking kalintilarini temizle

> **Ilgili**: git-rules.md (commit format, branch naming), ai-workflow.md (kalite kapilari), release-ops.md (deploy akisi)
