verdiSetActWin -dock widgetDock_<Decl._Tree>
debImport "-f" "filelist.f"
debLoadSimResult \
           /home/student/Downloads/Honours project/Project/SOC_UVM/sim/soc_uart.fsdb
wvCreateWindow
wvRestoreSignal -win $_nWave2 "uart_verdi.rc" -overWriteAutoAlias on \
           -appendSignals on
verdiWindowResize -win $_Verdi_1 "340" "92" "900" "700"
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
wvUnknownSaveResult -win $_nWave2 -clear
verdiDockWidgetMaximize -dock windowDock_nWave_2
verdiSetActWin -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvSelectSignal -win $_nWave2 {( "2. DUT UART TX" 1 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("1. System Clocks & Reset" 0)}
wvSelectSignal -win $_nWave2 {( "2. DUT UART TX" 1 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("1. System Clocks & Reset" 0)}
wvSelectSignal -win $_nWave2 \
           {( "5. UART RX Serial Path (VIP Driver -> Interface \
           -> DUT RX)" 2 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("1. System Clocks & Reset" 0)}
wvSelectSignal -win $_nWave2 \
           {( "5. UART RX Serial Path (VIP Driver -> Interface \
           -> DUT RX)" 2 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("1. System Clocks & Reset" 0)}
wvSelectSignal -win $_nWave2 \
           {( "5. UART RX Serial Path (VIP Driver -> Interface \
           -> DUT RX)" 1 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("1. System Clocks & Reset" 0)}
wvSelectSignal -win $_nWave2 \
           {( "5. UART RX Serial Path (VIP Driver -> Interface \
           -> DUT RX)" 1 )} 
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("1. System Clocks & Reset" 0)}
