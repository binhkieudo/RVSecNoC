-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
-- Date        : Sun Nov 12 12:40:50 2023
-- Host        : binhkieudo-hotswap running 64-bit Ubuntu 20.04.6 LTS
-- Command     : write_vhdl -force -mode synth_stub
--               /home/binhkieudo/Workspace/RISC-V/RVSecNoC/neorv32_verilog/mul/mul.gen/sources_1/ip/vio_alu/vio_alu_stub.vhdl
-- Design      : vio_alu
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7vx485tffg1761-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity vio_alu is
  Port ( 
    clk : in STD_LOGIC;
    probe_in0 : in STD_LOGIC_VECTOR ( 32 downto 0 );
    probe_out0 : out STD_LOGIC_VECTOR ( 15 downto 0 );
    probe_out1 : out STD_LOGIC_VECTOR ( 15 downto 0 );
    probe_out2 : out STD_LOGIC_VECTOR ( 15 downto 0 )
  );

end vio_alu;

architecture stub of vio_alu is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk,probe_in0[32:0],probe_out0[15:0],probe_out1[15:0],probe_out2[15:0]";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "vio,Vivado 2022.2";
begin
end;
