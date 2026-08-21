class_name UIColors
extends Object

## =============================================================================
## UI 核心色彩常量与单一真值来源
## 遵循项目设计规范（dev_standards.md 六.5）与全局 Theme 体系
## =============================================================================

# --- 六大核心属性色（微调低荧光版本，统一高级质感）---
const ATK := Color("#F04A5D")
const DEF := Color("#E8BE3A")
const SPD := Color("#20D9F2")
const HP := Color("#45E68A")
const MP := Color("#A66BE8")
const FP := Color("#F28A3D")

const STAT_COLORS: Dictionary[StringName, Color] = {
	&"atk": ATK,
	&"def": DEF,
	&"spd": SPD,
	&"hp": HP,
	&"mp": MP,
	&"fp": FP,
}

# --- 文本色彩体系 ---
const TEXT_MAIN := Color("#D9E5E8")              # 主正文文本
const TEXT_MUTED := Color("#8EA3AA")             # 辅助文本/注释/次级标签
const TEXT_TITLE := Color("#EAF4F5")             # 标题文本
const TEXT_WHITE := Color("#FFFFFFFF")           # 高亮白色文本
const TEXT_TRANSLUCENT_60 := Color("#FFFFFF99")  # 60% 不透明度白色
const TEXT_TRANSLUCENT_40 := Color("#FFFFFF66")  # 40% 不透明度白色

# --- 背景与边框体系 ---
const BG_DARK := Color("#0A1217F2")              # 深蓝黑主背景
const BG_INSET := Color("#0D181DDE")             # 嵌板/次级背景
const BG_BUTTON_NORMAL := Color("#152229E8")     # 按钮常态背景
const BG_BUTTON_HOVER := Color("#1B3138F2")      # 按钮悬停背景
const BG_BUTTON_FOCUS := Color("#173842FA")      # 按钮选中背景

const BORDER_NORMAL := Color("#354A52")          # 常态边框（低对比灰蓝）
const BORDER_MUTED := Color("#2C3E45")           # 弱化次级边框
const BORDER_SUBTLE := Color("#1E2D33")          # 极弱分割边框

# --- 交互与状态强调色体系 ---
const ACCENT_CYAN := Color("#20D9F2")            # 主交互青色高亮（Hover / Focus / Selected）
const ACCENT_WARN := Color("#F28A3D")            # 警告/提示强调色（与 FP 协调）
const ACCENT_DANGER := Color("#F04A5D")          # 危险/致命/错误状态色（与 ATK 协调）
const ACCENT_SUCCESS := Color("#45E68A")         # 成功/就绪/增益状态色（与 HP 协调）

# --- 数值预览与护盾色彩 ---
const PREVIEW_GAIN := Color("#45E68A")
const PREVIEW_LOSS := Color("#F04A5D")
const PREVIEW_SHIELD := Color("#20D9F2")
const SHIELD_BAR := Color("#45AAF2")
const SHIELD_VALUE := Color("#50C8FF")
const GRID_EMPTY := Color("#52656D")
const BUFF := Color("#45E68A")
const DEBUFF := Color("#F04A5D")
const NEUTRAL := Color("#D9E5E8")

# --- 遮罩色彩 ---
const BACKDROP_MODAL := Color(0.0, 0.0, 0.0, 0.45) # 0.45 半透明遮罩


static func get_stat_color(stat_id: StringName, fallback: Color = TEXT_MAIN) -> Color:
	return STAT_COLORS.get(stat_id, fallback)
