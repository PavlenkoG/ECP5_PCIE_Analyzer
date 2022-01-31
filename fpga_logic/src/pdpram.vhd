library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity pdpram is
generic (
    addr_width : natural := 16;
    data_width : natural := 36);
port (
    write_en    : in std_logic;
    waddr       : in std_logic_vector (addr_width - 1 downto 0);
    wclk        : in std_logic;
    raddr       : in std_logic_vector (addr_width - 1 downto 0);
    rclk        : in std_logic;
    din         : in std_logic_vector (data_width - 1 downto 0);
    dout        : out std_logic_vector (data_width - 1 downto 0));
end pdpram;

architecture rtl of pdpram is
    type mem_type is array (0 to (2 ** addr_width) - 1) of std_logic_vector(35 downto 0);
    signal mem : mem_type := (
        ('1' & X"AB" & '0' & X"CD" & '0' & X"EF" & '0' & X"FF"), -- 1
        ('0' & X"00" & '0' & X"01" & '0' & X"02" & '0' & X"03"), -- 2
        ('0' & X"04" & '0' & X"05" & '0' & X"06" & '0' & X"07"), -- 3
        ('0' & X"08" & '0' & X"09" & '0' & X"0A" & '0' & X"0B"), -- 4
        ('0' & X"0C" & '0' & X"0D" & '0' & X"0E" & '0' & X"0F"), -- 5
        ('0' & X"10" & '0' & X"11" & '0' & X"12" & '0' & X"13"), -- 6
        ('0' & X"14" & '0' & X"15" & '0' & X"16" & '0' & X"17"), -- 7
        ('0' & X"18" & '0' & X"19" & '0' & X"1A" & '0' & X"1B"), -- 8
        ('1' & X"AB" & '0' & X"CD" & '0' & X"EF" & '0' & X"FF"), -- 1
        ('0' & X"20" & '0' & X"21" & '0' & X"22" & '0' & X"23"), -- 2
        ('0' & X"24" & '0' & X"25" & '0' & X"26" & '0' & X"27"), -- 3
        ('0' & X"28" & '0' & X"29" & '0' & X"2A" & '0' & X"2B"), -- 4
        ('0' & X"2C" & '0' & X"2D" & '0' & X"2E" & '0' & X"2F"), -- 5
        ('0' & X"30" & '0' & X"31" & '0' & X"32" & '0' & X"33"), -- 6
        ('0' & X"34" & '0' & X"35" & '0' & X"36" & '0' & X"37"), -- 7
        ('0' & X"38" & '0' & X"39" & '0' & X"3A" & '0' & X"3B"), -- 8
        others => (others =>'0')
    );

    attribute syn_ramstyle  : string;
    attribute syn_ramstyle of mem: signal is "no_rw_check";
begin
    process (wclk) -- Write memory.
    begin
        if (wclk'event and wclk = '1') then
            if (write_en = '1') then
                mem(conv_integer(waddr)) <= din; -- Using write address bus.
            end if;
        end if;
    end process;

    process (rclk) -- Read memory.
    begin
        if (rclk'event and rclk = '1') then
            dout <= mem(conv_integer(raddr)); -- Using read address bus.
        end if;
    end process;
end rtl;