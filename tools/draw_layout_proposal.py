"""Generate a discussion diagram, never a runtime game scene or save migration."""
from pathlib import Path
import base64
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'builds/local-validation/v08-layout-proposal-a.svg'
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
parts = ['''<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="1000" viewBox="0 0 1600 1000">
<defs><linearGradient id="sky" x2="0" y2="1"><stop stop-color="#dce9e8"/><stop offset="1" stop-color="#a8c6cb"/></linearGradient>
<linearGradient id="rock" x2="0" y2="1"><stop stop-color="#698e8c"/><stop offset="1" stop-color="#b7d1cf"/></linearGradient>
<pattern id="paper" width="12" height="12" patternUnits="userSpaceOnUse"><rect width="12" height="12" fill="#f4eddc"/><path d="M0 6h12M6 0v12" stroke="#cfbf9d" opacity=".08"/></pattern>
<style>text{font-family:'Microsoft YaHei','Noto Sans CJK SC',sans-serif;fill:#203d40} .serif{font-family:SimSun,serif} .tiny{font-size:14px} .small{font-size:17px} .label{font-size:20px} .light{fill:#f4eddc} .muted{fill:#537572} .zone{fill:#b8cbb4;stroke:#829d83;stroke-width:1.5;stroke-dasharray:7 7} .road{fill:none;stroke:#f4ecdb;stroke-linejoin:round;stroke-linecap:round}</style></defs>
<rect width="1600" height="1000" fill="url(#sky)"/>
<path d="M0 290L80 120 130 260 230 80 310 320 390 190 440 380 0 520zM1240 380l90-260 60 130 80-190 130 370v300z" fill="#7fa1a3" opacity=".23"/>
<path d="M0 480Q160 410 350 490T760 460T1200 480T1600 410V1000H0Z" fill="#edf2e9" opacity=".45"/>
<path d="M175 510L750 205 1310 505 1210 810 835 950 340 800Z" fill="url(#rock)"/>
<path d="M175 510L750 205 1310 505 835 850 340 715Z" fill="#b4c0a2" stroke="#6d8e83" stroke-width="4"/>
<path d="M195 507L750 228 1288 505 833 823 355 702Z" fill="#dce0c9" stroke="#eee8d7" stroke-width="8"/>
<path d="M747 275L765 510 845 723 844 810M360 549L765 510 1130 552M493 378L765 510 1085 395" class="road" stroke-width="39"/>
<path d="M747 275L765 510 845 723 844 810M360 549L765 510 1130 552M493 378L765 510 1085 395" fill="none" stroke="#b9b49b" stroke-width="1"/>
<ellipse cx="765" cy="515" rx="150" ry="75" fill="#f4ecdb" stroke="#b4ab8b" stroke-width="2"/>
<ellipse cx="765" cy="515" rx="122" ry="60" fill="none" stroke="#c4b795" stroke-width="2"/>
<ellipse cx="765" cy="515" rx="75" ry="37" fill="none" stroke="#c4b795"/>
<path d="M392 409l132-66 142 70-129 66zM955 424l116-58 138 67-122 67zM433 654l133-68 131 66-130 70zM962 637l137-69 132 63-143 76z" class="zone"/>
<path d="M635 690q68-72 124-36t33 84q-42 51-98 21t-59-69z" fill="#81b4b0" stroke="#dfdfc8" stroke-width="10"/>
<path d="M1180 515q45 40 27 83t-57 52" fill="none" stroke="#8eb8b0" stroke-width="19"/>
<path d="M745 333l24-13 73 37-24 13zM736 344l24-13 73 37-24 13zM727 355l24-13 73 37-24 13z" fill="#ede5d0" stroke="#c4b795"/>
''']

def text(x, y, value, cls='label', anchor='start'):
    parts.append(f'<text x="{x}" y="{y}" class="{cls}" text-anchor="{anchor}">{value}</text>')

def image_asset(path, x, y, width, height, viewbox=None):
    encoded = base64.b64encode((ROOT / path).read_bytes()).decode('ascii')
    if viewbox:
        parts.append(f'<svg x="{x}" y="{y}" width="{width}" height="{height}" viewBox="{viewbox}"><image width="1671" height="941" href="data:image/png;base64,{encoded}"/></svg>')
    else:
        parts.append(f'<image x="{x}" y="{y}" width="{width}" height="{height}" href="data:image/png;base64,{encoded}"/>')

def plaque(x, y, title, note):
    parts.append(f'<rect x="{x-80}" y="{y-22}" width="160" height="33" rx="5" fill="#203e42"/>')
    text(x, y, title, 'small light', 'middle')
    text(x, y+32, note, 'tiny', 'middle')

# Independent existing project sprites are shown at candidate screen anchors.
# Positions here are diagram coordinates, not proposed save cell coordinates.
image_asset('assets/buildings/main-hall-sample.png', 620, 126, 290, 290)
image_asset('assets/buildings/disciple-quarters-sample.png', 406, 317, 176, 176)
atlas = 'assets/buildings/sect_buildings_atlas.png'
image_asset(atlas, 460, 217, 110, 124, '835.5 470.5 417.75 470.5')
image_asset(atlas, 992, 311, 178, 165, '0 470.5 417.75 470.5')
image_asset(atlas, 1025, 506, 155, 166, '417.75 470.5 417.75 470.5')
image_asset(atlas, 478, 565, 166, 143, '1253.25 0 417.75 470.5')
image_asset(atlas, 282, 476, 140, 147, '417.75 0 417.75 470.5')
image_asset(atlas, 1165, 449, 125, 138, '835.5 0 417.75 470.5')
for x,y,name,note in [(765,377,'主殿高台','固定中轴 · 不与生活院落重叠'),(493,485,'生活区','弟子居推荐 · 可自由建设'),(513,329,'藏经阁','后侧窄高建筑 · 主次分明'),(1080,470,'演武区','侧翼展开 · 预留周围视线'),(1105,661,'工坊区','炼器坊推荐 · 道路连接'),(561,705,'灵田区','前侧低矮建筑 · 不挡主殿'),(339,616,'林地与伐木','外围资源点'),(1228,581,'矿脉','外围资源点')]:
    plaque(x,y,name,note)
text(765,528,'主殿前庭', 'label', 'middle')
text(845,801,'入口 · 山门步道', 'small', 'middle')
text(700,745,'池水与园林', 'tiny', 'middle')
# Decorative garden markers represent environmental distribution, not new resources.
for x,y in [(250,505),(400,357),(596,317),(901,338),(1185,441),(916,780),(430,680),(910,610)]:
    parts.append(f'<ellipse cx="{x}" cy="{y+10}" rx="22" ry="11" fill="#708c76" opacity=".25"/><path d="M{x} {y+10}v-30" stroke="#7d7254" stroke-width="4"/><ellipse cx="{x}" cy="{y-22}" rx="21" ry="16" fill="#537d69"/><ellipse cx="{x+9}" cy="{y-34}" rx="15" ry="11" fill="#719078"/>')
# Compact HUD and a small context card, deliberately separate from the map diagram.
parts.append('<rect x="30" y="24" width="1540" height="67" rx="12" fill="#18383e" stroke="#ad9460"/>')
text(58,66,'青云宗', 'label light')
text(165,66,'Lv.3', 'small light')
for x, label in [(480,'木材 80'),(655,'灵石 70'),(830,'灵谷 150'),(1030,'弟子 3/5')]:
    text(x,66,label,'label light')
text(1425,66,'保存', 'small light')
parts.append('<rect x="1324" y="136" width="246" height="257" rx="8" fill="url(#paper)" stroke="#a88d58"/><path d="M1332 136h230q8 0 8 8v43h-246v-43q0-8 8-8" fill="#24464a"/>')
text(1344,169,'弟子居', 'label light'); text(1541,169,'×','label light')
text(1344,223,'等级 1', 'small');text(1344,258,'人口上限 +2', 'small')
for x,label in [(1343,'升级'),(1456,'管理')]:
    parts.append(f'<rect x="{x}" y="287" width="96" height="39" rx="4" fill="#294b4d"/>')
    text(x+48,314,label,'small light','middle')
text(1344,364,'点建筑后显示 · 默认收起','tiny muted')
parts.append('<rect x="1324" y="429" width="246" height="240" rx="8" fill="#f4eddc" fill-opacity=".85"/>')
text(1343,461,'布局提案 A','label')
for y,line in [(498,'后殿 · 两翼 · 前庭'),(533,'虚线：推荐建设区域'),(568,'道路 / 水面：环境骨架'),(603,'16×12：候选编辑范围'),(638,'最终格子与占地尚未定稿')]:
    text(1343,y,line,'small muted')
for i,label in enumerate(['宗门','建设','弟子','养成','挂机']):
    x=455+i*142
    parts.append(f'<rect x="{x}" y="905" width="130" height="57" rx="9" fill="#203f43" stroke="{("#c4a25e" if i==0 else "#8b9e8d")}" stroke-width="{2 if i==0 else 1}"/>')
    text(x+65,942,label,'label light','middle')
text(32,949,'布局示意 · 非游戏运行画面', 'label')
text(32,978,'建筑图仅复用现有资产；示例布置不代表初始赠送', 'tiny muted')
parts.append('</svg>')
source=''.join(parts)
ET.fromstring(source)
OUTPUT.write_text(source, encoding='utf-8')
print(f'Created {OUTPUT} ({OUTPUT.stat().st_size} bytes)')
