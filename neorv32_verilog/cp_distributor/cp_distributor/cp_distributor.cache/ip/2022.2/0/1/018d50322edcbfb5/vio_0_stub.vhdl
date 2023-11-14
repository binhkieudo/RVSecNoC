-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
-- Date        : Wed Nov 15 03:11:34 2023
-- Host        : binhkieudo-hotswap running 64-bit Ubuntu 20.04.6 LTS
-- Command     : write_vhdl -force -mode synth_stub -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
--               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ vio_0_stub.vhdl
-- Design      : vio_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7vx485tffg1761-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix is
  Port ( 
    clk : in STD_LOGIC;
    probe_in0 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    probe_in1 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    probe_in2 : in STD_LOGIC_VECTOR ( 3 downto 0 );
    probe_in3 : in STD_LOGIC_VECTOR ( 11 downto 0 );
    probe_in4 : in STD_LOGIC_VECTOR ( 19 downto 0 );
    probe_in5 : in STD_LOGIC_VECTOR ( 127 downto 0 );
    probe_in6 : in STD_LOGIC_VECTOR ( 127 downto 0 );
    probe_out0 : out STD_LOGIC_VECTOR ( 7 downto 0 );
    probe_out1 : out STD_LOGIC_VECTOR ( 7 downto 0 );
    probe_out2 : out STD_LOGIC_VECTOR ( 23 downto 0 );
    probe_out3 : out STD_LOGIC_VECTOR ( 39 downto 0 );
    probe_out4 : out STD_LOGIC_VECTOR ( 255 downto 0 );
    probe_out5 : out STD_LOGIC_VECTOR ( 255 downto 0 );
    probe_out6 : out STD_LOGIC_VECTOR ( 3 downto 0 )
  );

end decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix;

architecture stub of decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk,probe_in0[31:0],probe_in1[3:0],probe_in2[3:0],probe_in3[11:0],probe_in4[19:0],probe_in5[127:0],probe_in6[127:0],probe_out0[7:0],probe_out1[7:0],probe_out2[23:0],probe_out3[39:0],probe_out4[255:0],probe_out5[255:0],probe_out6[3:0]";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "vio,Vivado 2022.2";
begin
end;
