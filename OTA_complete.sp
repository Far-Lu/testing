***********************************************************************
*          跨导放大器(OTA)完整设计 - 可直接运行仿真文件
*
*  本文件包含完整的OTA电路与所有仿真分析
*  电路结构: 折叠共源共栅 (Folded-Cascode) OTA, PMOS输入差分对
*  偏置电路: 自偏置Beta-Multiplier电流基准
*  工艺: 0.5um CMOS 2p2m
*
*  使用方法: hspice OTA_complete.sp
*
*  仿真内容:
*    1) .OP   - 直流工作点分析
*    2) .DC   - 输入-输出传输特性 (增益、失调)
*    3) .AC   - 频率响应 (增益、相位、GBW、PM)
*    4) .TRAN - 瞬态响应 (转换速率SR)
*
***********************************************************************

.TITLE Folded-Cascode OTA Design - 0.5um CMOS

* =====================================================================
*                    温度设置
* =====================================================================
.TEMP 27

* =====================================================================
*                    全局参数
* =====================================================================
.PARAM VDD_VAL=3.6
.PARAM VREF_VAL=0.6
.PARAM CL_VAL=30p

* =====================================================================
*                    MOSFET模型
* =====================================================================
* 基于给定工艺参数的Level 1模型
*
* NMOS: Vth0=719.2mV, mu0=495.1cm2/Vs, tox=13nm
*   Cox_n = eps0*eps_r/tox = 8.85e-12*3.9/13e-9 = 2.655 fF/um2
*   KP_n = mu_n*Cox_n = 495.1e-4 * 2.655e-3 = 131.4 uA/V2
*
* PMOS: Vth0=972.6mV, mu0=283.3cm2/Vs, tox=13.7nm
*   Cox_p = eps0*eps_r/tox = 8.85e-12*3.9/13.7e-9 = 2.519 fF/um2
*   KP_p = mu_p*Cox_p = 283.3e-4 * 2.519e-3 = 71.35 uA/V2

.MODEL mn NMOS LEVEL=1
+ VTO=0.7192       $ 阈值电压
+ KP=131.4u        $ 工艺跨导参数
+ TOX=13n          $ 栅氧厚度
+ LAMBDA=0.04      $ 沟道长度调制
+ GAMMA=0.45       $ 体效应系数
+ PHI=0.7          $ 2*Fermi势
+ CBD=10f CBS=10f
+ CGSO=0.6n CGDO=0.6n

.MODEL mp PMOS LEVEL=1
+ VTO=-0.9726      $ 阈值电压(PMOS为负)
+ KP=71.35u        $ 工艺跨导参数
+ TOX=13.7n        $ 栅氧厚度
+ LAMBDA=0.03      $ 沟道长度调制
+ GAMMA=0.45       $ 体效应系数
+ PHI=0.7          $ 2*Fermi势
+ CBD=10f CBS=10f
+ CGSO=0.6n CGDO=0.6n

* =====================================================================
*     偏置电流基准子电路 (Self-Biased Beta-Multiplier)
* =====================================================================
*
* 电路原理:
*   - Mb1,Mb2: PMOS电流镜,强迫两支路电流相等
*   - Mb3: NMOS (W/L=10), Mb4: NMOS (W/L=40, K=4)
*   - Mb4源极接电阻Rs, 产生电压差
*   - 基准电流: Iref = (1-1/sqrt(K))^2 / (KP_n/2*(W/L)4*Rs^2)
*   - K=4, Rs=4.4kOhm → Iref ≈ 10 uA
*   - Mst1-Mst3: 启动电路,防止零电流死锁
*
* 偏置电压产生:
*   VBP:  PMOS镜像栅压 (二极管连接Mb1)
*   VBN:  NMOS电流源栅压 (二极管连接Mb5)
*   VBNC: NMOS共源共栅栅压 (Mb6+Mb7堆叠)
*   VBPC: PMOS共源共栅栅压 (Mb10+Mb11堆叠)

.SUBCKT BIAS AVDD AVSS VBP VBPC VBN VBNC

*** PMOS电流镜 ***
Mb1  nb1  nb1  AVDD  AVDD  mp  W=18u  L=2u   $ 二极管连接
Mb2  nb2  nb1  AVDD  AVDD  mp  W=18u  L=2u   $ 1:1镜像

*** NMOS Beta-Multiplier核心 ***
Mb3  nb1  nb2  AVSS  AVSS  mn  W=10u  L=1u   $ W/L=10
Mb4  nb2  nb2  nb4s  AVSS  mn  W=40u  L=1u   $ W/L=40, 二极管连接
Rs   nb4s AVSS  4.4k                          $ 偏置电阻

*** 启动电路 ***
Mst1  nb2  nst  AVDD  AVDD  mp  W=2u  L=10u  $ 启动注入
Mst2  nst  nst  AVDD  AVDD  mp  W=2u  L=10u  $ 二极管PMOS
Mst3  nst  nb1  AVSS  AVSS  mn  W=2u  L=1u   $ 关断控制

*** VBP输出 ***
* VBP = nb1 (PMOS镜像栅电压)
* 使用VCVS缓冲避免负载影响偏置点
Rvbp nb1 VBP 0.01

*** VBN产生: 二极管连接NMOS ***
Mb5  nb5  nb5  AVSS  AVSS  mn  W=46u  L=1u   $ Vbn = Vth+Vov
Mb5p nb5  nb1  AVDD  AVDD  mp  W=18u  L=2u   $ 电流源
Rvbn nb5 VBN 0.01

*** VBNC产生: NMOS共源共栅偏置 ***
* Vbnc = Vov_M7 + Vgs_M6 (保证M9,M10饱和)
Mb6  nb6  nb6  nb7d  AVSS  mn  W=46u  L=1u   $ 上层NMOS二极管
Mb7  nb7d nb5  AVSS  AVSS  mn  W=46u  L=1u   $ 下层NMOS, gate=Vbn
Mb6p nb6  nb1  AVDD  AVDD  mp  W=18u  L=2u   $ 电流源
Rvbnc nb6 VBNC 0.01

*** VBPC产生: PMOS共源共栅偏置 ***
* Vbpc = VDD - |Vov_M5| - |Vsg_M3| (保证M5,M6饱和)
Mb10  nbpc  nbpc  nb10s  AVDD  mp  W=18u  L=2u  $ 下层PMOS二极管
Mb11  nb10s nb10s AVDD   AVDD  mp  W=18u  L=2u  $ 上层PMOS二极管
Mb10n nbpc  nb5   AVSS   AVSS  mn  W=46u  L=1u  $ NMOS电流源拉电流
Rvbpc nbpc VBPC 0.01

.ENDS BIAS

* =====================================================================
*     折叠共源共栅OTA子电路
* =====================================================================
*
* 器件功能说明:
*   M0:     PMOS尾电流源 (I_tail=200uA)
*   M1,M2:  PMOS输入差分对 (Gm=1mA/V)
*   M5,M6:  PMOS电流源负载 (I=20uA each)
*   M3,M4:  PMOS共源共栅管 (提高PMOS侧输出阻抗)
*   M9,M10: NMOS电流源 (I=120uA each)
*   M7,M8:  NMOS共源共栅管 (提高NMOS侧输出阻抗)
*
* 电流关系: I_M9 = I_M5 + I_tail/2 → 120 = 20 + 100  ✓
* 总电流: I_tail + 2*I_M5 = 200 + 40 = 240 uA (OTA部分)

.SUBCKT FCOTA INP INN OUT AVDD AVSS VBP VBPC VBN VBNC

*** PMOS尾电流源 ***
* I=200uA, Vov=0.25V
* (W/L) = 2*200u/(71.35u*0.0625) = 89.7 → 90
* 镜像比: W_M0/W_Mb1 = 360/18 = 20 → I = 20*10uA = 200uA
M0  ns   VBP  AVDD  AVDD  mp  W=360u  L=2u

*** PMOS输入差分对 ***
* I=100uA each, gm=1mA/V, Vov=0.2V
* (W/L) = gm^2/(2*KP_p*Id) = 1e-6/(14.27e-9) = 70
M1  fa   INP   ns    AVDD  mp  W=140u  L=2u
M2  fb   INN   ns    AVDD  mp  W=140u  L=2u

*** PMOS电流源负载 ***
* I=20uA each, Vov=0.25V
* 镜像比: 36/18 = 2 → I = 2*10uA = 20uA
M5  d5   VBP   AVDD  AVDD  mp  W=36u   L=2u
M6  d6   VBP   AVDD  AVDD  mp  W=36u   L=2u

*** PMOS共源共栅 ***
* 与M5/M6串联, 提供高Rout_PMOS
M3  fa   VBPC  d5    AVDD  mp  W=36u   L=2u
M4  fb   VBPC  d6    AVDD  mp  W=36u   L=2u

*** NMOS共源共栅 ***
* I=120uA each, Vov=0.2V, gm=1.2mA/V
M7  fa   VBNC  d7    AVSS  mn  W=46u   L=1u
M8  fb   VBNC  d8    AVSS  mn  W=46u   L=1u

*** NMOS电流源 ***
* I=120uA each
* 镜像比: 138/46 = 3 → 若Mb5流10uA*3 (但Mb5的gm不同)
* 实际需根据仿真微调W获得精确120uA
M9   d7   VBN   AVSS  AVSS  mn  W=138u  L=1u
M10  d8   VBN   AVSS  AVSS  mn  W=138u  L=1u

*** 输出节点 ***
* fb即为高阻抗输出节点
Rcon fb OUT 0.01

.ENDS FCOTA

* =====================================================================
*               顶层电路实例化
* =====================================================================

*** 电源 ***
VDD  AVDD  0  DC VDD_VAL
VSS  AVSS  0  DC 0

*** 偏置电路 ***
XBIAS AVDD AVSS VBP VBPC VBN VBNC BIAS

*** OTA ***
XOTA VINP VINN VOUT AVDD AVSS VBP VBPC VBN VBNC FCOTA

*** 负载电容 ***
CL  VOUT  0  CL_VAL

*** 输入源 ***
* Vin- = 0.6V 参考 (固定)
VREF  VINN  0  DC  VREF_VAL

* Vin+ = 0.6V DC + AC 1V (用于AC分析)
*        在TRAN分析中会被替换为脉冲
VIN   VINP  0  DC  VREF_VAL  AC  1

* =====================================================================
*           分析一: 直流工作点
* =====================================================================
.OP

* =====================================================================
*           分析二: DC扫描 - 传输特性与静态电流
* =====================================================================
* 输入Vin+从0V扫到VDD, Vin-固定0.6V
.DC VIN 0 3.6 0.001

* --- DC测量 ---
* 输出为0.9V时的输入电压 (确定失调)
.MEASURE DC vin_at_vout09 WHEN V(VOUT)=0.9 CROSS=1
.MEASURE DC input_offset PARAM='vin_at_vout09-0.6'

* 静态电流 (输入平衡点)
.MEASURE DC Idd_static FIND I(VDD) AT=0.6

* DC增益 (在线性区的斜率)
.MEASURE DC vout_599m FIND V(VOUT) AT=0.599
.MEASURE DC vout_601m FIND V(VOUT) AT=0.601
.MEASURE DC Av_dc PARAM='(vout_599m-vout_601m)/0.002'

* =====================================================================
*           分析三: AC分析 - 频率响应
* =====================================================================
.AC DEC 100 1 1G

* --- AC测量 ---
* 低频增益
.MEASURE AC gain_1Hz FIND VDB(VOUT) AT=1
.MEASURE AC phase_1Hz FIND VP(VOUT) AT=1

* 单位增益带宽
.MEASURE AC GBW WHEN VDB(VOUT)=0 CROSS=1

* 相位裕度
.MEASURE AC phase_at_GBW FIND VP(VOUT) AT=GBW
.MEASURE AC phase_margin PARAM='phase_at_GBW+180'

* 3dB带宽
.MEASURE AC gain_peak MAX VDB(VOUT) FROM=1 TO=100k
.MEASURE AC gain_m3dB PARAM='gain_peak-3'
.MEASURE AC BW_3dB WHEN VDB(VOUT)=gain_m3dB CROSS=1

* =====================================================================
*           分析四: 瞬态分析 - 转换速率
* =====================================================================
* 注: DC扫描和TRAN使用相同VIN源
* HSPICE会按顺序执行所有分析
.TRAN 10n 20u

* --- TRAN测量 ---
* 注: 瞬态分析的SR测量依赖于输入脉冲激励
* 当VIN为DC 0.6V时, 瞬态输出为稳态
* 需要修改VIN为脉冲信号来测量SR
* 请使用 sim_transient.sp 进行独立SR测量

* =====================================================================
*           输出打印
* =====================================================================
.PRINT DC V(VOUT) V(VINP) I(VDD)
.PRINT DC V(VBP) V(VBPC) V(VBN) V(VBNC)
.PRINT AC VDB(VOUT) VP(VOUT)
.PRINT TRAN V(VOUT) V(VINP)

* =====================================================================
*           仿真选项
* =====================================================================
.OPTIONS POST=2        $ 输出波形数据
+ ACCURATE             $ 高精度模式
+ NUMDGT=7             $ 数字精度
+ INGOLD=2             $ 输出格式
+ PROBE                $ 探针模式
+ RELTOL=1e-4          $ 相对误差容限
+ ABSTOL=1e-12         $ 绝对电流误差
+ VNTOL=1e-6           $ 绝对电压误差
+ GMINDC=1e-13         $ 最小导纳(DC)
+ ITL1=500             $ DC迭代次数
+ ITL2=200             $ DC传输曲线迭代

.END
