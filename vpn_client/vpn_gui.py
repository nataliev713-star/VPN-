import os
import sys
import time
import json
import socket
import urllib.request
from typing import Optional, List, Dict

from PyQt6.QtCore import Qt, QThread, pyqtSignal, QTimer, QSize
from PyQt6.QtGui import QFont, QColor, QIcon, QCursor
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QLabel, QPushButton, QComboBox, QCheckBox, QFrame, QTextEdit,
    QGraphicsDropShadowEffect, QMessageBox
)

from config import SOCKS_PORT, HTTP_PORT
from parser import fetch_servers, VlessServer
from xray_manager import XrayManager
from system_proxy import enable_system_proxy, disable_system_proxy, get_proxy_status


# --- Вспомогательные потоки (Worker Threads) ---

class ConnectWorker(QThread):
    finished = pyqtSignal(bool, str)

    def __init__(self, manager: XrayManager, server: VlessServer):
        super().__init__()
        self.manager = manager
        self.server = server

    def run(self):
        success, msg = self.manager.start(self.server)
        self.finished.emit(success, msg)


class IpCheckWorker(QThread):
    finished = pyqtSignal(dict)

    def __init__(self, manager: XrayManager):
        super().__init__()
        self.manager = manager

    def run(self):
        info = self.manager.check_ip_info()
        self.finished.emit(info)


class PingWorker(QThread):
    ping_updated = pyqtSignal(int, int) # server_id, latency_ms
    finished = pyqtSignal()

    def __init__(self, servers: List[VlessServer]):
        super().__init__()
        self.servers = servers

    def run(self):
        for s in self.servers:
            latency = XrayManager.test_tcp_ping(s.host, s.port, timeout=2.0)
            if latency is not None:
                self.ping_updated.emit(s.id, latency)
        self.finished.emit()


class RefreshSubscriptionWorker(QThread):
    finished = pyqtSignal(list, str)

    def run(self):
        try:
            servers = fetch_servers(force_refresh=True)
            self.finished.emit(servers, "")
        except Exception as e:
            self.finished.emit([], str(e))


# --- Главное окно приложения ---

class ModernVpnWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.manager = XrayManager()
        self.servers: List[VlessServer] = []
        self.ping_map: Dict[int, int] = {}

        self.conn_time_sec = 0
        self.timer = QTimer(self)
        self.timer.timeout.connect(self._update_timer)

        self.init_ui()
        self.apply_styles()
        self._load_servers_initial()

    def init_ui(self):
        self.setWindowTitle("Pink Service VPN — NextGen Client")
        self.setFixedSize(680, 720)

        central_widget = QWidget(self)
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)
        main_layout.setContentsMargins(24, 20, 24, 20)
        main_layout.setSpacing(16)

        # 1. Шапка (Header)
        header_layout = QHBoxLayout()
        header_layout.setSpacing(12)

        logo_label = QLabel("🛡️")
        logo_label.setStyleSheet("font-size: 28px;")
        header_layout.addWidget(logo_label)

        title_vbox = QVBoxLayout()
        title_vbox.setSpacing(2)
        app_title = QLabel("Pink Service VPN")
        app_title.setObjectName("AppTitle")
        app_subtitle = QLabel("Xray-Core v26.11 • VLESS Reality • High-Speed Anti-Censorship")
        app_subtitle.setObjectName("AppSubtitle")
        title_vbox.addWidget(app_title)
        title_vbox.addWidget(app_subtitle)
        header_layout.addLayout(title_vbox)

        header_layout.addStretch()

        self.badge_status = QLabel("● ОТКЛЮЧЕНО")
        self.badge_status.setObjectName("BadgeDisconnected")
        header_layout.addWidget(self.badge_status)

        main_layout.addLayout(header_layout)

        # 2. Карточка статуса и Главная кнопка (Hero Status Card)
        self.hero_card = QFrame()
        self.hero_card.setObjectName("HeroCard")
        hero_layout = QVBoxLayout(self.hero_card)
        hero_layout.setContentsMargins(20, 20, 20, 20)
        hero_layout.setSpacing(14)

        # Инфо подключенного сервера и таймер
        info_row = QHBoxLayout()
        self.lbl_server_active = QLabel("Выберите сервер для подключения")
        self.lbl_server_active.setObjectName("ActiveServerText")
        info_row.addWidget(self.lbl_server_active)
        info_row.addStretch()

        self.lbl_timer = QLabel("00:00:00")
        self.lbl_timer.setObjectName("TimerText")
        info_row.addWidget(self.lbl_timer)
        hero_layout.addLayout(info_row)

        # Большая кнопка подключения
        self.btn_power = QPushButton("ПОДКЛЮЧИТЬСЯ")
        self.btn_power.setObjectName("PowerButtonConnect")
        self.btn_power.setCursor(QCursor(Qt.CursorShape.PointingHandCursor))
        self.btn_power.setFixedHeight(54)
        self.btn_power.clicked.connect(self.on_toggle_power)
        hero_layout.addWidget(self.btn_power)

        # Плашка IP и Геолокации
        ip_row = QHBoxLayout()
        self.lbl_ip_info = QLabel("🌐 IP: Не защищен (VPN выключен)")
        self.lbl_ip_info.setObjectName("IpInfoText")
        ip_row.addWidget(self.lbl_ip_info)
        ip_row.addStretch()

        self.btn_check_ip = QPushButton("Проверить IP")
        self.btn_check_ip.setObjectName("SmallButton")
        self.btn_check_ip.setCursor(QCursor(Qt.CursorShape.PointingHandCursor))
        self.btn_check_ip.clicked.connect(self.on_check_ip)
        ip_row.addWidget(self.btn_check_ip)

        hero_layout.addLayout(ip_row)
        main_layout.addWidget(self.hero_card)

        # 3. Карточка выбора локации (Server Select Card)
        server_card = QFrame()
        server_card.setObjectName("ContentCard")
        server_layout = QVBoxLayout(server_card)
        server_layout.setContentsMargins(18, 16, 18, 16)
        server_layout.setSpacing(12)

        srv_header = QHBoxLayout()
        srv_title = QLabel("📍 Выбор локации сервера")
        srv_title.setObjectName("CardTitle")
        srv_header.addWidget(srv_title)
        srv_header.addStretch()

        self.btn_ping_all = QPushButton("⚡ Измерить пинг")
        self.btn_ping_all.setObjectName("SmallButton")
        self.btn_ping_all.setCursor(QCursor(Qt.CursorShape.PointingHandCursor))
        self.btn_ping_all.clicked.connect(self.on_ping_all)
        srv_header.addWidget(self.btn_ping_all)

        self.btn_refresh_sub = QPushButton("🔄 Обновить")
        self.btn_refresh_sub.setObjectName("SmallButton")
        self.btn_refresh_sub.setCursor(QCursor(Qt.CursorShape.PointingHandCursor))
        self.btn_refresh_sub.clicked.connect(self.on_refresh_subscription)
        srv_header.addWidget(self.btn_refresh_sub)
        server_layout.addLayout(srv_header)

        self.combo_servers = QComboBox()
        self.combo_servers.setObjectName("ServerComboBox")
        self.combo_servers.setFixedHeight(44)
        server_layout.addWidget(self.combo_servers)

        main_layout.addWidget(server_card)

        # 4. Настройки сети и системного прокси
        settings_card = QFrame()
        settings_card.setObjectName("ContentCard")
        settings_layout = QVBoxLayout(settings_card)
        settings_layout.setContentsMargins(18, 16, 18, 16)
        settings_layout.setSpacing(10)

        self.chk_sys_proxy = QCheckBox("Использовать как системный прокси Windows (весь трафик ПК через VPN)")
        self.chk_sys_proxy.setObjectName("ModernCheckBox")
        self.chk_sys_proxy.setChecked(True)
        self.chk_sys_proxy.toggled.connect(self.on_toggle_sys_proxy)
        settings_layout.addWidget(self.chk_sys_proxy)

        ports_layout = QHBoxLayout()
        ports_label = QLabel(f"Локальные порты: SOCKS5: 127.0.0.1:{SOCKS_PORT}  |  HTTP: 127.0.0.1:{HTTP_PORT}")
        ports_label.setStyleSheet("color: #64748b; font-size: 11px;")
        ports_layout.addWidget(ports_label)
        ports_layout.addStretch()
        bypass_label = QLabel("Прямой роутинг: Локальная сеть (RFC1918)")
        bypass_label.setStyleSheet("color: #64748b; font-size: 11px;")
        ports_layout.addWidget(bypass_label)
        settings_layout.addLayout(ports_layout)

        main_layout.addWidget(settings_card)

        # 5. Лог событий (Console Log)
        log_card = QFrame()
        log_card.setObjectName("ContentCard")
        log_layout = QVBoxLayout(log_card)
        log_layout.setContentsMargins(16, 12, 16, 12)
        log_layout.setSpacing(6)

        log_title = QLabel("💻 Журнал событий")
        log_title.setObjectName("CardSubTitle")
        log_layout.addWidget(log_title)

        self.txt_log = QTextEdit()
        self.txt_log.setObjectName("LogConsole")
        self.txt_log.setReadOnly(True)
        self.txt_log.setFixedHeight(110)
        log_layout.addWidget(self.txt_log)

        main_layout.addWidget(log_card)

    def apply_styles(self):
        stylesheet = """
            QMainWindow {
                background-color: #0b0f19;
            }
            QWidget {
                color: #e2e8f0;
                font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
            }
            #AppTitle {
                font-size: 19px;
                font-weight: 700;
                color: #ffffff;
                letter-spacing: 0.5px;
            }
            #AppSubtitle {
                font-size: 11px;
                color: #64748b;
                font-weight: 500;
            }
            #BadgeDisconnected {
                background-color: rgba(239, 68, 68, 0.15);
                color: #ef4444;
                border: 1px solid rgba(239, 68, 68, 0.3);
                border-radius: 12px;
                padding: 5px 12px;
                font-size: 11px;
                font-weight: 700;
            }
            #BadgeConnected {
                background-color: rgba(16, 185, 129, 0.15);
                color: #10b981;
                border: 1px solid rgba(16, 185, 129, 0.4);
                border-radius: 12px;
                padding: 5px 12px;
                font-size: 11px;
                font-weight: 700;
            }
            #BadgeConnecting {
                background-color: rgba(245, 158, 11, 0.15);
                color: #f59e0b;
                border: 1px solid rgba(245, 158, 11, 0.3);
                border-radius: 12px;
                padding: 5px 12px;
                font-size: 11px;
                font-weight: 700;
            }
            #HeroCard {
                background: qlineargradient(x1:0, y1:0, x2:1, y2:1, stop:0 #131d2e, stop:1 #172439);
                border: 1px solid #23354e;
                border-radius: 16px;
            }
            #ContentCard {
                background-color: #111827;
                border: 1px solid #1f293d;
                border-radius: 14px;
            }
            #CardTitle {
                font-size: 14px;
                font-weight: 600;
                color: #f1f5f9;
            }
            #CardSubTitle {
                font-size: 12px;
                font-weight: 600;
                color: #94a3b8;
            }
            #ActiveServerText {
                font-size: 15px;
                font-weight: 600;
                color: #f8fafc;
            }
            #TimerText {
                font-size: 14px;
                font-weight: 700;
                color: #38bdf8;
                font-family: 'Consolas', monospace;
            }
            #IpInfoText {
                font-size: 12px;
                color: #94a3b8;
            }
            #PowerButtonConnect {
                background: qlineargradient(x1:0, y1:0, x2:1, y2:0, stop:0 #2563eb, stop:1 #3b82f6);
                color: #ffffff;
                font-size: 14px;
                font-weight: 700;
                letter-spacing: 1px;
                border: none;
                border-radius: 12px;
            }
            #PowerButtonConnect:hover {
                background: qlineargradient(x1:0, y1:0, x2:1, y2:0, stop:0 #1d4ed8, stop:1 #2563eb);
            }
            #PowerButtonConnect:pressed {
                background-color: #1e40af;
            }
            #PowerButtonDisconnect {
                background: qlineargradient(x1:0, y1:0, x2:1, y2:0, stop:0 #dc2626, stop:1 #ef4444);
                color: #ffffff;
                font-size: 14px;
                font-weight: 700;
                letter-spacing: 1px;
                border: none;
                border-radius: 12px;
            }
            #PowerButtonDisconnect:hover {
                background: qlineargradient(x1:0, y1:0, x2:1, y2:0, stop:0 #b91c1c, stop:1 #dc2626);
            }
            #SmallButton {
                background-color: #1e293b;
                border: 1px solid #334155;
                color: #cbd5e1;
                font-size: 11px;
                font-weight: 600;
                padding: 6px 12px;
                border-radius: 8px;
            }
            #SmallButton:hover {
                background-color: #334155;
                color: #ffffff;
            }
            #ServerComboBox {
                background-color: #1e293b;
                border: 1px solid #334155;
                border-radius: 10px;
                padding: 6px 12px;
                font-size: 13px;
                color: #f8fafc;
            }
            #ServerComboBox:hover {
                border-color: #475569;
            }
            #ServerComboBox::drop-down {
                border: none;
                width: 28px;
            }
            #ServerComboBox QAbstractItemView {
                background-color: #1e293b;
                border: 1px solid #334155;
                selection-background-color: #2563eb;
                selection-color: #ffffff;
                color: #f8fafc;
                padding: 4px;
            }
            #ModernCheckBox {
                font-size: 12px;
                color: #e2e8f0;
                spacing: 8px;
            }
            #ModernCheckBox::indicator {
                width: 18px;
                height: 18px;
                border: 1px solid #475569;
                border-radius: 5px;
                background-color: #1e293b;
            }
            #ModernCheckBox::indicator:checked {
                background-color: #2563eb;
                border-color: #3b82f6;
            }
            #LogConsole {
                background-color: #080c14;
                border: 1px solid #1e293b;
                border-radius: 8px;
                color: #94a3b8;
                font-family: 'Consolas', monospace;
                font-size: 11px;
                padding: 6px;
            }
        """
        self.setStyleSheet(stylesheet)

    def log(self, msg: str):
        timestamp = time.strftime("%H:%M:%S")
        self.txt_log.append(f"[{timestamp}] {msg}")
        self.txt_log.verticalScrollBar().setValue(self.txt_log.verticalScrollBar().maximum())

    def _load_servers_initial(self):
        self.log("Инициализация: чтение серверов из кэша...")
        try:
            self.servers = fetch_servers(force_refresh=False)
            self._rebuild_combobox()
            self.log(f"Готово: загружено {len(self.servers)} серверов.")
        except Exception as e:
            self.log(f"Ошибка загрузки серверов: {e}")

    def _rebuild_combobox(self):
        curr_idx = self.combo_servers.currentIndex()
        self.combo_servers.clear()
        for s in self.servers:
            ping_text = f" • {self.ping_map[s.id]} ms" if s.id in self.ping_map else ""
            self.combo_servers.addItem(f"{s.id:2d}. {s.name}{ping_text}")
        if 0 <= curr_idx < len(self.servers):
            self.combo_servers.setCurrentIndex(curr_idx)
        elif self.servers:
            self.combo_servers.setCurrentIndex(0)

    def on_toggle_power(self):
        if self.manager.is_running():
            self._disconnect_vpn()
        else:
            self._connect_vpn()

    def _connect_vpn(self):
        idx = self.combo_servers.currentIndex()
        if idx < 0 or idx >= len(self.servers):
            QMessageBox.warning(self, "Внимание", "Пожалуйста, выберите сервер из списка.")
            return

        server = self.servers[idx]
        self.badge_status.setText("⏳ ПОДКЛЮЧЕНИЕ...")
        self.badge_status.setObjectName("BadgeConnecting")
        self.apply_styles()
        self.btn_power.setEnabled(False)

        self.log(f"Подключение к {server.name} ({server.host}:{server.port})...")

        self.conn_worker = ConnectWorker(self.manager, server)
        self.conn_worker.finished.connect(lambda ok, msg: self._on_connect_finished(ok, msg, server))
        self.conn_worker.start()

    def _on_connect_finished(self, ok: bool, msg: str, server: VlessServer):
        self.btn_power.setEnabled(True)
        if ok:
            if self.chk_sys_proxy.isChecked():
                enable_system_proxy(port=HTTP_PORT)
                self.log("Системный прокси Windows активирован.")

            self.badge_status.setText("🟢 ЗАЩИЩЕНО")
            self.badge_status.setObjectName("BadgeConnected")
            self.lbl_server_active.setText(f"Подключено: {server.name}")
            self.btn_power.setText("ОТКЛЮЧИТЬСЯ")
            self.btn_power.setObjectName("PowerButtonDisconnect")
            self.apply_styles()

            self.conn_time_sec = 0
            self.timer.start(1000)

            self.log(f"✓ {msg}")
            # Автопроверка внешнего IP в фоне
            self.on_check_ip()
        else:
            self.badge_status.setText("● ОШИБКА")
            self.badge_status.setObjectName("BadgeDisconnected")
            self.apply_styles()
            self.log(f"✗ Ошибка: {msg}")
            QMessageBox.critical(self, "Ошибка подключения", msg)

    def _disconnect_vpn(self):
        self.manager.stop()
        disable_system_proxy()
        self.timer.stop()
        self.lbl_timer.setText("00:00:00")

        self.badge_status.setText("● ОТКЛЮЧЕНО")
        self.badge_status.setObjectName("BadgeDisconnected")
        self.lbl_server_active.setText("Выберите сервер для подключения")
        self.lbl_ip_info.setText("🌐 IP: Не защищен (VPN выключен)")
        self.btn_power.setText("ПОДКЛЮЧИТЬСЯ")
        self.btn_power.setObjectName("PowerButtonConnect")
        self.apply_styles()

        self.log("VPN отключен. Системный прокси Windows сброшен.")

    def _update_timer(self):
        self.conn_time_sec += 1
        h = self.conn_time_sec // 3600
        m = (self.conn_time_sec % 3600) // 60
        s = self.conn_time_sec % 60
        self.lbl_timer.setText(f"{h:02d}:{m:02d}:{s:02d}")

    def on_check_ip(self):
        if not self.manager.is_running():
            self.lbl_ip_info.setText("🌐 VPN не запущен")
            return

        self.lbl_ip_info.setText("🌐 Запрос реального IP...")
        self.ip_worker = IpCheckWorker(self.manager)
        self.ip_worker.finished.connect(self._on_ip_checked)
        self.ip_worker.start()

    def _on_ip_checked(self, info: dict):
        if "error" in info:
            self.lbl_ip_info.setText(f"🌐 Ошибка IP: {info['error']}")
            self.log(f"Ошибка проверки внешнего IP: {info['error']}")
        else:
            ip = info.get("ip", "—")
            country = info.get("country", "")
            city = info.get("city", "")
            org = info.get("org", "")
            info_str = f"🌐 Внешний IP: {ip} • {country}, {city} ({org})"
            self.lbl_ip_info.setText(info_str)
            self.log(f"Внешний IP подтвержден: {ip} [{country}, {city}]")

    def on_ping_all(self):
        self.log("Старт измерения пинга до серверов...")
        self.btn_ping_all.setEnabled(False)
        self.ping_worker = PingWorker(self.servers)
        self.ping_worker.ping_updated.connect(self._on_single_ping_update)
        self.ping_worker.finished.connect(self._on_ping_finished)
        self.ping_worker.start()

    def _on_single_ping_update(self, server_id: int, latency: int):
        self.ping_map[server_id] = latency

    def _on_ping_finished(self):
        self.btn_ping_all.setEnabled(True)
        self._rebuild_combobox()
        self.log("Тест задержки (ping) завершен.")

    def on_refresh_subscription(self):
        self.log("Обновление списка серверов с сервера подписки...")
        self.btn_refresh_sub.setEnabled(False)
        self.ref_worker = RefreshSubscriptionWorker()
        self.ref_worker.finished.connect(self._on_refresh_finished)
        self.ref_worker.start()

    def _on_refresh_finished(self, servers: list, err: str):
        self.btn_refresh_sub.setEnabled(True)
        if err:
            self.log(f"Ошибка при обновлении подписки: {err}")
            QMessageBox.critical(self, "Ошибка", f"Не удалось обновить: {err}")
        else:
            self.servers = servers
            self.ping_map.clear()
            self._rebuild_combobox()
            self.log(f"Подписка успешно обновлена! Найдено {len(servers)} серверов.")

    def on_toggle_sys_proxy(self, checked: bool):
        if self.manager.is_running():
            if checked:
                enable_system_proxy(port=HTTP_PORT)
                self.log("Системный прокси Windows включен.")
            else:
                disable_system_proxy()
                self.log("Системный прокси Windows выключен (прямой трафик приложений).")

    def closeEvent(self, event):
        self.manager.stop()
        disable_system_proxy()
        event.accept()


def main():
    app = QApplication(sys.argv)
    window = ModernVpnWindow()
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
