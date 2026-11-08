# -*- coding: utf-8 -*-
"""大乐透前区缩水过滤条件计算模块（纯逻辑, 不依赖 Qt）。

从 shrink_tool.py 提取的全部筛选计算方法:
    常量定义 / 连号统计 / AC值 / FilterConditions(所有筛选条件的匹配计算)
"""

PRIMES = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31}

BIG_BOUNDARY = 18  # 1~17 为小, 18~35 为大
# 龙头/中间/凤尾分区定义(区间可重叠, 同一号码计入其所属的每个分区)
ZONE_HEAD = (1, 13)   # 龙头 01~13
ZONE_MID = (9, 26)    # 中间 09~26
ZONE_TAIL = (24, 35)  # 凤尾 24~35
# 五行(洛书)分区: 尾数1/6=水 2/7=火 3/8=木 4/9=金 5/0=土, 共5组各7个号, 组间不重叠
WX_ZONES = (
    ("金", frozenset((4, 14, 24, 34, 9, 19, 29))),
    ("木", frozenset((3, 13, 23, 33, 8, 18, 28))),
    ("水", frozenset((1, 11, 21, 31, 6, 16, 26))),
    ("火", frozenset((2, 12, 22, 32, 7, 17, 27))),
    ("土", frozenset((5, 15, 25, 35, 10, 20, 30))),
)
# 五行(易经)分区(与洛书分法不同): 覆盖1~35, 组间不重叠; 默认金木水火土出号0~3, 土1~4
YJ_ZONES = (
    ("金", frozenset((9, 10, 21, 22, 33, 34))),
    ("木", frozenset((3, 4, 15, 16, 27, 28))),
    ("水", frozenset((1, 12, 13, 24, 25))),
    ("火", frozenset((6, 7, 18, 19, 30, 31))),
    ("土", frozenset((2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35))),
)
YJ_DEFAULTS = ((0, 3), (0, 3), (0, 3), (0, 3), (1, 4))
# 五行尾数: 按个位尾数分五行(金4,9/木3,8/水1,6/火2,7/土0,5); 默认金木水火尾0~1, 土尾1~2
TAIL_WX = (
    ("金尾", frozenset((4, 9))),
    ("木尾", frozenset((3, 8))),
    ("水尾", frozenset((1, 6))),
    ("火尾", frozenset((2, 7))),
    ("土尾", frozenset((0, 5))),
)
TAIL_WX_DEFAULTS = ((0, 1), (0, 1), (0, 1), (0, 1), (1, 2))
# 尾数红蓝绿: 按个位尾数分色(红1,2,7,8 / 蓝3,4,9,0 / 绿5,6)
TAIL_COLOR = (
    ("红尾", frozenset((1, 2, 7, 8))),
    ("蓝尾", frozenset((3, 4, 9, 0))),
    ("绿尾", frozenset((5, 6))),
)
TAIL_COLOR_DEFAULTS = ((0, 5),) * 3
# 红蓝绿波(双色球波色划分): 红/蓝各12个号, 绿11个号
WAVE_ZONES = (
    ("红", frozenset((1, 2, 7, 8, 12, 13, 18, 19, 23, 24, 29, 30))),
    ("蓝", frozenset((3, 4, 9, 10, 14, 15, 20, 25, 26, 31, 34, 35))),
    ("绿", frozenset((5, 6, 11, 16, 17, 21, 22, 27, 28, 32, 33))),
)
WAVE_DEFAULTS = ((0, 3),) * 3
# 三区间比: 1区01~11 / 2区12~22 / 3区23~35; 各档为允许的(1区:2区:3区)分布
SAN_RANGES = ((1, 11), (12, 22), (23, 35))
SAN_PATTERNS = (
    ((2, 2, 1), (2, 1, 2), (1, 2, 2), (3, 2, 1), (1, 3, 1), (1, 1, 3)),   # 一次选(常态)
    ((3, 2, 0), (3, 0, 2), (2, 3, 0), (0, 3, 2), (2, 0, 3), (0, 2, 3)),   # 二次选(偏态)
    ((5, 0, 0), (0, 5, 0), (0, 0, 5)),                                    # 三次选(极端)
)
SAN_TIER_NAMES = ("一次选(常态)", "二次选(偏态)", "三次选(极端)")
SAN_ALL_PATTERNS = tuple(p for tier in SAN_PATTERNS for p in tier)  # 15种比例平铺
# 固定胆组: 8组预定义号码集合, 每组可设出号个数范围(默认0~5=不过滤)
DAN_GROUPS = (
    (5, 15, 25, 35, 10, 20, 30),
    tuple(range(1, 15)),
    (2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35),
    (7, 14, 21, 28, 35, 1, 8, 15, 22, 29),
    (2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35),
    (1, 2, 7, 8, 12, 13, 18, 19, 23, 24, 29, 30),
    (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31),
    (1, 4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20, 21, 22, 24, 25, 26, 27, 28, 30, 32, 33, 34, 35),
)
# 5分区: 每区7个连续号, 组间不重叠; 默认2区最多出2个, 其余0~3
FIVE_ZONES = ((1, 7), (8, 14), (15, 21), (22, 28), (29, 35))
FIVE_DEFAULTS = ((0, 3), (0, 2), (0, 3), (0, 3), (0, 3))
# 4分区(十位段): 0区01~09 / 1区10~19 / 2区20~29 / 3区30~35, 组间不重叠
FOUR_ZONES = ((1, 9), (10, 19), (20, 29), (30, 35))
FOUR_DEFAULTS = ((0, 3), (0, 2), (0, 2), (0, 3))
# 5区边缘码: 各分区首尾号(每分区边缘码最多1个)
EDGE_NUMS = frozenset((1, 7, 8, 14, 15, 21, 22, 28, 29, 35))
# 7区边缘码: 各分区首尾号(每分区边缘码最多1个)
EDGE7_NUMS = frozenset((1, 5, 6, 10, 11, 15, 16, 20, 21, 25, 26, 30, 31, 35))
# 7分区: 每区5个连续号, 组间不重叠; 默认1区/7区最多3个, 其余最多2个
SEVEN_ZONES = ((1, 5), (6, 10), (11, 15), (16, 20), (21, 25), (26, 30), (31, 35))
SEVEN_DEFAULTS = ((0, 3), (0, 2), (0, 2), (0, 2), (0, 2), (0, 2), (0, 3))
# 7分区跨区: 5个号覆盖的分区数范围
SEVEN_SPAN_DEFAULT = (2, 4)


def consecutive_stats(nums):
    """返回 (2连号组数, 三连号及以上组数)。"""
    two = three = 0
    run = 1
    for a, b in zip(nums, nums[1:]):
        if b - a == 1:
            run += 1
        else:
            if run == 2:
                two += 1
            elif run >= 3:
                three += 1
            run = 1
    if run == 2:
        two += 1
    elif run >= 3:
        three += 1
    return two, three


def ac_value(nums):
    """AC 值: 两两差绝对值去重个数 - (n-1)。"""
    diffs = {abs(a - b) for i, a in enumerate(nums) for b in nums[i + 1:]}
    return len(diffs) - (len(nums) - 1)


class FilterConditions:
    """缩水条件集合。某项未启用时跳过该项过滤。"""

    def __init__(self):
        self.sum_filter = True         # 和值区间开关
        self.sum_min, self.sum_max = 15, 165
        self.span_filter = True        # 跨度区间开关
        self.span_min, self.span_max = 4, 6  # 跨度范围
        self.ac_min, self.ac_max = 0, 6
        self.zone_filter = True       # 龙头/中间/凤尾分区出号开关
        self.zone_head_min, self.zone_head_max = 1, 3  # 龙头(01~13)出号个数
        self.zone_mid_min, self.zone_mid_max = 1, 4    # 中间(09~26)出号个数
        self.zone_tail_min, self.zone_tail_max = 1, 3  # 凤尾(24~35)出号个数
        self.wx_filter = True          # 五行(洛书)分区出号开关
        self.wx_limits = ((0, 3),) * 5  # 金木水火土 各分区出号个数范围
        self.yj_filter = True          # 五行(易经)分区出号开关
        self.yj_limits = YJ_DEFAULTS    # 金木水火土 各分区出号个数范围
        self.five_filter = True        # 5分区出号开关
        self.five_limits = FIVE_DEFAULTS  # 1~5区 各分区出号个数范围
        self.four_filter = True        # 4分区出号开关
        self.four_limits = FOUR_DEFAULTS  # 0~3区 各分区出号个数范围
        self.seven_filter = True       # 7分区出号开关
        self.seven_limits = SEVEN_DEFAULTS  # 1~7区 各分区出号个数范围
        self.seven_span_filter = True  # 7分区跨区开关
        self.seven_span_min, self.seven_span_max = SEVEN_SPAN_DEFAULT  # 覆盖分区数范围
        self.edge_filter = True        # 5区边缘码过滤开关
        self.edge_min, self.edge_max = 0, 3  # 边缘码总个数范围
        self.edge7_filter = True       # 7区边缘码过滤开关
        self.edge7_min, self.edge7_max = 0, 4  # 边缘码总个数范围
        self.odd_counts = None        # set of 合法奇数个数, None 表示不过滤
        self.big_counts = None        # set of 合法大号个数
        self.prime_counts = None      # set of 合法质数个数
        self.mod3_filter = True       # 012路出号开关
        self.mod3_limits = ((0, 5),) * 3  # 0/1/2路 各路出号个数范围
        self.mod7_filter = True       # 除7余数出号开关
        self.mod7_limits = ((0, 2),) * 7  # 余0~余6 每组出号个数范围
        self.mod7_span_filter = True  # 余7跨区开关
        self.mod7_span_min, self.mod7_span_max = 2, 4  # 覆盖余数组数范围
        self.con_filter = True         # 连号过滤开关
        self.con2_min, self.con2_max = 0, 1  # 2连号组数范围
        self.con3_min, self.con3_max = 0, 1  # 三连号及以上组数范围
        self.tail_min, self.tail_max = 1, 5
        self.tsum_filter = True        # 尾数之和过滤开关
        self.tsum_min, self.tsum_max = 10, 34  # 尾数(个位)之和范围
        self.tailwx_filter = True      # 五行尾数过滤开关
        self.tailwx_limits = TAIL_WX_DEFAULTS  # 金木水火土尾 各出号个数范围
        self.tailwx_kind_min, self.tailwx_kind_max = 2, 5  # 五行尾数种类范围
        self.tailcolor_filter = True   # 尾数红蓝绿过滤开关
        self.tailcolor_limits = TAIL_COLOR_DEFAULTS  # 红/蓝/绿尾 各出号个数范围
        self.wave_filter = True        # 红蓝绿波过滤开关
        self.wave_limits = WAVE_DEFAULTS  # 红蓝绿 各波出号个数范围
        self.san_filter = True         # 三区间比开关
        self.san_patterns = (True,) * 6 + (False,) * 9  # 15种比例勾选(默认常态6种)
        self.san_limits = ((0, 3), (0, 3), (0, 3))  # 1~3区出号个数范围
        self.dangroup_filter = False   # 固定胆组开关(各组默认0~5=不过滤)
        self.dangroup_limits = ((0, 5),) * len(DAN_GROUPS)
        self.kill = set()             # 杀号
        self.dan = set()              # 胆码
        self.prev_draw = None         # 上期号码 frozenset
        self.rn_filter = True         # 重邻孤过滤开关(需填上期号码)
        self.rep_min, self.rep_max = 0, 2   # 重号(上期开奖号)个数范围
        self.nbr_min, self.nbr_max = 1, 3   # 邻号(上期号±1, 剔除重号)个数范围
        self.orph_min, self.orph_max = 1, 4 # 孤号(非重非邻)个数范围

    def match(self, nums):
        num_set = set(nums)
        if self.kill & num_set:
            return False
        if not (self.ac_min <= ac_value(nums) <= self.ac_max):
            return False
        if self.zone_filter:
            h = sum(ZONE_HEAD[0] <= n <= ZONE_HEAD[1] for n in nums)
            if not (self.zone_head_min <= h <= self.zone_head_max):
                return False
            m = sum(ZONE_MID[0] <= n <= ZONE_MID[1] for n in nums)
            if not (self.zone_mid_min <= m <= self.zone_mid_max):
                return False
            t = sum(ZONE_TAIL[0] <= n <= ZONE_TAIL[1] for n in nums)
            if not (self.zone_tail_min <= t <= self.zone_tail_max):
                return False
        if self.wx_filter:
            for i, (_, elements) in enumerate(WX_ZONES):
                wmin, wmax = self.wx_limits[i]
                if not (wmin <= sum(n in elements for n in nums) <= wmax):
                    return False
        if self.yj_filter:
            for i, (_, elements) in enumerate(YJ_ZONES):
                wmin, wmax = self.yj_limits[i]
                if not (wmin <= sum(n in elements for n in nums) <= wmax):
                    return False
        if self.four_filter:
            for i, (lo, hi) in enumerate(FOUR_ZONES):
                fmin, fmax = self.four_limits[i]
                if not (fmin <= sum(lo <= n <= hi for n in nums) <= fmax):
                    return False
        if self.five_filter:
            for i, (lo, hi) in enumerate(FIVE_ZONES):
                fmin, fmax = self.five_limits[i]
                if not (fmin <= sum(lo <= n <= hi for n in nums) <= fmax):
                    return False
        if self.seven_filter:
            for i, (lo, hi) in enumerate(SEVEN_ZONES):
                smin, smax = self.seven_limits[i]
                if not (smin <= sum(lo <= n <= hi for n in nums) <= smax):
                    return False
        if self.seven_span_filter:
            zones_hit = sum(any(lo <= n <= hi for n in nums) for lo, hi in SEVEN_ZONES)
            if not (self.seven_span_min <= zones_hit <= self.seven_span_max):
                return False
        if self.edge_filter:
            if not (self.edge_min <= sum(n in EDGE_NUMS for n in nums) <= self.edge_max):
                return False
            if any((lo in num_set) + (hi in num_set) > 1 for lo, hi in FIVE_ZONES):
                return False
        if self.edge7_filter:
            if not (self.edge7_min <= sum(n in EDGE7_NUMS for n in nums) <= self.edge7_max):
                return False
            if any((lo in num_set) + (hi in num_set) > 1 for lo, hi in SEVEN_ZONES):
                return False

        if self.sum_filter:
            if not (self.sum_min <= sum(nums) <= self.sum_max):
                return False
        span = nums[-1] - nums[0]
        if self.span_filter:
            if not (self.span_min <= span <= self.span_max):
                return False

        if self.odd_counts is not None and sum(n % 2 for n in nums) not in self.odd_counts:
            return False
        if self.big_counts is not None and sum(n >= BIG_BOUNDARY for n in nums) not in self.big_counts:
            return False
        if self.prime_counts is not None and sum(n in PRIMES for n in nums) not in self.prime_counts:
            return False

        mod3 = [0, 0, 0]
        for n in nums:
            mod3[n % 3] += 1
        if self.mod3_filter:
            if any(not (self.mod3_limits[i][0] <= mod3[i] <= self.mod3_limits[i][1])
                   for i in range(3)):
                return False

        mod7 = [0] * 7
        for n in nums:
            mod7[n % 7] += 1
        if self.mod7_filter:
            if any(not (self.mod7_limits[i][0] <= mod7[i] <= self.mod7_limits[i][1])
                   for i in range(7)):
                return False
        if self.mod7_span_filter:
            zones_hit = sum(1 for c in mod7 if c)
            if not (self.mod7_span_min <= zones_hit <= self.mod7_span_max):
                return False

        two_groups, three_groups = consecutive_stats(nums)
        if self.con_filter:
            if not (self.con2_min <= two_groups <= self.con2_max):
                return False
            if not (self.con3_min <= three_groups <= self.con3_max):
                return False

        tails = len({n % 10 for n in nums})
        if not (self.tail_min <= tails <= self.tail_max):
            return False
        if self.tsum_filter:
            tsum = sum(n % 10 for n in nums)
            if not (self.tsum_min <= tsum <= self.tsum_max):
                return False
        if self.tailwx_filter:
            violations = 0
            kinds = 0
            for i, (_, tset) in enumerate(TAIL_WX):
                cnt = sum(n % 10 in tset for n in nums)
                kmin, kmax = self.tailwx_limits[i]
                if kmin <= cnt <= kmax:
                    if cnt:
                        kinds += 1
                else:
                    violations += 1
            if not (self.tailwx_kind_min <= kinds <= self.tailwx_kind_max):
                violations += 1
            if violations:
                return False
        if self.tailcolor_filter:
            for i, (_, tset) in enumerate(TAIL_COLOR):
                cmin, cmax = self.tailcolor_limits[i]
                if not (cmin <= sum(n % 10 in tset for n in nums) <= cmax):
                    return False
        if self.wave_filter:
            violations = 0
            for i, (_, elements) in enumerate(WAVE_ZONES):
                wmin, wmax = self.wave_limits[i]
                if not (wmin <= sum(n in elements for n in nums) <= wmax):
                    violations += 1
            if violations:
                return False
        if self.san_filter:
            counts = tuple(sum(lo <= n <= hi for n in nums) for lo, hi in SAN_RANGES)
            allowed = tuple(p for sel, p in zip(self.san_patterns, SAN_ALL_PATTERNS) if sel)
            if allowed and counts not in allowed:
                return False
            violations = sum(1 for i in range(3)
                             if not (self.san_limits[i][0] <= counts[i] <= self.san_limits[i][1]))
            if violations:
                return False
        if self.dangroup_filter:
            for i, group in enumerate(DAN_GROUPS):
                gmin, gmax = self.dangroup_limits[i]
                if not (gmin <= sum(n in group for n in nums) <= gmax):
                    return False

        if self.dan and not self.dan <= num_set:
            return False

        if self.rn_filter and self.prev_draw is not None:
            rep = nbr = 0
            for n in nums:
                if n in self.prev_draw:
                    rep += 1
                elif (n - 1) in self.prev_draw or (n + 1) in self.prev_draw:
                    nbr += 1
            if not (self.rep_min <= rep <= self.rep_max):
                return False
            if not (self.nbr_min <= nbr <= self.nbr_max):
                return False
            if not (self.orph_min <= 5 - rep - nbr <= self.orph_max):
                return False

        return True
