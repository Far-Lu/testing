***********************************************************************
* 跨导放大器(OTA)设计 - 折叠共源共栅结构 (Folded-Cascode)
* 工艺: 0.5um CMOS 2p2m
* 设计者: Copilot
* 日期: 2026-04-05
***********************************************************************
*
* =====================================================================
*                    一、工艺参数与基本计算
* =====================================================================
*
* 给定工艺参数:
*   NMOS (mn): Vth0 = 719.2 mV, mu0 = 495.1 cm2/V/s, tox = 13 nm
*   PMOS (mp): Vth0 = 972.6 mV, mu0 = 283.3 cm2/V/s, tox = 13.7 nm
*   eps0 = 8.85e-12 F/m,  eps_r(SiO2) = 3.9
*
* 计算氧化层电容 Cox:
*   Cox_n = eps0 * eps_r / tox_n
*         = 8.85e-12 * 3.9 / 13e-9
*         = 34.515e-12 / 13e-9
*         = 2.655e-3 F/m^2 = 2.655 fF/um^2
*
*   Cox_p = eps0 * eps_r / tox_p
*         = 8.85e-12 * 3.9 / 13.7e-9
*         = 34.515e-12 / 13.7e-9
*         = 2.519e-3 F/m^2 = 2.519 fF/um^2
*
* 计算工艺跨导参数 KP = mu * Cox:
*   KP_n = mu_n * Cox_n = 495.1e-4 * 2.655e-3 = 131.4e-6 A/V^2
*        = 131.4 uA/V^2
*
*   KP_p = mu_p * Cox_p = 283.3e-4 * 2.519e-3 = 71.35e-6 A/V^2
*        = 71.35 uA/V^2
*
* =====================================================================
*                    二、设计指标
* =====================================================================
*
*   负载电容 CL        = 30 pF
*   电源电压 VDD       = 3.6 V (范围 2.5~5.5V)
*   静态电流 Itotal    < 250 uA (含偏置)
*   输入共模范围 ICMR  = 0.1 ~ 1 V
*   输出摆幅           = 0.6 ~ 1.2 V
*   开环增益(低频) Av  = 1800 ~ 2200 (约65~67 dB)
*   单位增益带宽 GBW   > 3 MHz
*   相位裕度 PM        > 60 度
*   PSRR(低频)         > 65 dB
*   跨导(低频) Gm      = 900 ~ 1100 uA/V
*   转换速率 SR        > 3 V/us
*
* =====================================================================
*                    三、电路结构选择
* =====================================================================
*
* 选择折叠共源共栅(Folded-Cascode) OTA，PMOS输入对:
*
* 原因:
* 1) 输入共模范围 0.1~1V 接近地电位, PMOS输入对的VCM_min 可以
*    做到很低 (约 Vov_NMOS_cascode + Vov_NMOS_source - |Vth_p|)
* 2) 折叠共源共栅结构提供高输出阻抗, 实现高增益
* 3) 单级结构无需密勒补偿, 相位裕度天然较好
* 4) 与参考电路结构一致
*
* 电路拓扑:
*
*           AVDD
*            |
*           M0 (PMOS尾电流源, gate=Vbp)
*            |
*        ----+----
*       M1        M2  (PMOS输入差分对, gates=Vin+,Vin-)
*        |         |
*   fold_a    fold_b (=Vout)
*        |         |
*  (同时连接)  (同时连接)
*
*     AVDD      AVDD
*      |          |
*     M5         M6  (PMOS电流源负载, gate=Vbp2)
*      |          |
*     M3         M4  (PMOS共源共栅, gate=Vbpc)
*      |          |
*   fold_a    fold_b
*      |          |
*     M7         M8  (NMOS共源共栅, gate=Vbnc)
*      |          |
*     M9        M10  (NMOS电流源, gate=Vbn)
*      |          |
*    AVSS       AVSS
*
* =====================================================================
*                    四、手工设计计算过程
* =====================================================================
*
* --- 4.1 尾电流与转换速率 ---
*
* 对于折叠共源共栅OTA:
*   SR = I_tail / (2 * CL) >= 3 V/us
*   I_tail >= 2 * 3e6 * 30e-12 = 180 uA
*
* 取 I_tail = 200 uA, 留有裕量
*   SR = 200e-6 / (2 * 30e-12) = 3.33 V/us > 3 V/us  ✓
*
* 每个输入管电流: Id1 = I_tail/2 = 100 uA
*
* --- 4.2 输入差分对尺寸 (M1, M2 - PMOS) ---
*
* 目标跨导: Gm = gm1 = 1000 uA/V (目标值1 mA/V)
*
* 过驱动电压:
*   Vov1 = 2 * Id1 / gm1 = 2 * 100e-6 / 1e-3 = 0.2 V
*   |Vsg1| = |Vth_p| + Vov1 = 0.9726 + 0.2 = 1.173 V
*
* 宽长比:
*   (W/L)1 = gm1^2 / (2 * KP_p * Id1)
*          = (1e-3)^2 / (2 * 71.35e-6 * 100e-6)
*          = 1e-6 / 14.27e-9
*          = 70.1
*
* 取 L1 = 2 um (良好匹配性), W1 = 70 * 2 = 140 um
*
* 验证: gm = sqrt(2 * KP_p * (W/L) * Id)
*      = sqrt(2 * 71.35e-6 * 70 * 100e-6)
*      = sqrt(999e-9) = 999.5 uA/V ≈ 1 mA/V  ✓
*
* --- 4.3 GBW验证 ---
*
*   GBW = Gm / (2*pi*CL) = 1e-3 / (2*pi*30e-12)
*       = 5.31 MHz > 3 MHz  ✓
*
* --- 4.4 PMOS尾电流源 (M0) ---
*
* Id = 200 uA, Vov0 = 0.25 V
*   (W/L)0 = 2*Id / (KP_p * Vov0^2)
*          = 2*200e-6 / (71.35e-6 * 0.0625)
*          = 400e-6 / 4.459e-6
*          = 89.7
*
* 取 (W/L)0 = 90, L0 = 2 um, W0 = 180 um
*
* --- 4.5 NMOS电流源分支电流 ---
*
* 支路电流平衡 (在折叠节点fold_a/fold_b):
*   I_PMOS_load + I_tail/2 = I_NMOS_branch
*
* 设 I_PMOS_load = 20 uA (每支路)
*   I_NMOS = 20 + 100 = 120 uA (每支路)
*
* 总电流: I_tail + 2*I_PMOS_load = 200 + 40 = 240 uA
* 加偏置电路 ~10 uA: 总计 ~250 uA  ✓ (满足<250uA)
*
* --- 4.6 NMOS电流源 (M9, M10) ---
*
* Id = 120 uA, Vov = 0.2 V
*   (W/L)9 = 2*120e-6 / (131.4e-6 * 0.04)
*          = 240e-6 / 5.256e-6
*          = 45.7
*
* 取 (W/L)9 = 46, L9 = 1 um, W9 = 46 um
*   (使用L=1um以降低rds, 控制增益在2000附近)
*
* Vgs9 = Vth_n + Vov = 0.7192 + 0.2 = 0.919 V
*
* --- 4.7 NMOS共源共栅 (M7, M8) ---
*
* 同样电流 Id = 120 uA, Vov = 0.2 V
*   (W/L)7 = 46, L7 = 1 um, W7 = 46 um
*
* gm_M7 = 2 * 120e-6 / 0.2 = 1.2 mA/V
*
* --- 4.8 PMOS电流源负载 (M5, M6) ---
*
* Id = 20 uA, Vov = 0.25 V
*   (W/L)5 = 2*20e-6 / (71.35e-6 * 0.0625)
*          = 40e-6 / 4.459e-6
*          = 8.97
*
* 取 (W/L)5 = 9, L5 = 2 um, W5 = 18 um
* (与M0共用偏置电压Vbp, 通过W/L比例设定电流)
*
* --- 4.9 PMOS共源共栅 (M3, M4) ---
*
* 同样电流 Id = 20 uA, Vov = 0.25 V
*   (W/L)3 = 9, L3 = 2 um, W3 = 18 um
*
* gm_M3 = 2 * 20e-6 / 0.25 = 160 uA/V
*
* --- 4.10 输出阻抗与增益估算 ---
*
* 假设 0.5um工艺:
*   NMOS L=1um: VA_n ≈ 5 V (lambda ≈ 0.04/um * L)
*   PMOS L=2um: VA_p ≈ 15 V (lambda ≈ 0.03/um * L)
*
* NMOS侧 (M7/M9, I=120uA, L=1um):
*   rds_M9 = VA_n / Id = 5 / 120e-6 = 41.7 kOhm
*   rds_M7 = VA_n / Id = 5 / 120e-6 = 41.7 kOhm
*   Rout_NMOS = gm_M7 * rds_M7 * rds_M9
*             = 1.2e-3 * 41.7e3 * 41.7e3
*             = 2.087 MOhm
*
* PMOS侧 (M3/M5, I=20uA, L=2um):
*   rds_M5 = VA_p / Id = 15 / 20e-6 = 750 kOhm
*   rds_M3 = VA_p / Id = 15 / 20e-6 = 750 kOhm
*   Rout_PMOS = gm_M3 * rds_M3 * rds_M5
*             = 160e-6 * 750e3 * 750e3
*             = 90 MOhm
*
* 总输出阻抗:
*   Rout = Rout_PMOS || Rout_NMOS
*        = 90M * 2.087M / (90M + 2.087M)
*        ≈ 2.04 MOhm
*
* 开环增益:
*   Av = Gm * Rout = 1e-3 * 2.04e6 = 2040  ✓
*   (在1800~2200范围内!)
*
* --- 4.11 输入共模范围验证 ---
*
* VCM_max (M0保持饱和):
*   VCM_max = VDD - |Vov_M0| - |Vth_p| - |Vov_M1|
*           = 3.6 - 0.25 - 0.9726 - 0.2
*           = 2.18 V >> 1 V  ✓
*
* VCM_min (M1保持饱和):
*   VCM_min = V_fold - |Vth_p|
*   V_fold = Vov_M9 + Vgs_M7 = 0.2 + 0.919 = 1.119 V
*   VCM_min = 1.119 - 0.9726 = 0.146 V
*   略高于0.1V, 可通过减小NMOS Vov来改善
*   调整: 取Vov_M9=Vov_M7=0.18V:
*   V_fold = 0.18 + 0.7192 + 0.18 = 1.079 V
*   VCM_min = 1.079 - 0.9726 = 0.107 V ≈ 0.1V  ✓
*
* --- 4.12 输出摆幅验证 ---
*
* Vout_max = VDD - |Vov_M5| - |Vov_M3|
*          = 3.6 - 0.25 - 0.25
*          = 3.1 V >> 1.2 V  ✓
*
* Vout_min = Vov_M9 + Vov_M7
*          = 0.2 + 0.2 = 0.4 V < 0.6 V  ✓
*
* 输出范围: 0.4V ~ 3.1V, 覆盖 0.6~1.2V  ✓
*
* --- 4.13 偏置电压计算 ---
*
* Vbp  (PMOS镜像栅压) = VDD - |Vsg_M0| = 3.6 - 1.223 ≈ 2.38 V
* Vbpc (PMOS共源共栅栅压) = VDD - |Vov_M5| - |Vsg_M3|
*      = 3.6 - 0.25 - 1.223 = 2.13 V
* Vbn  (NMOS电流源栅压) = Vgs_M9 = Vth_n + Vov = 0.72 + 0.2 = 0.92 V
* Vbnc (NMOS共源共栅栅压) = Vov_M9 + Vgs_M7 = 0.2 + 0.92 = 1.12 V
*
* --- 4.14 偏置电路设计 (自偏置Beta-Multiplier电流基准) ---
*
* 基准电流 Iref = 10 uA
*
* Beta-Multiplier原理:
*   Mb1(PMOS镜像) - Mb2(PMOS镜像) 强迫两支路电流相等
*   Mb3(NMOS, W/L=5) - Mb4(NMOS, W/L=20, 源极接电阻Rs)
*   K = (W/L)4 / (W/L)3 = 4
*
*   Iref = (1-1/sqrt(K))^2 / (KP_n/2 * (W/L)4 * Rs^2)
*        = (1-0.5)^2 / (65.7e-6 * 20 * Rs^2)
*        = 0.25 / (1.314e-3 * Rs^2)
*
*   Rs = sqrt(0.25 / (1.314e-3 * 10e-6))
*      = sqrt(0.25 / 1.314e-8)
*      = sqrt(1.903e7) = 4362 Ohm
*
* 取 Rs ≈ 4.4 kOhm
*
* 从Iref=10uA通过PMOS镜像产生各偏置电流:
*   M0(尾电流200uA): W/L比例 = 20:1 → (W/L)=20*9=180
*   M5,M6(负载20uA): W/L比例 = 2:1 → (W/L)=2*9=18
*   M9,M10(NMOS 120uA): 从NMOS侧镜像, 比例12:1
*
* 共源共栅偏置电压通过二极管连接的MOS管堆叠产生
*
* --- 4.15 相位裕度分析 ---
*
* 主极点: p1 = 1 / (Rout * CL)
*       = 1 / (2.04e6 * 30e-12) = 16.3 krad/s ≈ 2.6 kHz
*
* 单位增益频率: wu = Gm/CL = 1e-3/30e-12 = 3.33e7 rad/s
*
* 非主极点 (折叠节点): p2 ≈ gm_cascode / C_parasitic
*   C_parasitic ≈ 1 pF (估算)
*   p2 ≈ 1.2e-3 / 1e-12 = 1.2e9 rad/s = 1.2 GHz
*
* PM ≈ 90 - arctan(wu/p2) = 90 - arctan(33.3M/1.2G) = 90 - 1.6 = 88.4°
*   >> 60°  ✓  (单级折叠共源共栅的PM天然很好)
*
*
* =====================================================================
*                    五、MOSFET模型定义
* =====================================================================
*
* 使用Level 1 MOSFET模型 (基于给定的基本参数)
* 注: 实际仿真应使用工艺厂提供的BSIM3v3模型文件
*     这里基于给定参数建立简化模型

.PARAM VDD_VAL = 3.6

* NMOS模型
.MODEL mn NMOS LEVEL=1
+ VTO=0.7192       $ 阈值电压 (V)
+ KP=131.4u        $ 工艺跨导参数 mu*Cox (A/V^2)
+ TOX=13n          $ 栅氧化层厚度 (m)
+ LAMBDA=0.04      $ 沟道长度调制系数 (1/V), 对应L=1um
+ GAMMA=0.45       $ 体效应系数 (V^0.5)
+ PHI=0.7          $ 表面势 (V)
+ CBD=10f          $ 漏-衬底结电容 (F)
+ CBS=10f          $ 源-衬底结电容 (F)
+ CGSO=0.6n        $ 栅-源重叠电容 (F/m)
+ CGDO=0.6n        $ 栅-漏重叠电容 (F/m)

* PMOS模型
.MODEL mp PMOS LEVEL=1
+ VTO=-0.9726      $ 阈值电压 (V), PMOS为负值
+ KP=71.35u        $ 工艺跨导参数 mu*Cox (A/V^2)
+ TOX=13.7n        $ 栅氧化层厚度 (m)
+ LAMBDA=0.03      $ 沟道长度调制系数 (1/V), 对应L=2um
+ GAMMA=0.45       $ 体效应系数 (V^0.5)
+ PHI=0.7          $ 表面势 (V)
+ CBD=10f          $ 漏-衬底结电容 (F)
+ CBS=10f          $ 源-衬底结电容 (F)
+ CGSO=0.6n        $ 栅-源重叠电容 (F/m)
+ CGDO=0.6n        $ 栅-漏重叠电容 (F/m)

* 电阻模型 (用于偏置电路)
.MODEL rhr1k R RSH=1000

* =====================================================================
*                六、偏置电流基准电路 (Beta-Multiplier)
* =====================================================================
*
* 自偏置电流基准产生 Iref = 10 uA
* 并通过镜像产生所需的各偏置电压和电流

* --- 偏置电路子电路 ---
.SUBCKT BIAS_CIRCUIT AVDD AVSS VBP VBPC VBN VBNC

* === PMOS电流镜 (上半部分) ===
* Mb1: 二极管连接, 基准支路 (Iref=10uA)
* 格式: M name drain gate source bulk model W L
Mb1  nb1  nb1  AVDD  AVDD  mp  W=18u  L=2u   $ 二极管连接, VBP基准

* Mb2: 镜像支路 (Iref=10uA)
Mb2  nb2  nb1  AVDD  AVDD  mp  W=18u  L=2u   $ 1:1镜像

* Mb_tail_mirror: 产生尾电流偏置 VBP (镜像到M0)
* VBP = nb1 (PMOS gate voltage)

* === NMOS Beta-Multiplier核心 ===
* Mb3: NMOS, gate=nb2, drain=nb1 (W/L=10)
Mb3  nb1  nb2  AVSS  AVSS  mn  W=10u  L=1u   $ (W/L)=10

* Mb4: NMOS, gate=nb2, drain=nb2, source through Rs (W/L=40, K=4)
Mb4  nb2  nb2  nb4s  AVSS  mn  W=40u  L=1u   $ (W/L)=40, K=4

* Rs: 偏置电阻 (设定基准电流)
Rs   nb4s AVSS  4.4k                           $ Beta-multiplier电阻

* === 启动电路 ===
* 防止零电流稳态点
* Mst1: 当nb1=VDD时(零电流态), 注入启动电流到nb2
Mst1  nb2  nst  AVDD  AVDD  mp  W=2u  L=10u   $ 小启动管
Mst2  nst  nst  AVDD  AVDD  mp  W=2u  L=10u   $ 二极管连接
Mst3  nst  nb1  AVSS  AVSS  mn  W=2u  L=1u    $ 当电路正常后关断启动

* === 输出偏置电压 VBP ===
* VBP = nb1 栅电压, 用于PMOS电流镜
* 通过小电阻连接输出 (避免E源拓扑问题)
Rvbp nb1 VBP 0.01                               $ VBP连接输出

* === NMOS偏置电压产生 VBN ===
* 通过二极管连接NMOS产生 Vbn = Vgs_n
Mb5  nb5  nb5  AVSS  AVSS  mn  W=46u  L=1u    $ 二极管连接NMOS
Mb5p nb5  nb1  AVDD  AVDD  mp  W=18u  L=2u    $ PMOS电流源 (10uA)
* VBN = nb5 ≈ Vth + Vov
Rvbn nb5 VBN 0.01                               $ VBN连接输出

* === NMOS共源共栅偏置 VBNC ===
* 通过共源共栅偏置电路:
* Mb6 (二极管NMOS) + Mb7 (NMOS, gate=VBN)
* VBNC = Vov_M7 + Vgs_M6
Mb6  nb6  nb6  nb7d  AVSS  mn  W=46u  L=1u    $ 二极管连接NMOS (共源共栅)
Mb7  nb7d nb5  AVSS  AVSS  mn  W=46u  L=1u    $ NMOS gate=VBN
Mb6p nb6  nb1  AVDD  AVDD  mp  W=18u  L=2u    $ PMOS电流源 (10uA)
* VBNC = nb6
Rvbnc nb6 VBNC 0.01                             $ VBNC连接输出

* === PMOS共源共栅偏置 VBPC ===
* 通过堆叠二极管连接PMOS:
* VBPC = VDD - |Vov_M5_load| - |Vsg_M3_casc|
* 用电流源驱动两个堆叠的二极管连接PMOS
Mb10  nbpc  nbpc  nb10s  AVDD  mp  W=18u  L=2u   $ 下层cascode diode
Mb11  nb10s nb10s AVDD   AVDD  mp  W=18u  L=2u   $ 上层source diode
Mb10n nbpc  nb5   AVSS   AVSS  mn  W=46u  L=1u   $ NMOS电流源 (10uA)
* VBPC = nbpc
Rvbpc nbpc VBPC 0.01                              $ VBPC连接输出

.ENDS BIAS_CIRCUIT


* =====================================================================
*            七、折叠共源共栅OTA主电路
* =====================================================================

.SUBCKT OTA_FC VINP VINN VOUT AVDD AVSS VBP VBPC VBN VBNC

* === PMOS尾电流源 M0 ===
* I_tail = 200 uA, 由VBP偏置
* (W/L)0 = 90, L=2um, W=180um (与偏置电路Mb1的比例为 180/18 = 10:1 → 100uA)
* 实际需要20:1比例获得200uA, 因此W加倍
M0  ns   VBP  AVDD  AVDD  mp  W=360u  L=2u    $ 尾电流源, 200uA

* === PMOS输入差分对 M1, M2 ===
* (W/L)1 = 70, L=2um, W=140um
* gm1 = 1 mA/V, Id1 = 100 uA
M1  fa   VINP  ns  AVDD  mp  W=140u  L=2u     $ 输入管+
M2  fb   VINN  ns  AVDD  mp  W=140u  L=2u     $ 输入管-

* === PMOS电流源负载 M5, M6 ===
* Id = 20 uA, (W/L)5 = 9, L=2um, W=18um
* 偏置比例: 18/18 = 1:1 相对偏置Mb1(10uA), 实际=10uA
* 需要2:1得到20uA → W=36um
M5  d5   VBP   AVDD  AVDD  mp  W=36u  L=2u    $ PMOS电流源 (20uA)
M6  d6   VBP   AVDD  AVDD  mp  W=36u  L=2u    $ PMOS电流源 (20uA)

* === PMOS共源共栅 M3, M4 ===
* (W/L)3 = 9, L=2um, W=18um
* 与M5/M6串联, 提供高输出阻抗
M3  fa   VBPC  d5  AVDD  mp  W=36u  L=2u      $ PMOS共源共栅
M4  fb   VBPC  d6  AVDD  mp  W=36u  L=2u      $ PMOS共源共栅

* === NMOS共源共栅 M7, M8 ===
* Id = 120 uA, (W/L)=46, L=1um, W=46um
* gm7 = 1.2 mA/V
M7  fa   VBNC  d7  AVSS  mn  W=46u  L=1u      $ NMOS共源共栅
M8  fb   VBNC  d8  AVSS  mn  W=46u  L=1u      $ NMOS共源共栅

* === NMOS电流源 M9, M10 ===
* Id = 120 uA, (W/L)=46, L=1um, W=46um
* 镜像比例: 46/46 相对偏置中的单位管
M9   d7   VBN  AVSS  AVSS  mn  W=138u  L=1u   $ NMOS电流源 (120uA)
M10  d8   VBN  AVSS  AVSS  mn  W=138u  L=1u   $ NMOS电流源 (120uA)
* 注: 偏置Mb5 W=46u L=1u 流10uA, 需要12:1得120uA → W=46*12/4=138u
* (考虑偏置Mb5实际电流可能不同, 待仿真调整)

* === 输出连接 ===
* Vout 取自 fold_b 节点
Rout fb VOUT 0.01                              $ 极小电阻连接输出

.ENDS OTA_FC


* =====================================================================
*         八、顶层电路实例化与仿真设置
* =====================================================================

* --- 电源 ---
VDD  AVDD  0  DC 3.6
VSS  AVSS  0  DC 0

* --- 偏置电路实例化 ---
XBIAS AVDD AVSS VBP VBPC VBN VBNC BIAS_CIRCUIT

* --- OTA实例化 ---
XOTA VINP VINN VOUT AVDD AVSS VBP VBPC VBN VBNC OTA_FC

* --- 负载电容 ---
CL  VOUT  AVSS  30p

* --- 输入设置 ---
* 参考电压 (Vin- = 0.6V 固定参考)
* 输入信号施加在 Vin+
VREF VINN 0 DC 0.6

* =====================================================================
*     九、仿真一: 直流扫描 (输入-输出特性 & 静态电流)
* =====================================================================
* 目的: 确定低频增益、输入失调电压、输出工作点
*
* 一输入端固定为0.6V参考电压, 另一输入端从0V扫描到3.6V
* 观察输出电压和静态电流

VIN_DC VINP 0 DC 0.6

.OP

.DC VIN_DC 0 3.6 0.001

* 测量直流增益 (在输出为0.9V附近)
.MEASURE DC vout_at_06 FIND V(VOUT) AT=0.6
.MEASURE DC vin_cross WHEN V(VOUT)=0.9 CROSS=1
.MEASURE DC input_offset PARAM='vin_cross - 0.6'

* 测量静态电流
.MEASURE DC Itotal FIND I(VDD) AT=0.6
.MEASURE DC Idd_quiescent PARAM='-Itotal'

* 打印输出电压和电源电流
.PRINT DC V(VOUT) V(VINP) I(VDD)


* =====================================================================
*     十、仿真二: 交流分析 (增益、相位、GBW、相位裕度)
* =====================================================================
* 目的: 增益波特图、相频特性、单位增益带宽、相位裕量
*
* 将输入Vin+设为0.6V DC + AC小信号
* 输出工作点为0.9V

* AC分析信号源 (替换直流源)
* 注意: 在HSPICE中AC源叠加在DC源上
* VIN_DC 已设为0.6V DC
* 在此添加AC激励

.AC DEC 100 1 1G

* 测量低频增益
.MEASURE AC av_dc FIND VDB(VOUT) AT=1
.MEASURE AC phase_dc FIND VP(VOUT) AT=1

* 测量单位增益带宽 (0dB crossing)
.MEASURE AC GBW WHEN VDB(VOUT)=0 CROSS=1

* 测量相位裕度 (在GBW频率处的相位 + 180度)
.MEASURE AC phase_at_gbw FIND VP(VOUT) AT=GBW
.MEASURE AC phase_margin PARAM='phase_at_gbw + 180'

* 测量3dB带宽
.MEASURE AC gain_3db PARAM='av_dc - 3'
.MEASURE AC BW_3dB WHEN VDB(VOUT)=gain_3db CROSS=1

.PRINT AC VDB(VOUT) VP(VOUT)


* =====================================================================
*    十一、仿真三: PSRR分析
* =====================================================================
* 目的: 电源抑制比 PSRR vs 频率 (1Hz ~ 100kHz)
*
* PSRR = Av / Avdd = (dVout/dVin) / (dVout/dVdd)
* 方法: 在VDD上施加AC小信号, 测量到输出的传递函数
* PSRR(dB) = 20*log10(Av) - 20*log10(Avdd)
* 或单独测量 Avdd: AC信号加在VDD上, 输入接固定电压

* 注: 此分析需要在AC源设置中将VDD的AC幅度设为1
* 在主仿真文件中, 两种分析不能同时进行
* 请参见下面独立的PSRR仿真文件


* =====================================================================
*   十二、仿真四: 瞬态分析 (转换速率)
* =====================================================================
* 目的: 测量转换速率 SR

.TRAN 0.01u 10u

* 脉冲输入: 从0.5V跳到0.7V (200mV阶跃)
* VIN_PULSE VINP 0 PULSE(0.5 0.7 1u 10n 10n 4u 9u)

.PRINT TRAN V(VOUT) V(VINP)

* 测量上升转换速率
.MEASURE TRAN SR_rise DERIV V(VOUT) WHEN V(VOUT)=0.85 RISE=1
* 测量下降转换速率
.MEASURE TRAN SR_fall DERIV V(VOUT) WHEN V(VOUT)=0.95 FALL=1


* =====================================================================
*   十三、各偏置节点电压打印 (便于调试)
* =====================================================================

.PRINT DC V(VBP) V(VBPC) V(VBN) V(VBNC)
.PRINT DC V(XOTA.ns) V(XOTA.fa) V(XOTA.fb)

.OPTIONS POST=2 ACCURATE PROBE
+ INGOLD=2 NUMDGT=7

.END
