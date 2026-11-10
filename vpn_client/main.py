import sys

def main():
    if "--cli" in sys.argv:
        import vpn_cli
        vpn_cli.main()
    else:
        try:
            import vpn_gui
            vpn_gui.main()
        except Exception as e:
            print(f"Ошибка запуска GUI ({e}), переключение в режим CLI...")
            import vpn_cli
            vpn_cli.main()

if __name__ == "__main__":
    main()
