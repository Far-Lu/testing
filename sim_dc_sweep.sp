***********************************************************************
* 跨导放大器(OTA) - 直流扫描仿真
* 仿真一: 输入-输出传输特性 & 静态电流 & 跨导特性
* 工艺: 0.5um CMOS 2p2m
* 条件: VDD=3.6V, Temp=27C, TT工艺角
***********************************************************************

.TEMP 27

* =====================================================================
*                    MOSFET模型定义
* =====================================================================

.MODEL mn NMOS LEVEL=1
+ VTO=0.7192 KP=131.4u TOX=13n LAMBDA=0.04
+ GAMMA=0.45 PHI=0.7
+ CBD=10f CBS=10f CGSO=0.6n CGDO=0.6n

.MODEL mp PMOS LEVEL=1
+ VTO=-0.9726 KP=71.35u TOX=13.7n LAMBDA=0.03
+ GAMMA=0.45 PHI=0.7
+ CBD=10f CBS=10f CGSO=0.6n CGDO=0.6n

* =====================================================================
*               偏置电流基准电路
* =====================================================================

.SUBCKT BIAS_CIRCUIT AVDD AVSS VBP VBPC VBN VBNC

Mb1  nb1  nb1  AVDD  AVDD  mp  W=18u  L=2u
Mb2  nb2  nb1  AVDD  AVDD  mp  W=18u  L=2u
Mb3  nb1  nb2  AVSS  AVSS  mn  W=10u  L=1u
Mb4  nb2  nb2  nb4s  AVSS  mn  W=40u  L=1u
Rs   nb4s AVSS  4.4k

Mst1  nb2  nst  AVDD  AVDD  mp  W=2u  L=10u
Mst2  nst  nst  AVDD  AVDD  mp  W=2u  L=10u
Mst3  nst  nb1  AVSS  AVSS  mn  W=2u  L=1u

Rvbp nb1 VBP 0.01

Mb5  nb5  nb5  AVSS  AVSS  mn  W=46u  L=1u
Mb5p nb5  nb1  AVDD  AVDD  mp  W=18u  L=2u
Rvbn nb5 VBN 0.01

Mb6  nb6  nb6  nb7d  AVSS  mn  W=46u  L=1u
Mb7  nb7d nb5  AVSS  AVSS  mn  W=46u  L=1u
Mb6p nb6  nb1  AVDD  AVDD  mp  W=18u  L=2u
Rvbnc nb6 VBNC 0.01

Mb10  nbpc  nbpc  nb10s  AVDD  mp  W=18u  L=2u
Mb11  nb10s nb10s AVDD   AVDD  mp  W=18u  L=2u
Mb10n nbpc  nb5   AVSS   AVSS  mn  W=46u  L=1u
Rvbpc nbpc VBPC 0.01

.ENDS BIAS_CIRCUIT

* =====================================================================
*            折叠共源共栅OTA主电路
* =====================================================================

.SUBCKT OTA_FC VINP VINN VOUT AVDD AVSS VBP VBPC VBN VBNC

*--- PMOS尾电流源 M0 (200uA) ---
M0  ns   VBP  AVDD  AVDD  mp  W=360u  L=2u

*--- PMOS输入差分对 M1, M2 ---
M1  fa   VINP  ns  AVDD  mp  W=140u  L=2u
M2  fb   VINN  ns  AVDD  mp  W=140u  L=2u

*--- PMOS电流源负载 M5, M6 (20uA each) ---
M5  d5   VBP  AVDD  AVDD  mp  W=36u  L=2u
M6  d6   VBP  AVDD  AVDD  mp  W=36u  L=2u

*--- PMOS共源共栅 M3, M4 ---
M3  fa   VBPC  d5  AVDD  mp  W=36u  L=2u
M4  fb   VBPC  d6  AVDD  mp  W=36u  L=2u

*--- NMOS共源共栅 M7, M8 ---
M7  fa   VBNC  d7  AVSS  mn  W=46u  L=1u
M8  fb   VBNC  d8  AVSS  mn  W=46u  L=1u

*--- NMOS电流源 M9, M10 (120uA each) ---
M9   d7   VBN  AVSS  AVSS  mn  W=138u  L=1u
M10  d8   VBN  AVSS  AVSS  mn  W=138u  L=1u

*--- 输出 ---
Rout fb VOUT 0.01

.ENDS OTA_FC

* =====================================================================
*                 顶层电路连接
* =====================================================================

*--- 电源 ---
VDD  AVDD  0  DC 3.6
VSS  AVSS  0  DC 0

*--- 偏置电路 ---
XBIAS AVDD AVSS VBP VBPC VBN VBNC BIAS_CIRCUIT

*--- OTA ---
XOTA VINP VINN VOUT AVDD AVSS VBP VBPC VBN VBNC OTA_FC

*--- 负载电容 30pF ---
CL  VOUT  0  30p

*--- 输入: Vin-固定0.6V参考, Vin+扫描 ---
VREF VINN 0 DC 0.6
VIN  VINP 0 DC 0.6

* =====================================================================
*                 直流扫描分析
* =====================================================================

* 分析1: 输入电压-输出电压传输特性
.DC VIN 0 3.6 0.001

* 测量输出在0.9V时对应的输入电压 (失调电压)
.MEASURE DC vin_at_09 WHEN V(VOUT)=0.9 CROSS=1
.MEASURE DC input_offset PARAM='vin_at_09 - 0.6'

* 测量静态电流 (在Vin=0.6V处)
.MEASURE DC Idd_static FIND I(VDD) AT=0.6

* 测量输出电压范围 (在输入0.6V附近的线性区)
.MEASURE DC vout_at_05 FIND V(VOUT) AT=0.5
.MEASURE DC vout_at_07 FIND V(VOUT) AT=0.7

* 计算直流增益 (Vout变化/Vin变化)
.MEASURE DC dc_gain PARAM='(vout_at_05 - vout_at_07) / (0.5 - 0.7)'

* 输出节点
.PRINT DC V(VOUT) V(VINP) I(VDD)
.PRINT DC V(VBP) V(VBPC) V(VBN) V(VBNC)

.OPTIONS POST=2 ACCURATE NUMDGT=7
.END
