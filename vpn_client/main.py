import sys
import os

current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

def main():
    if "--cli" in sys.argv:
        import vpn_cli
        vpn_cli.main()
    else:
        try:
            import vpn_gui
            vpn_gui.main()
        except Exception as e:
            import traceback
            err = traceback.format_exc()
            with open(os.path.join(current_dir, "crash.log"), "w", encoding="utf-8") as f:
                f.write(err)
            print(f"Ошибка запуска GUI:\n{err}")
            if sys.stdin and sys.stdin.isatty():
                import vpn_cli
                vpn_cli.main()

if __name__ == "__main__":
    main()
