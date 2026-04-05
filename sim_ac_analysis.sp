***********************************************************************
* 跨导放大器(OTA) - 交流小信号分析
* 仿真二: 增益波特图、相频特性、GBW、相位裕度
* 工艺: 0.5um CMOS 2p2m
* 条件: VDD=3.6V, Temp=27C, TT工艺角
* 输出工作点: 0.9V (通过调整输入偏置实现)
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
*                 顶层电路连接
* =====================================================================

VDD  AVDD  0  DC 3.6
VSS  AVSS  0  DC 0

XBIAS AVDD AVSS VBP VBPC VBN VBNC BIAS_CIRCUIT
XOTA VINP VINN VOUT AVDD AVSS VBP VBPC VBN VBNC OTA_FC

CL  VOUT  0  30p

*--- 输入设置 ---
* Vin- 固定为0.6V参考
* Vin+ = 0.6V DC + AC小信号 (幅度1V用于AC分析)
VREF VINN 0 DC 0.6
VIN  VINP 0 DC 0.6 AC 1

* =====================================================================
*                 交流小信号分析
* =====================================================================

* 求解直流工作点
.OP

* AC扫描: 1Hz ~ 1GHz, 每十倍频100点
.AC DEC 100 1 1G

* --- 增益测量 ---
.MEASURE AC gain_dc FIND VDB(VOUT) AT=1
.MEASURE AC gain_1k FIND VDB(VOUT) AT=1k
.MEASURE AC gain_1M FIND VDB(VOUT) AT=1MEG

* --- 相位测量 ---
.MEASURE AC phase_dc FIND VP(VOUT) AT=1
.MEASURE AC phase_1k FIND VP(VOUT) AT=1k

* --- 单位增益带宽 GBW ---
.MEASURE AC GBW WHEN VDB(VOUT)=0 CROSS=1

* --- 相位裕度 ---
.MEASURE AC phase_at_gbw FIND VP(VOUT) AT=GBW
.MEASURE AC phase_margin PARAM='phase_at_gbw + 180'

* --- 3dB带宽 ---
.MEASURE AC gain_peak MAX VDB(VOUT) FROM=1 TO=100k
.MEASURE AC gain_3db PARAM='gain_peak - 3'
.MEASURE AC f_3dB WHEN VDB(VOUT)=gain_3db CROSS=1

* --- 打印输出 ---
.PRINT AC VDB(VOUT) VP(VOUT) VR(VOUT) VI(VOUT)

.OPTIONS POST=2 ACCURATE NUMDGT=7
.END
