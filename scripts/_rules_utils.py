"""Paylasilan yardimci sinif ve fonksiyonlar: Colors, check, section_factory."""


class Colors:
    GREEN = "\033[92m"
    RED = "\033[91m"
    YELLOW = "\033[93m"
    CYAN = "\033[96m"
    RESET = "\033[0m"
    BOLD = "\033[1m"


def check(description: str, expected: int, actual: int, tolerance: int = 0) -> bool:
    """Tek kontrol yap, PASS/FAIL yazdir ve sonucu dondur."""
    passed = abs(actual - expected) <= tolerance
    status = f"{Colors.GREEN}PASS{Colors.RESET}" if passed else f"{Colors.RED}FAIL{Colors.RESET}"
    detail = f"beklenen={expected}, gercek={actual}"
    if not passed:
        detail += f" {Colors.RED}(fark: {actual - expected:+d}){Colors.RESET}"
    print(f"  [{status}] {description}: {detail}")
    return passed


def section_factory():
    """Otomatik artan bolum numarasi icin baglanti kurar.

    Dondurur: (section_fn, counter) tuple'i.
      - section_fn(title): baslikli bolum string'i formatlar
      - counter: iter(range(1, 99)) — dogrudan next() icin kullanilabilir
    """
    counter = iter(range(1, 99))

    def _fn(title: str) -> str:
        return f"\n{Colors.BOLD}{next(counter)}. {title}{Colors.RESET}"

    return _fn, counter
