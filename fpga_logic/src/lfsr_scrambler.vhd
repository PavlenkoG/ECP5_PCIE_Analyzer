-------------------------------------------------------------------------------
-- Copyright (C) 2009 OutputLogic.com
-- This source file may be used and distributed without restriction
-- provided that this copyright statement is not removed from the file
-- and that any derivative work contains the original copyright notice
-- and the associated disclaimer.
--
-- THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
-- OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
-- WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
-------------------------------------------------------------------------------
-- scrambler module for data(7:0)
--   lfsr(15:0)=1+x^3+x^4+x^5+x^16;
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.analyzer_pkg.all;

entity lfsr_scrambler is
  port ( 
    clk         : in std_logic;
    rst         : in std_logic;
    data_in     : in std_logic_vector (7 downto 0);
    rx_k        : in std_logic;
    data_out    : out std_logic_vector (7 downto 0);
    rx_k_out    : out std_logic
    );
end lfsr_scrambler;

architecture imp_scrambler of lfsr_scrambler is
  signal data_c     : std_logic_vector (7 downto 0);
  signal lfsr_q     : std_logic_vector (15 downto 0);
  signal lfsr_c     : std_logic_vector (15 downto 0);
  signal scram_en   : std_logic;
  signal scram_rst  : std_logic;
begin
    lfsr_c(0) <= lfsr_q(8);
    lfsr_c(1) <= lfsr_q(9);
    lfsr_c(2) <= lfsr_q(10);
    lfsr_c(3) <= lfsr_q(8) xor lfsr_q(11);
    lfsr_c(4) <= lfsr_q(8) xor lfsr_q(9) xor lfsr_q(12);
    lfsr_c(5) <= lfsr_q(8) xor lfsr_q(9) xor lfsr_q(10) xor lfsr_q(13);
    lfsr_c(6) <= lfsr_q(9) xor lfsr_q(10) xor lfsr_q(11) xor lfsr_q(14);
    lfsr_c(7) <= lfsr_q(10) xor lfsr_q(11) xor lfsr_q(12) xor lfsr_q(15);
    lfsr_c(8) <= lfsr_q(0) xor lfsr_q(11) xor lfsr_q(12) xor lfsr_q(13);
    lfsr_c(9) <= lfsr_q(1) xor lfsr_q(12) xor lfsr_q(13) xor lfsr_q(14);
    lfsr_c(10) <= lfsr_q(2) xor lfsr_q(13) xor lfsr_q(14) xor lfsr_q(15);
    lfsr_c(11) <= lfsr_q(3) xor lfsr_q(14) xor lfsr_q(15);
    lfsr_c(12) <= lfsr_q(4) xor lfsr_q(15);
    lfsr_c(13) <= lfsr_q(5);
    lfsr_c(14) <= lfsr_q(6);
    lfsr_c(15) <= lfsr_q(7);

    data_c(0) <= data_in(0) xor lfsr_q(15);
    data_c(1) <= data_in(1) xor lfsr_q(14);
    data_c(2) <= data_in(2) xor lfsr_q(13);
    data_c(3) <= data_in(3) xor lfsr_q(12);
    data_c(4) <= data_in(4) xor lfsr_q(11);
    data_c(5) <= data_in(5) xor lfsr_q(10);
    data_c(6) <= data_in(6) xor lfsr_q(9);
    data_c(7) <= data_in(7) xor lfsr_q(8);

    scram_rst <= '1' when rx_k = '1' and data_in = K_COM_SYM_28_5 else '0';
    scram_en  <= '0' when rx_k = '1' and data_in = K_COM_SYM_28_5 else
                 '0' when rx_k = '1' and data_in = K_PAD_SKP_28_0 else
                 '1';

    process (clk,rst) begin
      if (rst = '1') then
        lfsr_q <= b"1111111111111111";
        data_out <= b"00000000";
    elsif (clk'EVENT and clk = '1') then
        rx_k_out <= rx_k;
        if (scram_rst = '1') then
          lfsr_q <= b"1111111111111111";
        elsif (scram_en = '1') then
          lfsr_q <= lfsr_c;
        end if;

        if (scram_en = '1' and rx_k = '0') then
          data_out <= data_c;
        else
          data_out <= data_in;
        end if;
      end if;
    end process;
end architecture imp_scrambler;
