***********************************************************************
* 跨导放大器(OTA) - 瞬态分析 & 转换速率
* 仿真四: 阶跃响应与转换速率 SR
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

M0  ns   VBP  AVDD  AVDD  mp  W=360u  L=2u
M1  fa   VINP  ns  AVDD  mp  W=140u  L=2u
M2  fb   VINN  ns  AVDD  mp  W=140u  L=2u
M5  d5   VBP  AVDD  AVDD  mp  W=36u  L=2u
M6  d6   VBP  AVDD  AVDD  mp  W=36u  L=2u
M3  fa   VBPC  d5  AVDD  mp  W=36u  L=2u
M4  fb   VBPC  d6  AVDD  mp  W=36u  L=2u
M7  fa   VBNC  d7  AVSS  mn  W=46u  L=1u
M8  fb   VBNC  d8  AVSS  mn  W=46u  L=1u
M9   d7   VBN  AVSS  AVSS  mn  W=138u  L=1u
M10  d8   VBN  AVSS  AVSS  mn  W=138u  L=1u
Rout fb VOUT 0.01

.ENDS OTA_FC

* =====================================================================
*                 瞬态测试电路
* =====================================================================

VDD  AVDD  0  DC 3.6
VSS  AVSS  0  DC 0

XBIAS AVDD AVSS VBP VBPC VBN VBNC BIAS_CIRCUIT
XOTA VINP VINN VOUT AVDD AVSS VBP VBPC VBN VBNC OTA_FC

CL  VOUT  0  30p

*--- 输入: Vin-固定0.6V参考 ---
VREF VINN 0 DC 0.6

*--- Vin+: 脉冲信号 (大信号阶跃测试SR) ---
* 从0.5V跳到0.7V (200mV阶跃), 上升时间10ns
* 初始0.5V, 脉冲到0.7V
VIN  VINP 0 PULSE(0.5 0.7 1u 10n 10n 4u 9u)

* =====================================================================
*                 瞬态分析
* =====================================================================

* 仿真时间: 20us, 步长10ns
.TRAN 10n 20u UIC

* 测量上升转换速率 (输出上升段)
* SR_rise = dVout/dt 在输出10%~90%范围
.MEASURE TRAN vout_low FIND V(VOUT) AT=0.5u
.MEASURE TRAN vout_10 PARAM='vout_low + 0.1*(3.6-vout_low)'
.MEASURE TRAN vout_90 PARAM='vout_low + 0.9*(3.6-vout_low)'

* 简单SR测量: 输出斜率
.MEASURE TRAN t_rise_10 WHEN V(VOUT)=0.8 RISE=1
.MEASURE TRAN t_rise_90 WHEN V(VOUT)=1.0 RISE=1
.MEASURE TRAN SR_rise PARAM='(1.0-0.8)/(t_rise_90-t_rise_10)'

* 测量下降转换速率
.MEASURE TRAN t_fall_90 WHEN V(VOUT)=1.0 FALL=1
.MEASURE TRAN t_fall_10 WHEN V(VOUT)=0.8 FALL=1
.MEASURE TRAN SR_fall PARAM='(1.0-0.8)/(t_fall_10-t_fall_90)'

* 打印输出波形
.PRINT TRAN V(VOUT) V(VINP) V(VINN) I(VDD)

.OPTIONS POST=2 ACCURATE NUMDGT=7
+ RELTOL=1e-4 ABSTOL=1e-12 VNTOL=1e-6
.END
