import sys
import os
import time
from parser import fetch_servers, VlessServer
from xray_manager import XrayManager
from system_proxy import enable_system_proxy, disable_system_proxy, get_proxy_status
from config import SOCKS_PORT, HTTP_PORT

# Включение поддержки ANSI цветов в консоли Windows
if os.name == "nt":
    os.system("color")

CYAN = "\033[96m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
BOLD = "\033[1m"
RESET = "\033[0m"

def print_banner():
    print(f"{CYAN}{BOLD}")
    print("=" * 60)
    print("           PINK SERVICE VPN CLIENT / ОБОЛОЧКА             ")
    print("=" * 60)
    print(f"{RESET}")

def print_status(manager: XrayManager):
    running = manager.is_running()
    proxy_active = get_proxy_status()
    print(f"{BOLD}Текущее состояние:{RESET}")
    if running and manager.current_server:
        print(f"  ● Статус ядра:   {GREEN}ПОДКЛЮЧЕНО{RESET} к {BOLD}{manager.current_server.name}{RESET}")
        print(f"  ● Порты:         SOCKS5: 127.0.0.1:{SOCKS_PORT} | HTTP: 127.0.0.1:{HTTP_PORT}")
    else:
        print(f"  ● Статус ядра:   {RED}ОТКЛЮЧЕНО{RESET}")

    sys_status_str = f"{GREEN}ВКЛЮЧЕН (весь трафик Windows через VPN){RESET}" if proxy_active else f"{YELLOW}ВЫКЛЮЧЕН (только локальные порты){RESET}"
    print(f"  ● Системный прокси: {sys_status_str}")
    print("-" * 60)

def main():
    manager = XrayManager()
    servers = fetch_servers()

    while True:
        os.system("cls" if os.name == "nt" else "clear")
        print_banner()
        print_status(manager)

        print(f"{BOLD}Меню действий:{RESET}")
        print(f"  [{CYAN}1{RESET}] Выбрать и подключить сервер")
        print(f"  [{CYAN}2{RESET}] Отключить VPN")
        print(f"  [{CYAN}3{RESET}] Переключить системный прокси Windows (Вкл/Выкл)")
        print(f"  [{CYAN}4{RESET}] Проверить реальный IP и геолокацию")
        print(f"  [{CYAN}5{RESET}] Измерить пинг до всех серверов")
        print(f"  [{CYAN}6{RESET}] Обновить подписку с сервера")
        print(f"  [{CYAN}0{RESET}] Выход")
        print("-" * 60)

        choice = input(f"{BOLD}Введите номер действия > {RESET}").strip()

        if choice == "1":
            print(f"\n{BOLD}Доступные серверы ({len(servers)}):{RESET}")
            for s in servers:
                print(f"  {CYAN}{s.id:2d}{RESET}. {s.name} ({s.host}:{s.port})")
            srv_idx = input(f"\n{BOLD}Введите номер сервера для подключения (0 - отмена): {RESET}").strip()
            if srv_idx.isdigit() and int(srv_idx) > 0:
                idx = int(srv_idx)
                selected = next((s for s in servers if s.id == idx), None)
                if selected:
                    print(f"\nПодключение к {selected.name}...")
                    success, msg = manager.start(selected)
                    if success:
                        enable_system_proxy(port=HTTP_PORT)
                        print(f"{GREEN}✓ {msg}{RESET}")
                        print(f"{GREEN}✓ Системный прокси Windows активирован!{RESET}")
                    else:
                        print(f"{RED}✗ Ошибка подключения: {msg}{RESET}")
                else:
                    print(f"{RED}Сервер с номером {idx} не найден.{RESET}")
            input("\nНажмите Enter для продолжения...")

        elif choice == "2":
            manager.stop()
            disable_system_proxy()
            print(f"\n{YELLOW}VPN отключен, системный прокси сброшен.{RESET}")
            time.sleep(1)

        elif choice == "3":
            if get_proxy_status():
                disable_system_proxy()
                print(f"\n{YELLOW}Системный прокси Windows отключен.{RESET}")
            else:
                enable_system_proxy(port=HTTP_PORT)
                print(f"\n{GREEN}Системный прокси Windows включен на 127.0.0.1:{HTTP_PORT}!{RESET}")
            time.sleep(1)

        elif choice == "4":
            print(f"\n{BOLD}Запрос геолокации...{RESET}")
            info = manager.check_ip_info()
            if "error" in info:
                print(f"{RED}Ошибка получения информации об IP: {info['error']}{RESET}")
            else:
                print(f"{GREEN}IP:{RESET}       {info.get('ip')}")
                print(f"{GREEN}Страна:{RESET}   {info.get('country')}")
                print(f"{GREEN}Город:{RESET}    {info.get('city')}")
                print(f"{GREEN}Провайдер:{RESET}{info.get('org')}")
            input("\nНажмите Enter для продолжения...")

        elif choice == "5":
            print(f"\n{BOLD}Тестирование пинга до серверов...{RESET}")
            for s in servers:
                p = XrayManager.test_tcp_ping(s.host, s.port)
                p_str = f"{GREEN}{p:4d} ms{RESET}" if p is not None else f"{RED}timeout{RESET}"
                print(f"  {CYAN}{s.id:2d}{RESET}. {s.name:<30} {p_str}")
            input("\nНажмите Enter для продолжения...")

        elif choice == "6":
            print(f"\n{BOLD}Загрузка актуального списка подписки...{RESET}")
            try:
                servers = fetch_servers(force_refresh=True)
                print(f"{GREEN}✓ Успешно загружено {len(servers)} серверов!{RESET}")
            except Exception as e:
                print(f"{RED}✗ Ошибка обновления: {e}{RESET}")
            time.sleep(1.5)

        elif choice == "0":
            manager.stop()
            disable_system_proxy()
            print(f"\n{CYAN}Завершение работы.{RESET}")
            sys.exit(0)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        disable_system_proxy()
        print("\nПрервано пользователем. Выход...")
