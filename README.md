# ECP5_PCIE_Analyzer
The main idea of this project is the evaluation of the possibility of using the PCS-Block of ECP5UMG FPGA for PCI-Express protocol analysis.
The PCS Block can deserialize physical PCI-Express signals and decode 8b10b. <p>
Deserialized data can be used to analyze protocol traffic, detecting errors and so on.<p>
The first implementation involves an adapter print to connect PCI-Express lanes to PCS-Block in FPGA and an evaluation board with ECP5UM(G).<p>
The adapter print should be connected to the eval. board through VERSA Expansion headers and SMA-Cables.

https://www.latticesemi.com/products/developmentboardsandkits/ecp5evaluationboard
# VERSA Expansion Headers
![sch](doc/pic/connector.png)
# Eval Board top view
![Block Schema](doc/pic/block_sch.svg)

![Eval Board Top](/doc/pic/ecp_eval_board_top.png)

# Eval Board bottom view
![Eval Board Bottom](/doc/pic/ecp_eval_board_bot.png)

## Impedance calculation JLCPCB
![impedance 50 Ohm single](/doc/pic/impedance_single_50.png)
![impedance 100 Ohm diff](/doc/pic/impedance_diff_100.png)