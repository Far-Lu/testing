***********************************************************************
* 跨导放大器(OTA) - 多工艺角多温度多电压仿真
* 仿真六: PVT Corner仿真 (全慢/全典型/全快 × 多温度 × 多电压)
* 工艺: 0.5um CMOS 2p2m
***********************************************************************
*
* 仿真条件矩阵:
*              VDD=2.5V    VDD=3.6V    VDD=5.5V
* SS,-40C       ✓           ✓           ✓
* TT, 27C       ✓           ✓           ✓
* FF,125C       ✓           ✓           ✓
*
* 注: Level 1模型不支持工艺角变化,
*     这里通过修改Vth和KP来模拟SS/FF角
*     SS: Vth增大10%, mu降低10%
*     FF: Vth减小10%, mu增大10%
*
***********************************************************************

* =====================================================================
*  参数化模型 (支持工艺角切换)
* =====================================================================

* 工艺角参数 (通过.ALTER切换)
.PARAM corner = 0    $ 0=TT, 1=SS, -1=FF
.PARAM vdd_val = 3.6
.PARAM temp_val = 27

* TT模型 (默认)
.MODEL mn NMOS LEVEL=1
+ VTO=0.7192 KP=131.4u TOX=13n LAMBDA=0.04
+ GAMMA=0.45 PHI=0.7
+ CBD=10f CBS=10f CGSO=0.6n CGDO=0.6n

.MODEL mp PMOS LEVEL=1
+ VTO=-0.9726 KP=71.35u TOX=13.7n LAMBDA=0.03
+ GAMMA=0.45 PHI=0.7
+ CBD=10f CBS=10f CGSO=0.6n CGDO=0.6n

* =====================================================================
*               偏置电路
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
*            OTA主电路
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
*            顶层电路
* =====================================================================

VDD  AVDD  0  DC vdd_val
VSS  AVSS  0  DC 0

XBIAS AVDD AVSS VBP VBPC VBN VBNC BIAS_CIRCUIT
XOTA VINP VINN VOUT AVDD AVSS VBP VBPC VBN VBNC OTA_FC

CL  VOUT  0  30p

VREF VINN 0 DC 0.6
VIN  VINP 0 DC 0.6 AC 1

.TEMP temp_val

* =====================================================================
*            综合分析
* =====================================================================

.OP

* DC扫描
.DC VIN 0 'vdd_val' 0.001

* AC分析
.AC DEC 100 1 1G

* 测量
.MEASURE DC vin_cross WHEN V(VOUT)=0.9 CROSS=1
.MEASURE DC offset PARAM='vin_cross-0.6'
.MEASURE DC Idd FIND I(VDD) AT=0.6

.MEASURE AC gain_dc FIND VDB(VOUT) AT=1
.MEASURE AC GBW WHEN VDB(VOUT)=0 CROSS=1
.MEASURE AC phase_gbw FIND VP(VOUT) AT=GBW
.MEASURE AC PM PARAM='phase_gbw+180'

.PRINT DC V(VOUT) I(VDD)
.PRINT AC VDB(VOUT) VP(VOUT)

.OPTIONS POST=2 ACCURATE NUMDGT=7

* =====================================================================
*  工艺角 1: TT, 27C, VDD=3.6V (基准, 已在上面运行)
* =====================================================================

* =====================================================================
*  工艺角 2: TT, 27C, VDD=2.5V
* =====================================================================
.ALTER
.PARAM vdd_val = 2.5
.TEMP 27

* =====================================================================
*  工艺角 3: TT, 27C, VDD=5.5V
* =====================================================================
.ALTER
.PARAM vdd_val = 5.5
.TEMP 27

* =====================================================================
*  工艺角 4: SS, -40C, VDD=2.5V
* =====================================================================
.ALTER
.PARAM vdd_val = 2.5
.TEMP -40
* SS模型: Vth增大10%, KP减小10%
.MODEL mn NMOS LEVEL=1
+ VTO=0.7911 KP=118.3u TOX=13n LAMBDA=0.04
+ GAMMA=0.45 PHI=0.7
+ CBD=10f CBS=10f CGSO=0.6n CGDO=0.6n
.MODEL mp PMOS LEVEL=1
+ VTO=-1.0699 KP=64.22u TOX=13.7n LAMBDA=0.03
+ GAMMA=0.45 PHI=0.7
+ CBD=10f CBS=10f CGSO=0.6n CGDO=0.6n

* =====================================================================
*  工艺角 5: SS, -40C, VDD=3.6V
* =====================================================================
.ALTER
.PARAM vdd_val = 3.6
.TEMP -40
.MODEL mn NMOS LEVEL=1
+ VTO=0.7911 KP=118.3u TOX=13n LAMBDA=0.04
+ GAMMA=0.45 PHI=0.7 CBD=10f CBS=10f CGSO=0.6n CGDO=0.6n
.MODEL mp PMOS LEVEL=1
+ VTO=-1.0699 KP=64.22u TOX=13.7n LAMBDA=0.03
+ GAMMA=0.45 PHI=0.7 CBD=10f CBS=10f CGSO=0.6n CGDO=0.6n

* =====================================================================
*  工艺角 6: SS, -40C, VDD=5.5V
* =====================================================================
.ALTER
.PARAM vdd_val = 5.5
.TEMP -40
.MODEL mn NMOS LEVEL=1
+ VTO=0.7911 KP=118.3u TOX=13n LAMBDA=0.04
+ GAMMA=0.45 PHI=0.7 CBD=10f CBS=10f CGSO=0.6n CGDO=0.6n
.MODEL mp PMOS LEVEL=1
+ VTO=-1.0699 KP=64.22u TOX=13.7n LAMBDA=0.03
+ GAMMA=0.45 PHI=0.7 CBD=10f CBS=10f CGSO=0.6n CGDO=0.6n

* =====================================================================
*  工艺角 7: FF, 125C, VDD=2.5V
* =====================================================================
.ALTER
.PARAM vdd_val = 2.5
.TEMP 125
* FF模型: Vth减小10%, KP增大10%
.MODEL mn NMOS LEVEL=1
+ VTO=0.6473 KP=144.5u TOX=13n LAMBDA=0.04
+ GAMMA=0.45 PHI=0.7 CBD=10f CBS=10f CGSO=0.6n CGDO=0.6n
.MODEL mp PMOS LEVEL=1
+ VTO=-0.8753 KP=78.49u TOX=13.7n LAMBDA=0.03
+ GAMMA=0.45 PHI=0.7 CBD=10f CBS=10f CGSO=0.6n CGDO=0.6n

* =====================================================================
*  工艺角 8: FF, 125C, VDD=3.6V
* =====================================================================
.ALTER
.PARAM vdd_val = 3.6
.TEMP 125
.MODEL mn NMOS LEVEL=1
+ VTO=0.6473 KP=144.5u TOX=13n LAMBDA=0.04
+ GAMMA=0.45 PHI=0.7 CBD=10f CBS=10f CGSO=0.6n CGDO=0.6n
.MODEL mp PMOS LEVEL=1
+ VTO=-0.8753 KP=78.49u TOX=13.7n LAMBDA=0.03
+ GAMMA=0.45 PHI=0.7 CBD=10f CBS=10f CGSO=0.6n CGDO=0.6n

* =====================================================================
*  工艺角 9: FF, 125C, VDD=5.5V
* =====================================================================
.ALTER
.PARAM vdd_val = 5.5
.TEMP 125
.MODEL mn NMOS LEVEL=1
+ VTO=0.6473 KP=144.5u TOX=13n LAMBDA=0.04
+ GAMMA=0.45 PHI=0.7 CBD=10f CBS=10f CGSO=0.6n CGDO=0.6n
.MODEL mp PMOS LEVEL=1
+ VTO=-0.8753 KP=78.49u TOX=13.7n LAMBDA=0.03
+ GAMMA=0.45 PHI=0.7 CBD=10f CBS=10f CGSO=0.6n CGDO=0.6n

.END
