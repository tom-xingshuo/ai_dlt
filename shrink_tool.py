# -*- coding: utf-8 -*-
"""大乐透前区缩水工具（PyQt5）

运行环境: conda py311 (D:\\app\\miniconda3\\envs\\py311\\python.exe)

支持缩水条件:
    杀号 / AC值区间 / 龙头中间凤尾分区出号 / 五行(洛书)分区出号 / 五行(易经)分区出号 /
    5分区出号 / 4分区出号 / 7分区出号与跨区 / 5区边缘码 / 7区边缘码 /
    和值区间 / 跨度区间 / 奇偶比 / 大小比 / 质合比 / 五行尾数 / 红蓝绿波
    012路 / 除7余数与跨区 / 尾数之和 / 连号组数与长度 / 尾数种类 / 胆码 / 重号与邻号(对比上期)
"""

import json
import os
import re
import shutil
import sys
import threading
import time
import urllib.request

from PyQt5.QtCore import QPoint, QSettings, Qt, pyqtSignal
from PyQt5.QtGui import QColor, QFont, QImage, QPainter, QPen
from PyQt5.QtWidgets import (
    QApplication, QAbstractButton, QCheckBox, QFileDialog, QFrame,
    QGridLayout, QGroupBox, QHBoxLayout, QHeaderView, QLabel, QLineEdit,
    QMainWindow, QPushButton, QScrollArea, QSpinBox, QTableWidget,
    QTableWidgetItem, QTabWidget, QVBoxLayout, QWidget,
)

# 内嵌全量数据(full_data.py, 打包exe时无需外部txt)
try:
    import full_data
except ImportError:
    full_data = None

from utils.calcute_funcs import (
    BIG_BOUNDARY, DAN_GROUPS, FilterConditions, FIVE_DEFAULTS, FIVE_ZONES,
    FOUR_DEFAULTS, FOUR_ZONES, SAN_PATTERNS, SAN_RANGES, SAN_TIER_NAMES,
    SEVEN_DEFAULTS, SEVEN_SPAN_DEFAULT, SEVEN_ZONES, TAIL_COLOR,
    TAIL_COLOR_DEFAULTS, TAIL_WX, TAIL_WX_DEFAULTS, WAVE_DEFAULTS,
    WAVE_ZONES, WX_ZONES, YJ_DEFAULTS,
    YJ_ZONES, ac_value,
)

DEFAULT_SAVE = r"E:\app2\ai_dlt\front_numbers_shrunk.txt"
# 体彩官网开奖结果API(gameNo=85为大乐透), 需带浏览器请求头否则被拦截
LOTTERY_API = ("https://webapi.sporttery.cn/gateway/lottery/getHistoryPageListV1.qry"
               "?gameNo=85&provinceId=0&pageSize=1&isVerify=1&pageNo=1")
# 配置文件存放在用户目录(打包exe后不依赖程序所在目录的写权限)
_CONFIG_DIR = os.path.join(os.path.expanduser("~"), ".ai_dlt")
SETTINGS_FILE = os.path.join(_CONFIG_DIR, "shrink_ui_state.ini")
_LEGACY_SETTINGS_FILE = r"E:\app\ai_dlt\shrink_ui_state.ini"  # 旧版本位置, 用于自动迁移
PREVIEW_ROWS = 2000  # 表格最多预览行数


def _make_check_png():
    """生成白色对勾图标(选中复选框用), 保存到配置目录, 失败返回空串"""
    try:
        os.makedirs(_CONFIG_DIR, exist_ok=True)
        path = os.path.join(_CONFIG_DIR, "check.png")
        if not os.path.exists(path):
            # 用 QImage 而非 QPixmap: 模块导入时尚未创建 QApplication, QPixmap 会失败
            img = QImage(13, 13, QImage.Format_ARGB32)
            img.fill(Qt.transparent)
            p = QPainter(img)
            p.setRenderHint(QPainter.Antialiasing)
            pen = QPen(QColor("#ffffff"), 2, Qt.SolidLine, Qt.RoundCap, Qt.RoundJoin)
            p.setPen(pen)
            p.drawPolyline([QPoint(3, 7), QPoint(6, 10), QPoint(10, 3)])
            p.end()
            img.save(path, "PNG")
        return path
    except Exception:
        return ""


_CHECK_PNG = _make_check_png()

# 简单样式
STYLE_SHEET = """
QWidget { font-family: "Microsoft YaHei UI"; font-size: 9pt; color: #1f2d38; }
QMainWindow, QDialog { background: #f4f6f8; }
QToolTip { background: #2d3b45; color: #fff; border: none; padding: 4px 8px; border-radius: 4px; }

QGroupBox {
    font-weight: bold; color: #0a7d43;  /* 标题加粗变色(仅作用于标题, 子控件由下方QWidget规则重置) */
    border: 1px solid #dde3ea; border-radius: 6px;
    margin-top: 14px; padding: 10px 8px 8px 8px; background: #ffffff;
}
QGroupBox::title { subcontrol-origin: margin; left: 10px; padding: 0 6px; }

QTabWidget::pane { border: 1px solid #dde3ea; border-radius: 6px; background: #ffffff; top: -1px; }
QTabBar::tab {
    background: transparent; color: #5a6b7a; padding: 6px 9px;
    margin-right: 2px; border: 1px solid transparent; border-bottom: none;
    border-top-left-radius: 6px; border-top-right-radius: 6px;
}
QTabBar::tab:hover { color: #0a7d43; background: #e9f3ee; }
QTabBar::tab:selected { color: #0a7d43; font-weight: bold; background: #ffffff;
    border-color: #dde3ea; border-bottom: 2px solid #0a7d43; }

QPushButton {
    padding: 6px 18px; background: #ffffff; color: #245b3f;
    border: 1px solid #c3cdd6; border-radius: 6px;
}
QPushButton:hover { background: #eef4f1; border-color: #0a7d43; }
QPushButton:pressed { background: #dcebe4; }
QPushButton:disabled { color: #9aa7b1; border-color: #dde3ea; background: #f2f4f6; }
QPushButton#primaryBtn {
    background: #0a7d43; color: #ffffff; font-weight: bold; border: 1px solid #0a7d43;
}
QPushButton#primaryBtn:hover { background: #086838; }
QPushButton#primaryBtn:pressed { background: #06542e; }

QLineEdit, QSpinBox {
    border: 1px solid #c3cdd6; border-radius: 4px;
    background: #ffffff; color: #1f2d38; selection-background-color: #0a7d43;
}
QLineEdit { padding: 2px 4px; }
QSpinBox { padding: 2px 2px; }
QLineEdit:focus, QSpinBox:focus { border: 1px solid #0a7d43; }
QSpinBox::up-button, QSpinBox::down-button { width: 10px; border: none; background: transparent; }
QSpinBox::up-button:hover, QSpinBox::down-button:hover { background: #e9f3ee; border-radius: 3px; }

QCheckBox { spacing: 6px; color: #1f2d38; }
QCheckBox::indicator {
    width: 15px; height: 15px; border: 1px solid #c3cdd6; border-radius: 3px; background: #fff;
}
QCheckBox::indicator:hover { border-color: #0a7d43; }
QCheckBox::indicator:checked { background: #0a7d43; border-color: #0a7d43;
    image: url(__CHECK_PNG__); }

QTableWidget {
    gridline-color: #e4e9ee; background: #ffffff; alternate-background-color: #f6faf8;
    border: 1px solid #dde3ea; border-radius: 6px; selection-background-color: #cfe6da;
    selection-color: #1f2d38;
}
QHeaderView::section {
    background: #eef2f5; color: #245b3f; font-weight: bold; padding: 5px 6px;
    border: none; border-right: 1px solid #dde3ea; border-bottom: 1px solid #dde3ea;
}

QScrollBar:vertical { background: transparent; width: 10px; margin: 2px; }
QScrollBar::handle:vertical { background: #c3cdd6; border-radius: 4px; min-height: 30px; }
QScrollBar::handle:vertical:hover { background: #0a7d43; }
QScrollBar::add-line, QScrollBar::sub-line { height: 0; width: 0; }
QScrollBar:horizontal { background: transparent; height: 10px; margin: 2px; }
QScrollBar::handle:horizontal { background: #c3cdd6; border-radius: 4px; min-width: 30px; }
QScrollBar::handle:horizontal:hover { background: #0a7d43; }

QLabel#statusLabel { font-weight: bold; color: #0a7d43; }
"""

# 注入对勾图标路径(QSS url 需正斜杠); 生成失败时移除 image 属性, 仅保留绿底
if _CHECK_PNG:
    STYLE_SHEET = STYLE_SHEET.replace("__CHECK_PNG__", _CHECK_PNG.replace("\\", "/"))
else:
    STYLE_SHEET = STYLE_SHEET.replace("    image: url(__CHECK_PNG__); ", "")


# ---------------- 最新开奖 ----------------
def fetch_latest_draw():
    """请求体彩官网API获取最新一期大乐透开奖号码。

    返回 (期号, 日期, 前区5号, 后区2号) ; 失败返回 None。
    """
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                      "(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36",
        "Accept": "application/json, text/plain, */*",
        "Referer": "https://static.sporttery.cn/",
    }
    try:
        req = urllib.request.Request(LOTTERY_API, headers=headers)
        with urllib.request.urlopen(req, timeout=8) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        item = data["value"]["lastPoolDraw"]
        all_nums = [int(x) for x in item["lotteryDrawResult"].split()]
        front, back = all_nums[:5], all_nums[5:7]
        if len(front) == 5 and len(back) == 2 and all(1 <= n <= 35 for n in front):
            return item["lotteryDrawNum"], item["lotteryDrawTime"], tuple(front), tuple(back)
    except (OSError, ValueError, KeyError, IndexError):
        pass
    return None


# ---------------- 界面 ----------------
def make_row_label(text):
    """组内行标题(如"杀号(排除):"): 加粗变色, 深绿与组标题亮绿区分层次。"""
    lbl = QLabel(text)
    lbl.setStyleSheet("font-weight: bold; color: #245b3f;")
    return lbl


def add_scroll_tab(tabs, page, name):
    """将页面包进滚动区域后加入 QTabWidget, 使标签区高度可控。"""
    sa = QScrollArea()
    sa.setWidgetResizable(True)
    sa.setFrameShape(QFrame.NoFrame)
    sa.setWidget(page)
    tabs.addTab(sa, name)


def make_ratio_group(title, tooltip):
    """生成比例选择组：0~5 个复选框, 标签为"几:几"(如 2:3)。"""
    box = QGroupBox(title)
    box.setToolTip(tooltip)
    layout = QHBoxLayout(box)
    checks = []
    for k in range(6):
        cb = QCheckBox(f"{k}:{5 - k}")
        layout.addWidget(cb)
        checks.append(cb)
    return box, checks


def make_spin(vmin, vmax, val):
    s = QSpinBox()
    s.setRange(vmin, vmax)
    s.setValue(val)
    s.setFixedWidth(44)  # 固定为原拉伸宽度(约128px)的1/3, 避免随列宽撑大
    return s


class ShrinkWindow(QMainWindow):
    _latest_ready = pyqtSignal(object)  # 开奖获取完成信号: (期号, 日期, 前区, 后区) 或 None

    def __init__(self):
        super().__init__()
        self.setWindowTitle("大乐透前区缩水工具")
        self.resize(1180, 1000)
        self.groups = []   # 全部已载入组合
        self.results = []  # 缩水结果
        self._init_ui()
        self._migrate_legacy_settings()
        self._restore_state()
        self.on_load()  # 启动时自动载入内嵌数据
        self._latest_ready.connect(self._show_latest_draw)
        self.on_fetch_latest()  # 启动时后台获取最新开奖号码

    def _init_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        root = QVBoxLayout(central)
        root.addWidget(self._build_source_box())
        root.addWidget(self._build_filters_box())

        # 操作按钮
        btn_row = QHBoxLayout()
        self.btn_shrink = QPushButton("开始缩水")
        self.btn_save = QPushButton("保存结果")
        self.btn_reset = QPushButton("重置条件")
        self.btn_shrink.setObjectName("primaryBtn")
        self.btn_shrink.clicked.connect(self.on_shrink)
        self.btn_save.clicked.connect(self.on_save)
        self.btn_reset.clicked.connect(self.on_reset)
        btn_row.addWidget(self.btn_shrink)
        btn_row.addWidget(self.btn_save)
        btn_row.addWidget(self.btn_reset)
        btn_row.addStretch(1)
        root.addLayout(btn_row)

        self.status_label = QLabel("请先载入数据")
        self.status_label.setObjectName("statusLabel")
        root.addWidget(self.status_label)

        self.table = QTableWidget(0, 5)
        self.table.setHorizontalHeaderLabels(["号码1", "号码2", "号码3", "号码4", "号码5"])
        self.table.horizontalHeader().setSectionResizeMode(QHeaderView.Stretch)
        self.table.setAlternatingRowColors(True)
        self.table.verticalHeader().setDefaultSectionSize(26)
        self.table.verticalHeader().setVisible(False)
        self.table.setEditTriggers(QTableWidget.NoEditTriggers)
        self.table.setMinimumHeight(320)
        root.addWidget(self.table, 1)

    def _build_source_box(self):
        box = QGroupBox("① 数据源")
        grid = QGridLayout(box)
        self.btn_load = QPushButton("重新载入")
        self.btn_load.clicked.connect(self.on_load)
        grid.addWidget(QLabel("全量数据(324632组)"), 0, 0)
        grid.addWidget(self.btn_load, 0, 1)

        self.latest_label = QLabel("最新开奖: 未获取")
        self.btn_latest = QPushButton("刷新")
        self.btn_latest.clicked.connect(self.on_fetch_latest)
        grid.addWidget(self.latest_label, 1, 0)
        grid.addWidget(self.btn_latest, 1, 1)
        return box

    def _build_filters_box(self):
        tabs = QTabWidget()
        tabs.setUsesScrollButtons(False)  # 页签全部平铺, 避免左右切换按钮与页签重叠
        tabs.setMaximumHeight(460)  # 限制条件区高度, 页面内容超高时滚动, 让出空间给下方表格

        # ---- 页1: 杀号/区间与比例 ----
        page1 = QWidget()
        g1 = QGridLayout(page1)
        g1.addWidget(make_row_label("杀号(排除):"), 0, 0)
        self.kill_edit = QLineEdit()
        self.kill_edit.setPlaceholderText("如: 03 11 22")
        self.kill_edit.setMaximumWidth(137)  # 约为原拉伸宽度的1/3
        g1.addWidget(self.kill_edit, 0, 1, 1, 3)

        g1.addWidget(make_row_label("AC值区间:"), 1, 0)
        self.ac_min = make_spin(0, 6, 2)
        self.ac_max = make_spin(0, 6, 6)
        g1.addWidget(self.ac_min, 1, 1)
        g1.addWidget(QLabel("~"), 1, 2)
        g1.addWidget(self.ac_max, 1, 3)

        self.chk_zone = QCheckBox("龙头-中间-凤尾分区出号(启用)")
        self.chk_zone.setToolTip(
            "龙头01~13 / 中间09~26 / 凤尾24~35, 区间可重叠:\n"
            "号码09~13同时计入龙头与中间, 24~26同时计入中间与凤尾\n"
            "不勾选=不启用该过滤")
        self.chk_zone.setChecked(True)
        g1.addWidget(self.chk_zone, 2, 0, 1, 8)

        g1.addWidget(make_row_label("龙头 01~13 出号:"), 3, 0)
        self.zone_head_min = make_spin(0, 5, 1)
        self.zone_head_max = make_spin(0, 5, 3)
        g1.addWidget(self.zone_head_min, 3, 1)
        g1.addWidget(QLabel("~"), 3, 2)
        g1.addWidget(self.zone_head_max, 3, 3)

        g1.addWidget(make_row_label("中间 09~26 出号:"), 4, 0)
        self.zone_mid_min = make_spin(0, 5, 1)
        self.zone_mid_max = make_spin(0, 5, 4)
        g1.addWidget(self.zone_mid_min, 4, 1)
        g1.addWidget(QLabel("~"), 4, 2)
        g1.addWidget(self.zone_mid_max, 4, 3)

        g1.addWidget(make_row_label("凤尾 24~35 出号:"), 5, 0)
        self.zone_tail_min = make_spin(0, 5, 1)
        self.zone_tail_max = make_spin(0, 5, 3)
        g1.addWidget(self.zone_tail_min, 5, 1)
        g1.addWidget(QLabel("~"), 5, 2)
        g1.addWidget(self.zone_tail_max, 5, 3)

        g1.addWidget(make_row_label("和值区间:"), 6, 0)
        self.sum_min = make_spin(15, 165, 70)
        self.sum_max = make_spin(15, 165, 110)
        g1.addWidget(self.sum_min, 6, 1)
        g1.addWidget(QLabel("~"), 6, 2)
        g1.addWidget(self.sum_max, 6, 3)
        self.chk_sum = QCheckBox("启用")
        self.chk_sum.setToolTip("不勾选=不过滤和值")
        self.chk_sum.setChecked(True)
        g1.addWidget(self.chk_sum, 6, 4)

        g1.addWidget(make_row_label("跨度区间:"), 7, 0)
        self.span_min = make_spin(4, 34, 4)
        self.span_max = make_spin(4, 34, 6)
        g1.addWidget(self.span_min, 7, 1)
        g1.addWidget(QLabel("~"), 7, 2)
        g1.addWidget(self.span_max, 7, 3)
        self.chk_span = QCheckBox("启用")
        self.chk_span.setToolTip("不勾选=不启用跨度过滤")
        self.chk_span.setChecked(True)
        g1.addWidget(self.chk_span, 7, 4)

        self.odd_box, self.odd_checks = make_ratio_group("奇数个数(奇:偶)", "勾选允许的奇数个数, 全不勾=不过滤")
        self.big_box, self.big_checks = make_ratio_group("大号个数(大:小)", f"大号 >= {BIG_BOUNDARY}, 全不勾=不过滤")
        self.prime_box, self.prime_checks = make_ratio_group("质数个数(质:合)", "质数: 2,3,5,7,11,13,17,19,23,29,31")
        g1.addWidget(self.odd_box, 8, 0, 1, 4)
        g1.addWidget(self.big_box, 9, 0, 1, 4)
        g1.addWidget(self.prime_box, 10, 0, 1, 4)

        # ---- 页2: 五行(洛书) ----
        page_wx = QWidget()
        gw = QGridLayout(page_wx)
        self.chk_wx = QCheckBox("五行(洛书)分区出号(启用)")
        self.chk_wx.setToolTip(
            "尾数1/6=水, 2/7=火, 3/8=木, 4/9=金, 5/0=土, 每组7个号, 组间不重叠\n"
            "不勾选=不启用该过滤")
        self.chk_wx.setChecked(True)
        gw.addWidget(self.chk_wx, 0, 0, 1, 4)
        self.wx_spins = []
        for i, (name, elements) in enumerate(WX_ZONES):
            gw.addWidget(QLabel(f"{name}({','.join(f'{n:02d}' for n in sorted(elements))}) 出号:"), i + 1, 0)
            mn = make_spin(0, 5, 0)
            mx = make_spin(0, 5, 3)
            self.wx_spins.append((mn, mx))
            gw.addWidget(mn, i + 1, 1)
            gw.addWidget(QLabel("~"), i + 1, 2)
            gw.addWidget(mx, i + 1, 3)
        gw.setRowStretch(len(WX_ZONES) + 1, 1)

        # ---- 页3: 五行(易经) ----
        page_yj = QWidget()
        gy = QGridLayout(page_yj)
        self.chk_yj = QCheckBox("五行(易经)分区出号(启用)")
        self.chk_yj.setToolTip(
            "金木水火土五组(与洛书分法不同), 覆盖1~35, 组间不重叠\n"
            "不勾选=不启用该过滤")
        self.chk_yj.setChecked(True)
        gy.addWidget(self.chk_yj, 0, 0, 1, 4)
        self.yj_spins = []
        for i, (name, elements) in enumerate(YJ_ZONES):
            gy.addWidget(QLabel(f"{name}({','.join(f'{n:02d}' for n in sorted(elements))}) 出号:"), i + 1, 0)
            mn = make_spin(0, 5, YJ_DEFAULTS[i][0])
            mx = make_spin(0, 5, YJ_DEFAULTS[i][1])
            self.yj_spins.append((mn, mx))
            gy.addWidget(mn, i + 1, 1)
            gy.addWidget(QLabel("~"), i + 1, 2)
            gy.addWidget(mx, i + 1, 3)
        gy.setRowStretch(len(YJ_ZONES) + 1, 1)

        # ---- 页: 五行尾数 ----
        page_twx = QWidget()
        gtw = QGridLayout(page_twx)
        self.chk_tailwx = QCheckBox("五行尾数过滤(启用)")
        self.chk_tailwx.setToolTip(
            "按个位尾数分五行: 金(4,9) 木(3,8) 水(1,6) 火(2,7) 土(0,5)\n"
            "各五行尾的出号个数及种类数均须落在设定范围内\n"
            "不勾选=不启用该过滤")
        self.chk_tailwx.setChecked(True)
        gtw.addWidget(self.chk_tailwx, 0, 0, 1, 4)
        self.tailwx_spins = []
        for i, (name, tset) in enumerate(TAIL_WX):
            gtw.addWidget(QLabel(f"{name}({','.join(str(t) for t in sorted(tset))}):"), i + 1, 0)
            mn = make_spin(0, 5, TAIL_WX_DEFAULTS[i][0])
            mx = make_spin(0, 5, TAIL_WX_DEFAULTS[i][1])
            self.tailwx_spins.append((mn, mx))
            gtw.addWidget(mn, i + 1, 1)
            gtw.addWidget(QLabel("~"), i + 1, 2)
            gtw.addWidget(mx, i + 1, 3)
        r = len(TAIL_WX) + 1
        gtw.addWidget(make_row_label("五行尾数种类:"), r, 0)
        self.tailwx_kind_min = make_spin(1, 5, 2)
        self.tailwx_kind_max = make_spin(1, 5, 5)
        gtw.addWidget(self.tailwx_kind_min, r, 1)
        gtw.addWidget(QLabel("~"), r, 2)
        gtw.addWidget(self.tailwx_kind_max, r, 3)
        gtw.setRowStretch(r + 2, 1)

        # ---- 页: 尾数红蓝绿 ----
        page_tcol = QWidget()
        gtc = QGridLayout(page_tcol)
        self.chk_tailcolor = QCheckBox("尾数红蓝绿过滤(启用)")
        self.chk_tailcolor.setToolTip(
            "尾数=号码的个位数\n"
            "红尾: 1,2,7,8   蓝尾: 3,4,9,0   绿尾: 5,6\n"
            "分别统计尾数属于各色的号码个数, 须落在设定范围内\n"
            "不勾选=不启用该过滤")
        self.chk_tailcolor.setChecked(True)
        gtc.addWidget(self.chk_tailcolor, 0, 0, 1, 4)
        self.tailcolor_spins = []
        for i, (name, tset) in enumerate(TAIL_COLOR):
            gtc.addWidget(QLabel(f"{name}({','.join(str(t) for t in sorted(tset))})出号:"), i + 1, 0)
            mn = make_spin(0, 5, TAIL_COLOR_DEFAULTS[i][0])
            mx = make_spin(0, 5, TAIL_COLOR_DEFAULTS[i][1])
            self.tailcolor_spins.append((mn, mx))
            gtc.addWidget(mn, i + 1, 1)
            gtc.addWidget(QLabel("~"), i + 1, 2)
            gtc.addWidget(mx, i + 1, 3)
        gtc.setRowStretch(len(TAIL_COLOR) + 2, 1)

        # ---- 页: 4分区 ----
        page_four = QWidget()
        g4 = QGridLayout(page_four)
        self.chk_four = QCheckBox("4分区出号(启用)")
        self.chk_four.setToolTip(
            "0区01~09 / 1区10~19 / 2区20~29 / 3区30~35\n"
            "不勾选=不启用该过滤")
        self.chk_four.setChecked(True)
        g4.addWidget(self.chk_four, 0, 0, 1, 4)
        self.four_spins = []
        for i, (lo, hi) in enumerate(FOUR_ZONES):
            g4.addWidget(QLabel(f"{i}区 {lo:02d}~{hi:02d} 出号:"), i + 1, 0)
            mn = make_spin(0, 5, FOUR_DEFAULTS[i][0])
            mx = make_spin(0, 5, FOUR_DEFAULTS[i][1])
            self.four_spins.append((mn, mx))
            g4.addWidget(mn, i + 1, 1)
            g4.addWidget(QLabel("~"), i + 1, 2)
            g4.addWidget(mx, i + 1, 3)
        g4.setRowStretch(6, 1)

        # ---- 页4: 5分区 ----
        page_five = QWidget()
        gf = QGridLayout(page_five)
        self.chk_five = QCheckBox("5分区出号(启用)")
        self.chk_five.setToolTip(
            "1区01~07 / 2区08~14 / 3区15~21 / 4区22~28 / 5区29~35, 每区7个号\n"
            "不勾选=不启用该过滤")
        self.chk_five.setChecked(True)
        gf.addWidget(self.chk_five, 0, 0, 1, 4)
        self.five_spins = []
        for i, (lo, hi) in enumerate(FIVE_ZONES):
            gf.addWidget(QLabel(f"{i + 1}区 {lo:02d}~{hi:02d} 出号:"), i + 1, 0)
            mn = make_spin(0, 5, FIVE_DEFAULTS[i][0])
            mx = make_spin(0, 5, FIVE_DEFAULTS[i][1])
            self.five_spins.append((mn, mx))
            gf.addWidget(mn, i + 1, 1)
            gf.addWidget(QLabel("~"), i + 1, 2)
            gf.addWidget(mx, i + 1, 3)

        self.chk_edge = QCheckBox("5区边缘码出号(启用)")
        self.chk_edge.setToolTip(
            "边缘码=各分区首尾号: 01,07,08,14,15,21,22,28,29,35\n"
            "每个分区的边缘码最多1个\n"
            "不勾选=不启用该过滤")
        self.chk_edge.setChecked(True)
        gf.addWidget(self.chk_edge, 6, 0, 1, 4)

        gf.addWidget(make_row_label("边缘码出号个数:"), 7, 0)
        self.edge_min = make_spin(0, 5, 0)
        self.edge_max = make_spin(0, 5, 3)
        gf.addWidget(self.edge_min, 7, 1)
        gf.addWidget(QLabel("~"), 7, 2)
        gf.addWidget(self.edge_max, 7, 3)

        gf.setRowStretch(9, 1)

        # ---- 页: 红蓝绿波 ----
        page_wave = QWidget()
        gwv = QGridLayout(page_wave)
        self.chk_wave = QCheckBox("红蓝绿波过滤(启用)")
        self.chk_wave.setToolTip(
            "红: 01,02,07,08,12,13,18,19,23,24,29,30\n"
            "蓝: 03,04,09,10,14,15,20,25,26,31,34,35\n"
            "绿: 05,06,11,16,17,21,22,27,28,32,33\n"
            "各波色出号个数须落在设定范围内\n不勾选=不启用该过滤")
        self.chk_wave.setChecked(True)
        gwv.addWidget(self.chk_wave, 0, 0, 1, 4)
        self.wave_spins = []
        for i, (name, elements) in enumerate(WAVE_ZONES):
            gwv.addWidget(QLabel(f"{name}波出号:"), i + 1, 0)
            mn = make_spin(0, 5, WAVE_DEFAULTS[i][0])
            mx = make_spin(0, 5, WAVE_DEFAULTS[i][1])
            self.wave_spins.append((mn, mx))
            gwv.addWidget(mn, i + 1, 1)
            gwv.addWidget(QLabel("~"), i + 1, 2)
            gwv.addWidget(mx, i + 1, 3)
        gwv.setRowStretch(5, 1)

        # ---- 页: 三区间比 ----
        page_san = QWidget()
        gsn = QGridLayout(page_san)
        self.chk_san = QCheckBox("三区间比过滤(启用)")
        self.chk_san.setToolTip(
            "1区01~11 / 2区12~22 / 3区23~35\n"
            "勾选各档允许的(1区:2区:3区)比例, 可多选, 全不勾=不按比例过滤\n"
            "不勾选=不启用该过滤")
        self.chk_san.setChecked(True)
        gsn.addWidget(self.chk_san, 0, 0, 1, 4)

        self.san_pattern_checks = []
        for t, name in enumerate(SAN_TIER_NAMES):
            lab = QLabel(name + ":")
            gsn.addWidget(lab, t + 1, 0)
            for p, pat in enumerate(SAN_PATTERNS[t]):
                cb = QCheckBox(f"{pat[0]}:{pat[1]}:{pat[2]}")
                cb.setChecked(t == 0)
                self.san_pattern_checks.append(cb)
                gsn.addWidget(cb, t + 1, 1 + p)

        self.san_spins = []
        for i in range(3):
            lo, hi = SAN_RANGES[i]
            gsn.addWidget(QLabel(f"{i + 1}区 {lo:02d}~{hi:02d} 出号:"), 4 + i, 0)
            mn = make_spin(0, 5, 0)
            mx = make_spin(0, 5, 3)
            self.san_spins.append((mn, mx))
            gsn.addWidget(mn, 4 + i, 1)
            gsn.addWidget(QLabel("~"), 4 + i, 2)
            gsn.addWidget(mx, 4 + i, 3)
        gsn.setRowStretch(8, 1)

        # ---- 页: 固定胆组 ----
        page_dg = QWidget()
        gdg = QGridLayout(page_dg)
        self.chk_dangroup = QCheckBox("固定胆组过滤(启用)")
        self.chk_dangroup.setToolTip(
            "8组预定义号码集合, 每组设置该组号码的出现个数范围\n"
            "悬停查看各组号码; 0~5=该组不限制\n不勾选=不启用该过滤")
        self.chk_dangroup.setChecked(False)
        gdg.addWidget(self.chk_dangroup, 0, 0, 1, 4)
        self.dangroup_spins = []
        for i, group in enumerate(DAN_GROUPS):
            nums_txt = ",".join(f"{n:02d}" for n in sorted(group))
            lab = QLabel(f"胆组{i + 1}: {nums_txt[:11]}…")
            lab.setToolTip(nums_txt)
            gdg.addWidget(lab, i + 1, 0)
            mn = make_spin(0, 5, 0)
            mx = make_spin(0, 5, 5)
            self.dangroup_spins.append((mn, mx))
            gdg.addWidget(mn, i + 1, 1)
            gdg.addWidget(QLabel("~"), i + 1, 2)
            gdg.addWidget(mx, i + 1, 3)
        gdg.setRowStretch(len(DAN_GROUPS) + 1, 1)

        # ---- 页5: 7分区与跨区 ----
        page_seven = QWidget()
        gs = QGridLayout(page_seven)
        self.chk_seven = QCheckBox("7分区出号(启用)")
        self.chk_seven.setToolTip(
            "1区01~05 / 2区06~10 / 3区11~15 / 4区16~20 / 5区21~25 / 6区26~30 / 7区31~35, 每区5个号\n"
            "不勾选=不启用该过滤")
        self.chk_seven.setChecked(True)
        gs.addWidget(self.chk_seven, 0, 0, 1, 4)
        self.seven_spins = []
        for i, (lo, hi) in enumerate(SEVEN_ZONES):
            gs.addWidget(QLabel(f"{i + 1}区 {lo:02d}~{hi:02d} 出号:"), i + 1, 0)
            mn = make_spin(0, 5, SEVEN_DEFAULTS[i][0])
            mx = make_spin(0, 5, SEVEN_DEFAULTS[i][1])
            self.seven_spins.append((mn, mx))
            gs.addWidget(mn, i + 1, 1)
            gs.addWidget(QLabel("~"), i + 1, 2)
            gs.addWidget(mx, i + 1, 3)


        self.chk_seven_span = QCheckBox("7分区跨区条件(启用)")
        self.chk_seven_span.setToolTip(
            "统计5个号覆盖的分区数(1~5), 须落在设定范围内\n"
            "不勾选=不启用该过滤")
        self.chk_seven_span.setChecked(True)
        gs.addWidget(self.chk_seven_span, 9, 0, 1, 4)

        gs.addWidget(make_row_label("跨区范围(覆盖分区数):"), 10, 0)
        self.seven_span_min = make_spin(1, 5, SEVEN_SPAN_DEFAULT[0])
        self.seven_span_max = make_spin(1, 5, SEVEN_SPAN_DEFAULT[1])
        gs.addWidget(self.seven_span_min, 10, 1)
        gs.addWidget(QLabel("~"), 10, 2)
        gs.addWidget(self.seven_span_max, 10, 3)

        self.chk_edge7 = QCheckBox("7区边缘码出号(启用)")
        self.chk_edge7.setToolTip(
            "边缘码=各分区首尾号: 01,05,06,10,11,15,16,20,21,25,26,30,31,35\n"
            "每个分区的边缘码最多1个\n"
            "不勾选=不启用该过滤")
        self.chk_edge7.setChecked(True)
        gs.addWidget(self.chk_edge7, 11, 0, 1, 4)

        gs.addWidget(make_row_label("边缘码出号个数:"), 12, 0)
        self.edge7_min = make_spin(0, 5, 0)
        self.edge7_max = make_spin(0, 5, 4)
        gs.addWidget(self.edge7_min, 12, 1)
        gs.addWidget(QLabel("~"), 12, 2)
        gs.addWidget(self.edge7_max, 12, 3)

        gs.setRowStretch(14, 1)

        # ---- 页3: 余数与结构 ----
        page2 = QWidget()
        g2 = QGridLayout(page2)
        self.chk_mod3 = QCheckBox("012路出号(启用)")
        self.chk_mod3.setToolTip(
            "0路=03,06,...,33; 1路=01,04,...,34; 2路=02,05,...,35\n"
            "各路出号个数须落在设定范围内\n不勾选=不启用该过滤")
        self.chk_mod3.setChecked(True)
        g2.addWidget(self.chk_mod3, 0, 0, 1, 9)

        self.mod3_spins = []
        for i in range(3):
            g2.addWidget(QLabel(f"{i}路"), 1, i * 3)
            mn = make_spin(0, 5, 0)
            mx = make_spin(0, 5, 5)
            self.mod3_spins.append((mn, mx))
            g2.addWidget(mn, 1, i * 3 + 1)
            g2.addWidget(mx, 1, i * 3 + 2)


        self.chk_mod7 = QCheckBox("除7余数出号(启用)")
        self.chk_mod7.setToolTip(
            "余0~余6共7组, 每组5个号, 每组出号个数须落在设定范围内\n"
            "不勾选=不启用该过滤")
        self.chk_mod7.setChecked(True)
        g2.addWidget(self.chk_mod7, 3, 0, 1, 8)

        self.mod7_spins = []
        for i in range(7):
            lab = QLabel(f"余{i}")
            lab.setToolTip("每组号码: " + ", ".join(f"{n:02d}" for n in range(1, 36) if n % 7 == i % 7))
            g2.addWidget(lab, 4, i * 2)
            mn = make_spin(0, 5, 0)
            mx = make_spin(0, 5, 2)
            self.mod7_spins.append((mn, mx))
            g2.addWidget(mn, 5, i * 2)
            g2.addWidget(mx, 5, i * 2 + 1)


        self.chk_mod7_span = QCheckBox("余7跨区条件(启用)")
        self.chk_mod7_span.setToolTip(
            "统计5个号覆盖的余数组数(1~5), 须落在设定范围内\n"
            "不勾选=不启用该过滤")
        self.chk_mod7_span.setChecked(True)
        g2.addWidget(self.chk_mod7_span, 7, 0, 1, 8)

        g2.addWidget(make_row_label("跨区范围(覆盖余数组数):"), 8, 0)
        self.mod7_span_min = make_spin(1, 5, 2)
        self.mod7_span_max = make_spin(1, 5, 4)
        g2.addWidget(self.mod7_span_min, 8, 1)
        g2.addWidget(QLabel("~"), 8, 2)
        g2.addWidget(self.mod7_span_max, 8, 3)

        self.chk_con = QCheckBox("连号过滤(启用)")
        self.chk_con.setToolTip(
            "2连号组数=长度恰为2的连号段个数; 三连号组数=长度>=3的连号段个数\n"
            "如 08,09,15,16,22 → 2连号2组 三连号0组; 08,09,10,22,25 → 2连号0组 三连号1组\n"
            "不勾选=不启用该过滤")
        self.chk_con.setChecked(True)
        g2.addWidget(self.chk_con, 10, 0, 1, 4)

        g2.addWidget(make_row_label("2连号组数:"), 11, 0)
        self.con2_min = make_spin(0, 2, 0)
        self.con2_max = make_spin(0, 2, 1)
        g2.addWidget(self.con2_min, 11, 1)
        g2.addWidget(QLabel("~"), 11, 2)
        g2.addWidget(self.con2_max, 11, 3)

        g2.addWidget(make_row_label("三连号组数:"), 12, 0)
        self.con3_min = make_spin(0, 1, 0)
        self.con3_max = make_spin(0, 1, 1)
        g2.addWidget(self.con3_min, 12, 1)
        g2.addWidget(QLabel("~"), 12, 2)
        g2.addWidget(self.con3_max, 12, 3)

        g2.addWidget(make_row_label("尾数种类:"), 13, 0)
        self.tail_min = make_spin(1, 5, 1)
        self.tail_max = make_spin(1, 5, 5)
        g2.addWidget(self.tail_min, 13, 1)
        g2.addWidget(QLabel("~"), 13, 2)
        g2.addWidget(self.tail_max, 13, 3)

        self.chk_tsum = QCheckBox("尾数之和过滤(启用)")
        self.chk_tsum.setToolTip(
            "5个号码的个位数相加, 如 08,12,15,29,30 → 8+2+5+9+0=24\n"
            "不勾选=不启用该过滤")
        self.chk_tsum.setChecked(True)
        g2.addWidget(self.chk_tsum, 14, 0, 1, 8)

        g2.addWidget(make_row_label("尾数和范围:"), 15, 0)
        self.tsum_min = make_spin(0, 45, 10)
        self.tsum_max = make_spin(0, 45, 34)
        g2.addWidget(self.tsum_min, 15, 1)
        g2.addWidget(QLabel("~"), 15, 2)
        g2.addWidget(self.tsum_max, 15, 3)

        g2.setRowStretch(17, 1)

        # ---- 页3: 号码限定 ----
        page3 = QWidget()
        g3 = QGridLayout(page3)
        g3.addWidget(make_row_label("胆码(必含):"), 0, 0)
        self.dan_edit = QLineEdit()
        self.dan_edit.setPlaceholderText("如: 07 18")
        self.dan_edit.setMaximumWidth(80)  # 约为原拉伸宽度的1/3
        g3.addWidget(self.dan_edit, 0, 1, 1, 3)

        g3.addWidget(make_row_label("上期号码:"), 1, 0)
        self.prev_edit = QLineEdit()
        self.prev_edit.setPlaceholderText("如: 04 13 19 29 31 (留空=不使用重邻孤)")
        self.prev_edit.setMaximumWidth(127)  # 约为原拉伸宽度的1/3
        g3.addWidget(self.prev_edit, 1, 1, 1, 5)

        self.chk_rn = QCheckBox("重邻孤过滤(启用)")
        self.chk_rn.setToolTip(
            "重号=上期开奖号码; 邻号=上期号码左右相邻(±1, 已剔除重号);\n"
            "孤号=既非重号也非邻号的号码。上期号码留空=不过滤")
        self.chk_rn.setChecked(True)
        g3.addWidget(self.chk_rn, 2, 0, 1, 8)

        g3.addWidget(make_row_label("重号个数:"), 3, 0)
        self.rep_min = make_spin(0, 5, 0)
        self.rep_max = make_spin(0, 5, 2)
        g3.addWidget(self.rep_min, 3, 1)
        g3.addWidget(QLabel("~"), 3, 2)
        g3.addWidget(self.rep_max, 3, 3)
        g3.addWidget(make_row_label("邻号个数:"), 3, 4)
        self.nbr_min = make_spin(0, 5, 1)
        self.nbr_max = make_spin(0, 5, 3)
        g3.addWidget(self.nbr_min, 3, 5)
        g3.addWidget(QLabel("~"), 3, 6)
        g3.addWidget(self.nbr_max, 3, 7)

        g3.addWidget(make_row_label("孤号个数:"), 4, 0)
        self.orph_min = make_spin(0, 5, 1)
        self.orph_max = make_spin(0, 5, 4)
        g3.addWidget(self.orph_min, 4, 1)
        g3.addWidget(QLabel("~"), 4, 2)
        g3.addWidget(self.orph_max, 4, 3)
        g3.setRowStretch(5, 1)

        add_scroll_tab(tabs, page1, "杀号/区间与比例")
        add_scroll_tab(tabs, page_wx, "五行(洛书)")
        add_scroll_tab(tabs, page_yj, "五行(易经)")
        add_scroll_tab(tabs, page_twx, "五行尾数")
        add_scroll_tab(tabs, page_tcol, "尾数红蓝绿")
        add_scroll_tab(tabs, page_four, "4分区")
        add_scroll_tab(tabs, page_five, "5分区")
        add_scroll_tab(tabs, page_wave, "红蓝绿波")
        add_scroll_tab(tabs, page_seven, "7分区与跨区")
        add_scroll_tab(tabs, page_san, "三区间比")
        add_scroll_tab(tabs, page2, "余数与结构")
        add_scroll_tab(tabs, page3, "号码限定")
        add_scroll_tab(tabs, page_dg, "固定胆组")
        return tabs

    # ---------------- 状态持久化 ----------------
    def _migrate_legacy_settings(self):
        """旧版配置在程序目录, 首次运行时自动迁移到用户目录。"""
        if not os.path.exists(SETTINGS_FILE) and os.path.exists(_LEGACY_SETTINGS_FILE):
            try:
                os.makedirs(_CONFIG_DIR, exist_ok=True)
                shutil.copyfile(_LEGACY_SETTINGS_FILE, SETTINGS_FILE)
            except OSError:
                pass  # 迁移失败不影响使用, 只是恢复默认配置

    def _persist_widgets(self):
        """返回 {配置键: 控件} 映射, 涵盖页面上所有用户输入项。"""
        m = {}
        m["check/chk_span"] = self.chk_span
        m["check/chk_mod3"] = self.chk_mod3
        m["check/chk_tailwx"] = self.chk_tailwx
        m["check/chk_tailcolor"] = self.chk_tailcolor
        m["check/chk_wave"] = self.chk_wave
        m["check/chk_sum"] = self.chk_sum
        m["check/chk_con"] = self.chk_con
        m["check/chk_san"] = self.chk_san
        m["check/chk_dangroup"] = self.chk_dangroup
        for i, cb in enumerate(self.san_pattern_checks):
            m[f"check/san_pat_{i}"] = cb
        for i, (mn, mx) in enumerate(self.san_spins):
            m[f"spin/san_min_{i}"] = mn
            m[f"spin/san_max_{i}"] = mx
        for i, (mn, mx) in enumerate(self.dangroup_spins):
            m[f"spin/dg_min_{i}"] = mn
            m[f"spin/dg_max_{i}"] = mx
        spins = ["sum_min", "sum_max", "span_min", "span_max", "ac_min", "ac_max",
                 "zone_head_min", "zone_head_max", "zone_mid_min", "zone_mid_max",
                 "zone_tail_min", "zone_tail_max",
                 "con2_min", "con2_max", "con3_min", "con3_max", "tail_min", "tail_max",
                 "rep_min", "rep_max", "nbr_min", "nbr_max", "orph_min", "orph_max"]
        for name in spins:
            m["spin/" + name] = getattr(self, name)
        m["check/chk_zone"] = self.chk_zone
        m["check/chk_wx"] = self.chk_wx
        m["check/chk_rn"] = self.chk_rn
        m["check/chk_yj"] = self.chk_yj
        m["check/chk_four"] = self.chk_four
        for i, (mn, mx) in enumerate(self.four_spins):
            m[f"spin/four_min_{i}"] = mn
            m[f"spin/four_max_{i}"] = mx
        m["check/chk_five"] = self.chk_five
        m["check/chk_seven"] = self.chk_seven
        m["check/chk_seven_span"] = self.chk_seven_span
        for i, (mn, mx) in enumerate(self.five_spins):
            m[f"spin/five_min_{i}"] = mn
            m[f"spin/five_max_{i}"] = mx
        for i, (mn, mx) in enumerate(self.seven_spins):
            m[f"spin/seven_min_{i}"] = mn
            m[f"spin/seven_max_{i}"] = mx
        m["spin/seven_span_min"] = self.seven_span_min
        m["spin/seven_span_max"] = self.seven_span_max
        m["check/chk_edge"] = self.chk_edge
        m["spin/edge_min"] = self.edge_min
        m["spin/edge_max"] = self.edge_max
        m["check/chk_edge7"] = self.chk_edge7
        m["spin/edge7_min"] = self.edge7_min
        m["spin/edge7_max"] = self.edge7_max
        for i, (mn, mx) in enumerate(self.mod3_spins):
            m[f"spin/mod3_min_{i}"] = mn
            m[f"spin/mod3_max_{i}"] = mx
        m["check/chk_mod7"] = self.chk_mod7
        m["check/chk_mod7_span"] = self.chk_mod7_span
        for i, (mn, mx) in enumerate(self.mod7_spins):
            m[f"spin/mod7_min_{i}"] = mn
            m[f"spin/mod7_max_{i}"] = mx
        m["spin/mod7_span_min"] = self.mod7_span_min
        m["spin/mod7_span_max"] = self.mod7_span_max
        m["check/chk_tsum"] = self.chk_tsum
        m["spin/tsum_min"] = self.tsum_min
        m["spin/tsum_max"] = self.tsum_max
        for i, (mn, mx) in enumerate(self.tailwx_spins):
            m[f"spin/tailwx_min_{i}"] = mn
            m[f"spin/tailwx_max_{i}"] = mx
        m["spin/tailwx_kind_min"] = self.tailwx_kind_min
        m["spin/tailwx_kind_max"] = self.tailwx_kind_max
        for i, (mn, mx) in enumerate(self.tailcolor_spins):
            m[f"spin/tailcolor_min_{i}"] = mn
            m[f"spin/tailcolor_max_{i}"] = mx
        for i, (mn, mx) in enumerate(self.wave_spins):
            m[f"spin/wave_min_{i}"] = mn
            m[f"spin/wave_max_{i}"] = mx
        for group, checks in (("odd", self.odd_checks), ("big", self.big_checks),
                              ("prime", self.prime_checks)):
            for i, cb in enumerate(checks):
                m[f"check/{group}_{i}"] = cb
        for name in ("kill_edit", "dan_edit", "prev_edit"):
            m["edit/" + name] = getattr(self, name)
        return m

    def _save_state(self):
        try:
            os.makedirs(_CONFIG_DIR, exist_ok=True)
        except OSError:
            pass
        s = QSettings(SETTINGS_FILE, QSettings.IniFormat)
        s.clear()
        for key, w in self._persist_widgets().items():
            if isinstance(w, QSpinBox):
                s.setValue(key, w.value())
            elif isinstance(w, QAbstractButton):  # QCheckBox
                s.setValue(key, w.isChecked())
            elif isinstance(w, QLineEdit):
                s.setValue(key, w.text())
        s.sync()

    def _restore_state(self):
        s = QSettings(SETTINGS_FILE, QSettings.IniFormat)
        if not s.contains("spin/sum_min"):
            return  # 首次启动, 无保存状态
        for key, w in self._persist_widgets().items():
            if not s.contains(key):
                continue
            v = s.value(key)
            try:
                if isinstance(w, QSpinBox):
                    w.setValue(int(v))
                elif isinstance(w, QAbstractButton):  # QCheckBox
                    w.setChecked(str(v).lower() == "true" or v is True)
                elif isinstance(w, QLineEdit):
                    w.setText(str(v))
            except (TypeError, ValueError):
                continue  # 单项异常不影响其余恢复

    def closeEvent(self, event):
        self._save_state()
        super().closeEvent(event)

    # ---------------- 事件 ----------------
    def on_fetch_latest(self):
        """后台线程请求最新开奖号码, 完成后经信号回主线程更新界面。"""
        self.latest_label.setText("最新开奖: 获取中...")
        self.btn_latest.setEnabled(False)
        threading.Thread(target=self._fetch_latest_worker, daemon=True).start()

    def _fetch_latest_worker(self):
        self._latest_ready.emit(fetch_latest_draw())

    def _show_latest_draw(self, result):
        self.btn_latest.setEnabled(True)
        if result is None:
            self.latest_label.setText("最新开奖: 获取失败(请检查网络)")
            return
        num, date, front, back = result
        self.latest_label.setText(
            f"最新开奖: 第{num}期({date})  "
            + " ".join(f"{n:02d}" for n in front)
            + " + " + " ".join(f"{n:02d}" for n in back)
            + f"  (AC值: {ac_value(front)})")

    def on_load(self):
        if full_data is None:
            self.status_label.setText("载入失败: 缺少 full_data.py 内嵌数据模块")
            return
        self.groups = full_data.FULL_GROUPS
        self.results = []
        self.table.setRowCount(0)
        self.status_label.setText(f"已载入 {len(self.groups)} 组号码: (全量数据)")

    def _collect_conditions(self):
        c = FilterConditions()
        c.sum_min, c.sum_max = self.sum_min.value(), self.sum_max.value()
        c.sum_filter = self.chk_sum.isChecked()
        c.span_min, c.span_max = self.span_min.value(), self.span_max.value()
        c.span_filter = self.chk_span.isChecked()
        c.ac_min, c.ac_max = self.ac_min.value(), self.ac_max.value()
        c.zone_filter = self.chk_zone.isChecked()
        c.zone_head_min, c.zone_head_max = self.zone_head_min.value(), self.zone_head_max.value()
        c.zone_mid_min, c.zone_mid_max = self.zone_mid_min.value(), self.zone_mid_max.value()
        c.zone_tail_min, c.zone_tail_max = self.zone_tail_min.value(), self.zone_tail_max.value()
        c.wx_filter = self.chk_wx.isChecked()
        c.wx_limits = tuple((mn.value(), mx.value()) for mn, mx in self.wx_spins)
        c.yj_filter = self.chk_yj.isChecked()
        c.yj_limits = tuple((mn.value(), mx.value()) for mn, mx in self.yj_spins)
        c.four_filter = self.chk_four.isChecked()
        c.four_limits = tuple((mn.value(), mx.value()) for mn, mx in self.four_spins)
        c.five_filter = self.chk_five.isChecked()
        c.five_limits = tuple((mn.value(), mx.value()) for mn, mx in self.five_spins)
        c.seven_filter = self.chk_seven.isChecked()
        c.seven_limits = tuple((mn.value(), mx.value()) for mn, mx in self.seven_spins)
        c.seven_span_filter = self.chk_seven_span.isChecked()
        c.seven_span_min, c.seven_span_max = self.seven_span_min.value(), self.seven_span_max.value()
        c.edge_filter = self.chk_edge.isChecked()
        c.edge_min, c.edge_max = self.edge_min.value(), self.edge_max.value()
        c.edge7_filter = self.chk_edge7.isChecked()
        c.edge7_min, c.edge7_max = self.edge7_min.value(), self.edge7_max.value()
        if any(cb.isChecked() for cb in self.odd_checks):
            c.odd_counts = {i for i, cb in enumerate(self.odd_checks) if cb.isChecked()}
        if any(cb.isChecked() for cb in self.big_checks):
            c.big_counts = {i for i, cb in enumerate(self.big_checks) if cb.isChecked()}
        if any(cb.isChecked() for cb in self.prime_checks):
            c.prime_counts = {i for i, cb in enumerate(self.prime_checks) if cb.isChecked()}
        c.mod3_filter = self.chk_mod3.isChecked()
        c.mod3_limits = tuple((mn.value(), mx.value()) for mn, mx in self.mod3_spins)
        c.mod7_filter = self.chk_mod7.isChecked()
        c.mod7_limits = tuple((mn.value(), mx.value()) for mn, mx in self.mod7_spins)
        c.mod7_span_filter = self.chk_mod7_span.isChecked()
        c.mod7_span_min, c.mod7_span_max = self.mod7_span_min.value(), self.mod7_span_max.value()
        c.con_filter = self.chk_con.isChecked()
        c.con2_min, c.con2_max = self.con2_min.value(), self.con2_max.value()
        c.con3_min, c.con3_max = self.con3_min.value(), self.con3_max.value()
        c.tail_min, c.tail_max = self.tail_min.value(), self.tail_max.value()
        c.tsum_filter = self.chk_tsum.isChecked()
        c.tsum_min, c.tsum_max = self.tsum_min.value(), self.tsum_max.value()
        c.tailwx_filter = self.chk_tailwx.isChecked()
        c.tailwx_limits = tuple((mn.value(), mx.value()) for mn, mx in self.tailwx_spins)
        c.tailwx_kind_min, c.tailwx_kind_max = self.tailwx_kind_min.value(), self.tailwx_kind_max.value()
        c.tailcolor_filter = self.chk_tailcolor.isChecked()
        c.tailcolor_limits = tuple((mn.value(), mx.value()) for mn, mx in self.tailcolor_spins)
        c.wave_filter = self.chk_wave.isChecked()
        c.wave_limits = tuple((mn.value(), mx.value()) for mn, mx in self.wave_spins)
        c.san_filter = self.chk_san.isChecked()
        c.san_patterns = tuple(cb.isChecked() for cb in self.san_pattern_checks)
        c.san_limits = tuple((mn.value(), mx.value()) for mn, mx in self.san_spins)
        c.dangroup_filter = self.chk_dangroup.isChecked()
        c.dangroup_limits = tuple((mn.value(), mx.value()) for mn, mx in self.dangroup_spins)
        c.kill = self._parse_nums(self.kill_edit.text())
        c.dan = self._parse_nums(self.dan_edit.text())
        prev = self._parse_nums(self.prev_edit.text())
        if prev:
            c.prev_draw = frozenset(prev)
        c.rn_filter = self.chk_rn.isChecked()
        c.rep_min, c.rep_max = self.rep_min.value(), self.rep_max.value()
        c.nbr_min, c.nbr_max = self.nbr_min.value(), self.nbr_max.value()
        c.orph_min, c.orph_max = self.orph_min.value(), self.orph_max.value()
        return c

    @staticmethod
    def _parse_nums(text):
        nums = set()
        for token in re.findall(r"\d+", text):
            n = int(token)
            if 1 <= n <= 35:
                nums.add(n)
        return nums

    def on_shrink(self):
        if not self.groups:
            self.status_label.setText("请先载入数据")
            return
        cond = self._collect_conditions()
        start = time.time()
        QApplication.processEvents()
        self.results = [g for g in self.groups if cond.match(g)]
        filtered_count = len(self.results)
        elapsed = time.time() - start

        self.table.setRowCount(0)
        for row, nums in enumerate(self.results[:PREVIEW_ROWS]):
            self.table.insertRow(row)
            for col, n in enumerate(nums):
                self.table.setItem(row, col, QTableWidgetItem(f"{n:02d}"))
        note = "" if len(self.results) <= PREVIEW_ROWS else f"（表格仅预览前 {PREVIEW_ROWS} 行）"
        self.status_label.setText(
            f"共 {len(self.groups)} 组 → 条件过滤 {filtered_count} 组, "
            f"最终 {len(self.results)} 组, 耗时 {elapsed:.2f} 秒 {note}")

    def on_save(self):
        if not self.results:
            self.status_label.setText("没有可保存的结果, 请先缩水")
            return
        path, _ = QFileDialog.getSaveFileName(self, "保存缩水结果", DEFAULT_SAVE, "文本文件 (*.txt)")
        if not path:
            return
        with open(path, "w", encoding="utf-8") as f:
            f.write(f"大乐透前区缩水结果（{len(self.results)}组，5/35）\n")
            f.write("-" * 40 + "\n")
            for i, nums in enumerate(self.results, 1):
                f.write(f"{i:04d}: " + " ".join(f"{n:02d}" for n in nums) + "\n")
        self.status_label.setText(f"已保存 {len(self.results)} 组至: {path}")

    def on_reset(self):
        defaults = [
            (self.sum_min, 70), (self.sum_max, 110),
            (self.span_min, 4), (self.span_max, 6),
            (self.ac_min, 2), (self.ac_max, 6),
            (self.zone_head_min, 1), (self.zone_head_max, 3),
            (self.zone_mid_min, 1), (self.zone_mid_max, 4),
            (self.zone_tail_min, 1), (self.zone_tail_max, 3),
            (self.con2_min, 0), (self.con2_max, 1),
            (self.con3_min, 0), (self.con3_max, 1),
            (self.tail_min, 1), (self.tail_max, 5),
            (self.rep_min, 0), (self.rep_max, 2),
            (self.nbr_min, 1), (self.nbr_max, 3),
            (self.orph_min, 1), (self.orph_max, 4),
        ]
        for spin_box, val in defaults:
            spin_box.setValue(val)
        for mn, mx in self.mod3_spins:
            mn.setValue(0)
            mx.setValue(5)
        self.chk_mod3.setChecked(True)
        for mn, mx in self.mod7_spins:
            mn.setValue(0)
            mx.setValue(2)
        self.chk_mod7.setChecked(True)
        self.chk_mod7_span.setChecked(True)
        self.mod7_span_min.setValue(2)
        self.mod7_span_max.setValue(4)
        self.chk_tsum.setChecked(True)
        self.tsum_min.setValue(10)
        self.tsum_max.setValue(34)
        for i, (mn, mx) in enumerate(self.tailwx_spins):
            mn.setValue(TAIL_WX_DEFAULTS[i][0])
            mx.setValue(TAIL_WX_DEFAULTS[i][1])
        self.tailwx_kind_min.setValue(2)
        self.tailwx_kind_max.setValue(5)
        for i, (mn, mx) in enumerate(self.tailcolor_spins):
            mn.setValue(TAIL_COLOR_DEFAULTS[i][0])
            mx.setValue(TAIL_COLOR_DEFAULTS[i][1])
        for mn, mx in self.wave_spins:
            mn.setValue(0)
            mx.setValue(3)
        for checks in (self.odd_checks, self.big_checks, self.prime_checks):
            for cb in checks:
                cb.setChecked(False)
        self.chk_span.setChecked(True)
        self.chk_tailwx.setChecked(True)
        self.chk_tailcolor.setChecked(True)
        self.chk_wave.setChecked(True)
        self.chk_sum.setChecked(True)
        self.chk_con.setChecked(True)
        self.chk_san.setChecked(True)
        for i, cb in enumerate(self.san_pattern_checks):
            cb.setChecked(i < len(SAN_PATTERNS[0]))
        for mn, mx in self.san_spins:
            mn.setValue(0)
            mx.setValue(3)
        self.chk_dangroup.setChecked(False)
        for mn, mx in self.dangroup_spins:
            mn.setValue(0)
            mx.setValue(5)
        self.chk_zone.setChecked(True)
        self.chk_wx.setChecked(True)
        self.chk_rn.setChecked(True)
        self.chk_yj.setChecked(True)
        self.chk_four.setChecked(True)
        for i, (mn, mx) in enumerate(self.four_spins):
            mn.setValue(FOUR_DEFAULTS[i][0])
            mx.setValue(FOUR_DEFAULTS[i][1])
        self.chk_five.setChecked(True)
        for mn, mx in self.wx_spins:
            mn.setValue(0)
            mx.setValue(3)
        for i, (mn, mx) in enumerate(self.yj_spins):
            mn.setValue(YJ_DEFAULTS[i][0])
            mx.setValue(YJ_DEFAULTS[i][1])
        self.chk_seven.setChecked(True)
        self.chk_seven_span.setChecked(True)
        for i, (mn, mx) in enumerate(self.five_spins):
            mn.setValue(FIVE_DEFAULTS[i][0])
            mx.setValue(FIVE_DEFAULTS[i][1])
        for i, (mn, mx) in enumerate(self.seven_spins):
            mn.setValue(SEVEN_DEFAULTS[i][0])
            mx.setValue(SEVEN_DEFAULTS[i][1])
        self.seven_span_min.setValue(SEVEN_SPAN_DEFAULT[0])
        self.seven_span_max.setValue(SEVEN_SPAN_DEFAULT[1])
        self.chk_edge.setChecked(True)
        self.edge_min.setValue(0)
        self.edge_max.setValue(3)
        self.chk_edge7.setChecked(True)
        self.edge7_min.setValue(0)
        self.edge7_max.setValue(4)
        for edit in (self.kill_edit, self.dan_edit, self.prev_edit):
            edit.clear()
        self.status_label.setText("条件已重置")


def main():
    app = QApplication(sys.argv)
    app.setFont(QFont("Microsoft YaHei UI", 9))
    app.setStyleSheet(STYLE_SHEET)
    win = ShrinkWindow()
    win.show()
    sys.exit(app.exec_())


if __name__ == "__main__":
    main()

