import os
import sys
import urllib.request

from PyQt5.QtCore import QUrl, QTimer, Qt
from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QVBoxLayout, QHBoxLayout, QPushButton, QWidget, QSizePolicy
)
from PyQt5.QtWebEngineWidgets import QWebEngineView
from PyQt5.QtGui import QIcon, QPixmap

# Force disable GPU for Virtual Machines
os.environ["QTWEBENGINE_CHROMIUM_FLAGS"] = "--disable-gpu"

class Browser(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Star Campus")
        self.setGeometry(0, 0, 1920, 1080)

        # Main container widget
        self.container = QWidget()
        self.setCentralWidget(self.container)

        # Main vertical layout
        self.main_layout = QVBoxLayout()
        self.main_layout.setContentsMargins(0, 0, 0, 0) 
        self.main_layout.setSpacing(0)                   
        self.container.setLayout(self.main_layout)


        # Create the web view
        self.webview = QWebEngineView()
        self.webview.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)

        # Create nav bar layout (horizontal)
        self.navbar_layout = QHBoxLayout()

        # Create buttons
        self.home_btn = QPushButton()
        self.back_btn = QPushButton()
        self.close_btn = QPushButton()
        
        self.home_btn.setToolTip("Página de Login")
        self.back_btn.setToolTip("Voltar")
        self.close_btn.setToolTip("Fechar sessão")


        # Apply SVG Icons (previous ones as SVGs in memory)
        self.home_btn.setIcon(self.svg_icon('''
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M3 12 L12 3 L21 12" />
            <path d="M5 12 V21 H19 V12" />
            </svg>
        '''))
        self.back_btn.setIcon(self.svg_icon('''
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="15 18 9 12 15 6"></polyline></svg>
        '''))
        self.close_btn.setIcon(self.svg_icon('''
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
        '''))

        # Apply button style
        button_style = """
            QPushButton {
                background-color: #3ea899;
                border: none;
                border-radius: 8px;
                padding: 10px 20px;
                margin: 6px;
            }
            QPushButton:hover {
                background-color: #086c4f;
            }
        """
        self.home_btn.setStyleSheet(button_style)
        self.back_btn.setStyleSheet(button_style)
        self.close_btn.setStyleSheet(button_style)

        # Connect button actions
        self.home_btn.clicked.connect(self.go_home)
        self.back_btn.clicked.connect(self.go_back)
        self.close_btn.clicked.connect(self.close_browser)

        # Add buttons to navbar layout
        self.navbar_layout.addStretch()
        self.navbar_layout.addWidget(self.home_btn)
        self.navbar_layout.addWidget(self.back_btn)
        self.navbar_layout.addWidget(self.close_btn)
        self.navbar_layout.addStretch()

        # Add webview and navbar to main layout
        self.main_layout.addWidget(self.webview)
        self.main_layout.addLayout(self.navbar_layout)

        # Load initial page
        self.webview.setUrl(QUrl("https://starteam.grupoiberostar.com/pt/sessao/novo"))

        # Connection monitor
        self.timer = QTimer()
        self.timer.timeout.connect(self.check_connection)
        self.timer.start(5000)

        # Set Fullscreen
        self.showFullScreen()

    def svg_icon(self, svg_content):
        from PyQt5.QtSvg import QSvgRenderer
        from PyQt5.QtGui import QPixmap, QPainter

        svg_renderer = QSvgRenderer(bytearray(svg_content.encode()))
        image = QPixmap(64, 64)
        image.fill(Qt.transparent)
        painter = QPainter(image)
        svg_renderer.render(painter)
        painter.end()

        return QIcon(image)

    def go_home(self):
        self.webview.setUrl(QUrl("https://starteam.grupoiberostar.com/pt/sessao/novo"))

    def go_back(self):
        self.webview.back()

    def close_browser(self):
        self.close()

    def check_connection(self):
        try:
            urllib.request.urlopen("https://www.google.com", timeout=5)
        except:
            print("Conexão Perdida! Recarregando página...")
            self.webview.reload()

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = Browser()
    sys.exit(app.exec_())
