***********************************************************************
* 跨导放大器(OTA) - PSRR分析
* 仿真三: 电源抑制比 PSRR vs 频率 (1Hz ~ 100kHz)
* 工艺: 0.5um CMOS 2p2m
* 条件: VDD=3.6V, Temp=27C, TT工艺角
***********************************************************************
*
* PSRR(dB) = 20*log10(Av/Avdd)
*          = 20*log10(Av) - 20*log10(Avdd)
*
* 方法: 在VDD上施加AC小信号, 两个输入端接固定DC电压
*       测量 Avdd = Vout/Vdd_ac
*       结合已知的Av, 计算PSRR
*
* 或直接: PSRR = Vdd_ac / Vout (从电源到输出的增益的倒数)
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
*                 PSRR测试电路
* =====================================================================

*--- 电源: DC + AC小信号 ---
VDD  AVDD  0  DC 3.6  AC 1    $ AC信号施加在VDD上
VSS  AVSS  0  DC 0

*--- 偏置电路 ---
XBIAS AVDD AVSS VBP VBPC VBN VBNC BIAS_CIRCUIT

*--- OTA ---
XOTA VINP VINN VOUT AVDD AVSS VBP VBPC VBN VBNC OTA_FC

*--- 负载电容 ---
CL  VOUT  0  30p

*--- 两个输入端固定DC电压 (无AC信号) ---
VREF VINN 0 DC 0.6
VIN  VINP 0 DC 0.6

* =====================================================================
*                 PSRR AC分析
* =====================================================================

.OP

* AC扫描: 1Hz ~ 100kHz
.AC DEC 100 1 100k

* 测量VDD到输出的传递函数 Avdd(dB) = VDB(VOUT)
* PSRR(dB) = Av(dB) - Avdd(dB)
* 其中Av已由AC分析获得

* 直接测量Avdd
.MEASURE AC Avdd_1Hz FIND VDB(VOUT) AT=1
.MEASURE AC Avdd_100Hz FIND VDB(VOUT) AT=100
.MEASURE AC Avdd_1kHz FIND VDB(VOUT) AT=1k
.MEASURE AC Avdd_10kHz FIND VDB(VOUT) AT=10k
.MEASURE AC Avdd_100kHz FIND VDB(VOUT) AT=100k

* PSRR = -Avdd (当Av >> Avdd时, PSRR ≈ -Avdd)
* 注: 精确的PSRR需要与开环增益结合计算
* PSRR(dB) ≈ Av(dB) - Avdd(dB)

.PRINT AC VDB(VOUT) VP(VOUT)

.OPTIONS POST=2 ACCURATE NUMDGT=7
.END
