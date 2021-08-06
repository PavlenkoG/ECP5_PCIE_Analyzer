EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L pcie_analyzer:HMC914 D?
U 1 1 610D1FB3
P 4100 1900
F 0 "D?" H 5100 2000 50  0000 C CNN
F 1 "HMC914" H 4600 1100 50  0000 C CNN
F 2 "" H 4100 1900 50  0001 C CNN
F 3 "" H 4100 1900 50  0001 C CNN
	1    4100 1900
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:R R?
U 1 1 610D6373
P 2700 3100
F 0 "R?" V 2840 3050 50  0000 L CNB
F 1 "4.75K" V 2770 2990 50  0000 L CNN
F 2 "" V 2630 3100 50  0001 C CNN
F 3 "" H 2700 3100 50  0001 C CNN
	1    2700 3100
	0    -1   -1   0   
$EndComp
$Comp
L pcie_analyzer:R R?
U 1 1 610D804E
P 3000 3100
F 0 "R?" V 3140 3050 50  0000 L CNB
F 1 "4.75K" V 3070 2990 50  0000 L CNN
F 2 "" V 2930 3100 50  0001 C CNN
F 3 "" H 3000 3100 50  0001 C CNN
	1    3000 3100
	0    -1   -1   0   
$EndComp
$Comp
L pcie_analyzer:C C?
U 1 1 610D8A75
P 3300 3300
F 0 "C?" H 3350 3375 50  0000 L CNB
F 1 "100n" H 3350 3225 50  0000 L CNN
F 2 "" H 3300 3315 50  0001 C CNN
F 3 "" H 3300 3315 50  0001 C CNN
	1    3300 3300
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:C C?
U 1 1 610D91F4
P 3600 3300
F 0 "C?" H 3650 3375 50  0000 L CNB
F 1 "100n" H 3650 3225 50  0000 L CNN
F 2 "" H 3600 3315 50  0001 C CNN
F 3 "" H 3600 3315 50  0001 C CNN
	1    3600 3300
	1    0    0    -1  
$EndComp
Wire Wire Line
	3900 3100 3600 3100
Wire Wire Line
	3300 3200 3300 3100
Connection ~ 3300 3100
Wire Wire Line
	3300 3100 3100 3100
Wire Wire Line
	3600 3200 3600 3100
Connection ~ 3600 3100
Wire Wire Line
	3600 3100 3300 3100
Wire Wire Line
	2800 3100 2900 3100
Wire Wire Line
	2600 3100 2400 3100
$Comp
L pcie_analyzer:GND #PWR?
U 1 1 610DA458
P 2400 3600
F 0 "#PWR?" H 2395 3430 50  0001 C CNN
F 1 "GND" H 2400 3500 50  0001 C CNN
F 2 "" H 2400 3600 50  0001 C CNN
F 3 "" H 2400 3600 50  0001 C CNN
	1    2400 3600
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:GND #PWR?
U 1 1 610DA82F
P 3300 3600
F 0 "#PWR?" H 3295 3430 50  0001 C CNN
F 1 "GND" H 3300 3500 50  0001 C CNN
F 2 "" H 3300 3600 50  0001 C CNN
F 3 "" H 3300 3600 50  0001 C CNN
	1    3300 3600
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:GND #PWR?
U 1 1 610DAAF3
P 3600 3600
F 0 "#PWR?" H 3595 3430 50  0001 C CNN
F 1 "GND" H 3600 3500 50  0001 C CNN
F 2 "" H 3600 3600 50  0001 C CNN
F 3 "" H 3600 3600 50  0001 C CNN
	1    3600 3600
	1    0    0    -1  
$EndComp
Wire Wire Line
	3600 3600 3600 3400
Wire Wire Line
	3300 3600 3300 3400
Wire Wire Line
	2400 3100 2400 3600
Wire Notes Line
	2100 2900 2100 3400
Wire Notes Line
	2100 3400 2600 3400
Wire Notes Line
	2600 3400 2600 2900
Wire Notes Line
	2600 2900 2100 2900
Text Notes 2100 3200 0    50   ~ 0
connect to \neither vcc\nor gnd
Text Label 2300 1100 0    50   ~ 0
PCIE_UP_P
Text Label 2300 1200 0    50   ~ 0
PCIE_UP_N
$Comp
L pcie_analyzer:C C?
U 1 1 610DCF88
P 2100 2100
F 0 "C?" H 2150 2175 50  0000 L CNB
F 1 "4.7u" H 2150 2025 50  0000 L CNN
F 2 "" H 2100 2115 50  0001 C CNN
F 3 "" H 2100 2115 50  0001 C CNN
	1    2100 2100
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:C C?
U 1 1 610DD4E7
P 2400 2100
F 0 "C?" H 2450 2175 50  0000 L CNB
F 1 "1n" H 2450 2025 50  0000 L CNN
F 2 "" H 2400 2115 50  0001 C CNN
F 3 "" H 2400 2115 50  0001 C CNN
	1    2400 2100
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:C C?
U 1 1 610DD70F
P 2700 2100
F 0 "C?" H 2750 2175 50  0000 L CNB
F 1 "100n" H 2750 2025 50  0000 L CNN
F 2 "" H 2700 2115 50  0001 C CNN
F 3 "" H 2700 2115 50  0001 C CNN
	1    2700 2100
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:C C?
U 1 1 610DE87E
P 2100 2600
F 0 "C?" H 2150 2675 50  0000 L CNB
F 1 "1n" H 2150 2525 50  0000 L CNN
F 2 "" H 2100 2615 50  0001 C CNN
F 3 "" H 2100 2615 50  0001 C CNN
	1    2100 2600
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:C C?
U 1 1 610DE9F4
P 2400 2600
F 0 "C?" H 2450 2675 50  0000 L CNB
F 1 "100n" H 2450 2525 50  0000 L CNN
F 2 "" H 2400 2615 50  0001 C CNN
F 3 "" H 2400 2615 50  0001 C CNN
	1    2400 2600
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:C C?
U 1 1 610DF764
P 3600 2900
F 0 "C?" V 3545 2710 50  0000 L CNB
F 1 "100n" V 3545 2955 50  0000 L CNN
F 2 "" H 3600 2915 50  0001 C CNN
F 3 "" H 3600 2915 50  0001 C CNN
	1    3600 2900
	0    1    1    0   
$EndComp
Wire Wire Line
	3900 2900 3700 2900
Wire Wire Line
	3300 3000 3300 2900
Wire Wire Line
	3300 2900 3500 2900
Wire Wire Line
	3300 3000 3900 3000
$Comp
L pcie_analyzer:C C?
U 1 1 610E124F
P 2100 1600
F 0 "C?" H 2150 1675 50  0000 L CNB
F 1 "4.7u" H 2150 1525 50  0000 L CNN
F 2 "" H 2100 1615 50  0001 C CNN
F 3 "" H 2100 1615 50  0001 C CNN
	1    2100 1600
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:C C?
U 1 1 610E13FB
P 2400 1600
F 0 "C?" H 2450 1675 50  0000 L CNB
F 1 "1n" H 2450 1525 50  0000 L CNN
F 2 "" H 2400 1615 50  0001 C CNN
F 3 "" H 2400 1615 50  0001 C CNN
	1    2400 1600
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:C C?
U 1 1 610E1405
P 2700 1600
F 0 "C?" H 2750 1675 50  0000 L CNB
F 1 "100n" H 2750 1525 50  0000 L CNN
F 2 "" H 2700 1615 50  0001 C CNN
F 3 "" H 2700 1615 50  0001 C CNN
	1    2700 1600
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:GND #PWR?
U 1 1 610E854B
P 2100 2700
F 0 "#PWR?" H 2095 2530 50  0001 C CNN
F 1 "GND" H 2100 2600 50  0001 C CNN
F 2 "" H 2100 2700 50  0001 C CNN
F 3 "" H 2100 2700 50  0001 C CNN
	1    2100 2700
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:GND #PWR?
U 1 1 610E87AE
P 2400 2700
F 0 "#PWR?" H 2395 2530 50  0001 C CNN
F 1 "GND" H 2400 2600 50  0001 C CNN
F 2 "" H 2400 2700 50  0001 C CNN
F 3 "" H 2400 2700 50  0001 C CNN
	1    2400 2700
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:GND #PWR?
U 1 1 610E9369
P 2100 2200
F 0 "#PWR?" H 2095 2030 50  0001 C CNN
F 1 "GND" H 2100 2100 50  0001 C CNN
F 2 "" H 2100 2200 50  0001 C CNN
F 3 "" H 2100 2200 50  0001 C CNN
	1    2100 2200
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:GND #PWR?
U 1 1 610E9BCC
P 2400 2200
F 0 "#PWR?" H 2395 2030 50  0001 C CNN
F 1 "GND" H 2400 2100 50  0001 C CNN
F 2 "" H 2400 2200 50  0001 C CNN
F 3 "" H 2400 2200 50  0001 C CNN
	1    2400 2200
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:GND #PWR?
U 1 1 610E9D74
P 2700 2200
F 0 "#PWR?" H 2695 2030 50  0001 C CNN
F 1 "GND" H 2700 2100 50  0001 C CNN
F 2 "" H 2700 2200 50  0001 C CNN
F 3 "" H 2700 2200 50  0001 C CNN
	1    2700 2200
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:GND #PWR?
U 1 1 610E9EFA
P 2700 1700
F 0 "#PWR?" H 2695 1530 50  0001 C CNN
F 1 "GND" H 2700 1600 50  0001 C CNN
F 2 "" H 2700 1700 50  0001 C CNN
F 3 "" H 2700 1700 50  0001 C CNN
	1    2700 1700
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:GND #PWR?
U 1 1 610EA092
P 2400 1700
F 0 "#PWR?" H 2395 1530 50  0001 C CNN
F 1 "GND" H 2400 1600 50  0001 C CNN
F 2 "" H 2400 1700 50  0001 C CNN
F 3 "" H 2400 1700 50  0001 C CNN
	1    2400 1700
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:GND #PWR?
U 1 1 610EA243
P 2100 1700
F 0 "#PWR?" H 2095 1530 50  0001 C CNN
F 1 "GND" H 2100 1600 50  0001 C CNN
F 2 "" H 2100 1700 50  0001 C CNN
F 3 "" H 2100 1700 50  0001 C CNN
	1    2100 1700
	1    0    0    -1  
$EndComp
Wire Wire Line
	2100 2500 2100 2400
Wire Wire Line
	2000 2400 2100 2400
Wire Wire Line
	2400 2400 2400 2500
Wire Wire Line
	2400 2400 3300 2400
Wire Wire Line
	3300 2400 3300 2800
Wire Wire Line
	3300 2800 3900 2800
Connection ~ 2400 2400
Wire Wire Line
	3900 2500 3400 2500
Wire Wire Line
	3400 2500 3400 1900
Wire Wire Line
	3400 1900 2700 1900
Wire Wire Line
	2100 1900 2100 2000
Wire Wire Line
	2400 2000 2400 1900
Connection ~ 2400 1900
Wire Wire Line
	2400 1900 2100 1900
Wire Wire Line
	2700 2000 2700 1900
Connection ~ 2700 1900
Wire Wire Line
	2700 1900 2400 1900
Wire Wire Line
	3900 2400 3500 2400
Wire Wire Line
	3500 2400 3500 1400
Wire Wire Line
	3500 1400 2700 1400
Wire Wire Line
	2100 1400 2100 1500
Wire Wire Line
	2400 1500 2400 1400
Connection ~ 2400 1400
Wire Wire Line
	2400 1400 2100 1400
Wire Wire Line
	2700 1500 2700 1400
Connection ~ 2700 1400
Wire Wire Line
	2700 1400 2400 1400
Text GLabel 2100 1400 0    50   Input ~ 0
DISABLE
Text GLabel 2100 1900 0    50   Input ~ 0
AODWNENB
Text GLabel 2000 2400 0    50   Input ~ 0
VAC
Wire Wire Line
	3900 2200 3600 2200
Wire Wire Line
	3600 2200 3600 1200
Wire Wire Line
	2300 1200 3600 1200
Wire Wire Line
	3700 1100 3700 2100
Wire Wire Line
	3700 2100 3900 2100
Wire Wire Line
	2300 1100 3700 1100
$Comp
L pcie_analyzer:GND #PWR?
U 1 1 610F7658
P 5100 3800
F 0 "#PWR?" H 5095 3630 50  0001 C CNN
F 1 "GND" H 5100 3700 50  0001 C CNN
F 2 "" H 5100 3800 50  0001 C CNN
F 3 "" H 5100 3800 50  0001 C CNN
	1    5100 3800
	1    0    0    -1  
$EndComp
Wire Wire Line
	5100 3800 5100 3700
Wire Wire Line
	5100 3700 5000 3700
Wire Wire Line
	4200 3700 4200 3600
Connection ~ 5100 3700
Wire Wire Line
	5100 3700 5100 3600
Wire Wire Line
	4300 3600 4300 3700
Connection ~ 4300 3700
Wire Wire Line
	4300 3700 4200 3700
Wire Wire Line
	4400 3600 4400 3700
Connection ~ 4400 3700
Wire Wire Line
	4400 3700 4300 3700
Wire Wire Line
	4500 3600 4500 3700
Connection ~ 4500 3700
Wire Wire Line
	4500 3700 4400 3700
Wire Wire Line
	4600 3600 4600 3700
Connection ~ 4600 3700
Wire Wire Line
	4600 3700 4500 3700
Wire Wire Line
	4700 3600 4700 3700
Connection ~ 4700 3700
Wire Wire Line
	4700 3700 4600 3700
Wire Wire Line
	4800 3600 4800 3700
Connection ~ 4800 3700
Wire Wire Line
	4800 3700 4700 3700
Wire Wire Line
	4900 3600 4900 3700
Connection ~ 4900 3700
Wire Wire Line
	4900 3700 4800 3700
Wire Wire Line
	5000 3600 5000 3700
Connection ~ 5000 3700
Wire Wire Line
	5000 3700 4900 3700
Wire Wire Line
	5400 2100 6400 2100
Wire Wire Line
	5400 2200 6400 2200
Text Label 6000 2100 0    50   ~ 0
PCIE_1_P
Text Label 6000 2200 0    50   ~ 0
PCIE_1_N
$Comp
L pcie_analyzer:R R?
U 1 1 61104055
P 5700 2800
F 0 "R?" V 5840 2750 50  0000 L CNB
F 1 "1.82K" V 5770 2690 50  0000 L CNN
F 2 "" V 5630 2800 50  0001 C CNN
F 3 "" H 5700 2800 50  0001 C CNN
	1    5700 2800
	0    -1   -1   0   
$EndComp
Wire Wire Line
	5400 2800 5600 2800
Wire Wire Line
	5800 2800 6400 2800
Wire Wire Line
	5400 2900 6400 2900
$Comp
L pcie_analyzer:+3.3VCC #PWR?
U 1 1 61109F83
P 4500 1400
F 0 "#PWR?" H 4500 1250 50  0001 C CNN
F 1 "+3.3VCC" H 4500 1540 50  0000 C CNN
F 2 "" H 4500 1400 50  0001 C CNN
F 3 "" H 4500 1400 50  0001 C CNN
	1    4500 1400
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:+3.3VCC #PWR?
U 1 1 6110A78C
P 6400 2800
F 0 "#PWR?" H 6400 2650 50  0001 C CNN
F 1 "+3.3VCC" H 6400 2940 50  0000 C CNN
F 2 "" H 6400 2800 50  0001 C CNN
F 3 "" H 6400 2800 50  0001 C CNN
	1    6400 2800
	1    0    0    -1  
$EndComp
Text GLabel 6400 2900 2    50   Input ~ 0
RSSI
Connection ~ 2100 2400
Wire Wire Line
	2100 2400 2400 2400
$Comp
L pcie_analyzer:C C?
U 1 1 6110E72A
P 5200 1400
F 0 "C?" H 5250 1475 50  0000 L CNB
F 1 "1n" H 5250 1325 50  0000 L CNN
F 2 "" H 5200 1415 50  0001 C CNN
F 3 "" H 5200 1415 50  0001 C CNN
	1    5200 1400
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:C C?
U 1 1 6110E9BA
P 5500 1400
F 0 "C?" H 5550 1475 50  0000 L CNB
F 1 "100n" H 5550 1325 50  0000 L CNN
F 2 "" H 5500 1415 50  0001 C CNN
F 3 "" H 5500 1415 50  0001 C CNN
	1    5500 1400
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:GND #PWR?
U 1 1 6110E9C4
P 5200 1500
F 0 "#PWR?" H 5195 1330 50  0001 C CNN
F 1 "GND" H 5200 1400 50  0001 C CNN
F 2 "" H 5200 1500 50  0001 C CNN
F 3 "" H 5200 1500 50  0001 C CNN
	1    5200 1500
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:GND #PWR?
U 1 1 6110E9CE
P 5500 1500
F 0 "#PWR?" H 5495 1330 50  0001 C CNN
F 1 "GND" H 5500 1400 50  0001 C CNN
F 2 "" H 5500 1500 50  0001 C CNN
F 3 "" H 5500 1500 50  0001 C CNN
	1    5500 1500
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:C C?
U 1 1 61111396
P 6000 1400
F 0 "C?" H 6050 1475 50  0000 L CNB
F 1 "1n" H 6050 1325 50  0000 L CNN
F 2 "" H 6000 1415 50  0001 C CNN
F 3 "" H 6000 1415 50  0001 C CNN
	1    6000 1400
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:C C?
U 1 1 61111666
P 6300 1400
F 0 "C?" H 6350 1475 50  0000 L CNB
F 1 "100n" H 6350 1325 50  0000 L CNN
F 2 "" H 6300 1415 50  0001 C CNN
F 3 "" H 6300 1415 50  0001 C CNN
	1    6300 1400
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:GND #PWR?
U 1 1 61111670
P 6000 1500
F 0 "#PWR?" H 5995 1330 50  0001 C CNN
F 1 "GND" H 6000 1400 50  0001 C CNN
F 2 "" H 6000 1500 50  0001 C CNN
F 3 "" H 6000 1500 50  0001 C CNN
	1    6000 1500
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:GND #PWR?
U 1 1 6111167A
P 6300 1500
F 0 "#PWR?" H 6295 1330 50  0001 C CNN
F 1 "GND" H 6300 1400 50  0001 C CNN
F 2 "" H 6300 1500 50  0001 C CNN
F 3 "" H 6300 1500 50  0001 C CNN
	1    6300 1500
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:C C?
U 1 1 611142EB
P 7100 1400
F 0 "C?" H 7150 1475 50  0000 L CNB
F 1 "1n" H 7150 1325 50  0000 L CNN
F 2 "" H 7100 1415 50  0001 C CNN
F 3 "" H 7100 1415 50  0001 C CNN
	1    7100 1400
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:C C?
U 1 1 611145FB
P 7400 1400
F 0 "C?" H 7450 1475 50  0000 L CNB
F 1 "100n" H 7450 1325 50  0000 L CNN
F 2 "" H 7400 1415 50  0001 C CNN
F 3 "" H 7400 1415 50  0001 C CNN
	1    7400 1400
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:GND #PWR?
U 1 1 61114605
P 7100 1500
F 0 "#PWR?" H 7095 1330 50  0001 C CNN
F 1 "GND" H 7100 1400 50  0001 C CNN
F 2 "" H 7100 1500 50  0001 C CNN
F 3 "" H 7100 1500 50  0001 C CNN
	1    7100 1500
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:GND #PWR?
U 1 1 6111460F
P 7400 1500
F 0 "#PWR?" H 7395 1330 50  0001 C CNN
F 1 "GND" H 7400 1400 50  0001 C CNN
F 2 "" H 7400 1500 50  0001 C CNN
F 3 "" H 7400 1500 50  0001 C CNN
	1    7400 1500
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:C C?
U 1 1 61116879
P 6600 1400
F 0 "C?" H 6650 1475 50  0000 L CNB
F 1 "4.7u" H 6650 1325 50  0000 L CNN
F 2 "" H 6600 1415 50  0001 C CNN
F 3 "" H 6600 1415 50  0001 C CNN
	1    6600 1400
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:GND #PWR?
U 1 1 6111706A
P 6600 1500
F 0 "#PWR?" H 6595 1330 50  0001 C CNN
F 1 "GND" H 6600 1400 50  0001 C CNN
F 2 "" H 6600 1500 50  0001 C CNN
F 3 "" H 6600 1500 50  0001 C CNN
	1    6600 1500
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:C C?
U 1 1 61117519
P 7700 1400
F 0 "C?" H 7750 1475 50  0000 L CNB
F 1 "4.7u" H 7750 1325 50  0000 L CNN
F 2 "" H 7700 1415 50  0001 C CNN
F 3 "" H 7700 1415 50  0001 C CNN
	1    7700 1400
	1    0    0    -1  
$EndComp
$Comp
L pcie_analyzer:GND #PWR?
U 1 1 61117889
P 7700 1500
F 0 "#PWR?" H 7695 1330 50  0001 C CNN
F 1 "GND" H 7700 1400 50  0001 C CNN
F 2 "" H 7700 1500 50  0001 C CNN
F 3 "" H 7700 1500 50  0001 C CNN
	1    7700 1500
	1    0    0    -1  
$EndComp
Wire Wire Line
	5200 1200 5500 1200
Wire Wire Line
	6600 1200 6600 1300
Wire Wire Line
	5200 1200 5200 1300
Wire Wire Line
	6300 1200 6300 1300
Connection ~ 6300 1200
Wire Wire Line
	6300 1200 6600 1200
Wire Wire Line
	6000 1200 6000 1300
Connection ~ 6000 1200
Wire Wire Line
	6000 1200 6300 1200
Wire Wire Line
	5500 1200 5500 1300
Connection ~ 5500 1200
Wire Wire Line
	5500 1200 6000 1200
Wire Wire Line
	7100 1200 7400 1200
Wire Wire Line
	7700 1200 7700 1300
Wire Wire Line
	7100 1200 7100 1300
Wire Wire Line
	7400 1200 7400 1300
Connection ~ 7400 1200
Wire Wire Line
	7400 1200 7700 1200
$Comp
L pcie_analyzer:+3.3VCC #PWR?
U 1 1 6112CAC0
P 6600 1100
F 0 "#PWR?" H 6600 950 50  0001 C CNN
F 1 "+3.3VCC" H 6600 1240 50  0000 C CNN
F 2 "" H 6600 1100 50  0001 C CNN
F 3 "" H 6600 1100 50  0001 C CNN
	1    6600 1100
	1    0    0    -1  
$EndComp
Connection ~ 6600 1200
Wire Wire Line
	6600 1200 6600 1100
$Comp
L pcie_analyzer:+3.3VCC #PWR?
U 1 1 61132449
P 7700 1100
F 0 "#PWR?" H 7700 950 50  0001 C CNN
F 1 "+3.3VCC" H 7700 1240 50  0000 C CNN
F 2 "" H 7700 1100 50  0001 C CNN
F 3 "" H 7700 1100 50  0001 C CNN
	1    7700 1100
	1    0    0    -1  
$EndComp
Wire Wire Line
	7700 1200 7700 1100
Connection ~ 7700 1200
Wire Wire Line
	4500 1700 4500 1600
Wire Wire Line
	4500 1600 4600 1600
Wire Wire Line
	4600 1600 4600 1700
Connection ~ 4500 1600
Wire Wire Line
	4500 1600 4500 1400
Wire Wire Line
	4600 1600 4700 1600
Wire Wire Line
	4700 1600 4700 1700
Connection ~ 4600 1600
$EndSCHEMATC
