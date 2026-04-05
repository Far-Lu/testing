***********************************************************************
* 跨导放大器(OTA) - 跨导特性仿真
* 仿真五: 输入电压-输出电流传输特性 (跨导Gm测量)
* 工艺: 0.5um CMOS 2p2m
* 条件: VDD=3.6V, Temp=27C, TT工艺角
***********************************************************************
*
* 跨导 Gm = dIout / dVin
* 方法: 开环配置, 扫描输入电压, 测量输出电流
*       输出接固定电压源(0.9V)代替电容负载
*
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
*            折叠共源共栅OTA (输出接电压源版本)
* =====================================================================

.SUBCKT OTA_FC_GM VINP VINN VOUT AVDD AVSS VBP VBPC VBN VBNC

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

.ENDS OTA_FC_GM

* =====================================================================
*                 跨导测试电路
* =====================================================================

VDD  AVDD  0  DC 3.6
VSS  AVSS  0  DC 0

XBIAS AVDD AVSS VBP VBPC VBN VBNC BIAS_CIRCUIT
XOTA VINP VINN VOUT AVDD AVSS VBP VBPC VBN VBNC OTA_FC_GM

*--- 输出端接固定电压0.9V (测量输出电流) ---
VOUT_FIX VOUT 0 DC 0.9

*--- 输入: Vin-固定0.6V, Vin+扫描 ---
VREF VINN 0 DC 0.6
VIN  VINP 0 DC 0.6

* =====================================================================
*                 DC扫描分析 - 跨导测量
* =====================================================================

.DC VIN 0.4 0.8 0.001

* 测量输出电流 (流过VOUT_FIX的电流)
* 跨导 Gm = dIout/dVin
.PRINT DC I(VOUT_FIX) V(VINP) V(VOUT)

* 在Vin=0.6V处测量跨导
* Gm ≈ ΔIout/ΔVin
.MEASURE DC Iout_599 FIND I(VOUT_FIX) AT=0.599
.MEASURE DC Iout_601 FIND I(VOUT_FIX) AT=0.601
.MEASURE DC Gm_at_06 PARAM='(Iout_601-Iout_599)/0.002'

* 打印跨导值
.PRINT DC I(VOUT_FIX)

.OPTIONS POST=2 ACCURATE NUMDGT=7
.END
