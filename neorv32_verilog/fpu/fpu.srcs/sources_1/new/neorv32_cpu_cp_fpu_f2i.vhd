----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/26/2023 04:04:07 PM
-- Design Name: 
-- Module Name: neorv32_cpu_cp_fpu_f2i - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neorv32;
use neorv32.neorv32_package.all;

entity neorv32_cpu_cp_fpu_f2i is
  port (
    -- control --
    clk_i      : in  std_ulogic; -- global clock, rising edge
    rstn_i     : in  std_ulogic; -- global reset, low-active, async
    start_i    : in  std_ulogic; -- trigger operation
    abort_i    : in  std_ulogic; -- abort current operation
    rmode_i    : in  std_ulogic_vector(02 downto 0); -- rounding mode
    funct_i    : in  std_ulogic; -- 0=signed, 1=unsigned
    -- input --
    sign_i     : in  std_ulogic; -- sign
    exponent_i : in  std_ulogic_vector(07 downto 0); -- exponent
    mantissa_i : in  std_ulogic_vector(22 downto 0); -- mantissa
    class_i    : in  std_ulogic_vector(09 downto 0); -- operand class
    -- output --
    result_o   : out std_ulogic_vector(31 downto 0); -- integer result
    flags_o    : out std_ulogic_vector(04 downto 0); -- exception flags
    done_o     : out std_ulogic -- operation done
  );
end neorv32_cpu_cp_fpu_f2i;

architecture neorv32_cpu_cp_fpu_f2i_rtl of neorv32_cpu_cp_fpu_f2i is

  -- controller --
  type ctrl_engine_state_t is (S_IDLE, S_PREPARE_F2I, S_NORMALIZE_BUSY, S_ROUND, S_FINALIZE);
  type ctrl_t is record
    state      : ctrl_engine_state_t; -- current state
    unsign     : std_ulogic;
    cnt        : std_ulogic_vector(07 downto 0); -- interation counter/exponent
    sign       : std_ulogic;
    class      : std_ulogic_vector(09 downto 0);
    rounded    : std_ulogic; -- output is rounded
    over       : std_ulogic; -- output is overflowing
    under      : std_ulogic; -- output in underflowing
    result_tmp : std_ulogic_vector(31 downto 0);
    result     : std_ulogic_vector(31 downto 0);
  end record;
  signal ctrl : ctrl_t;

  -- conversion shift register --
  type sreg_t is record
    int   : std_ulogic_vector(31 downto 0); -- including hidden-zero
    mant  : std_ulogic_vector(22 downto 0);
    ext_g : std_ulogic; -- guard bit
    ext_r : std_ulogic; -- round bit
    ext_s : std_ulogic; -- sticky bit
  end record;
  signal sreg : sreg_t;

  -- rounding unit --
  type round_t is record
    en     : std_ulogic; -- enable rounding
    sub    : std_ulogic; -- 0=decrement, 1=increment
    output : std_ulogic_vector(32 downto 0); -- result + overflow
  end record;
  signal round : round_t;

begin

  -- Control Engine -------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  ctrl_engine: process(rstn_i, clk_i)
  begin
    if (rstn_i = '0') then
      ctrl.state      <= S_IDLE;
      ctrl.cnt        <= (others => '0');
      ctrl.sign       <= '0';
      ctrl.class      <= (others => '0');
      ctrl.rounded    <= '0';
      ctrl.over       <= '0';
      ctrl.under      <= '0';
      ctrl.unsign     <= '0';
      ctrl.result     <= (others => '0');
      ctrl.result_tmp <= (others => '0');
      sreg.int        <= (others => '0');
      sreg.mant       <= (others => '0');
      sreg.ext_s      <= '0';
      done_o          <= '0';
    elsif rising_edge(clk_i) then
      -- defaults --
      done_o <= '0';

      -- fsm --
      case ctrl.state is

        when S_IDLE => -- wait for operation trigger
        -- ------------------------------------------------------------
          ctrl.rounded <= '0'; -- not rounded yet
          ctrl.over    <= '0'; -- not overflowing yet
          ctrl.under   <= '0'; -- not underflowing yet
          ctrl.unsign  <= funct_i;
          sreg.ext_s   <= '0'; -- init
          if (start_i = '1') then
            ctrl.cnt    <= exponent_i;
            ctrl.sign   <= sign_i;
            ctrl.class  <= class_i;
            sreg.mant   <= mantissa_i;
            ctrl.state  <= S_PREPARE_F2I;
          end if;

        when S_PREPARE_F2I => -- prepare float-to-integer conversion
        -- ------------------------------------------------------------
          if (unsigned(ctrl.cnt) < 126) then -- less than 0.5
            sreg.int    <= (others => '0');
            ctrl.under  <= '1'; -- this is an underflow!
            ctrl.cnt    <= (others => '0');
          elsif (unsigned(ctrl.cnt) = 126) then -- num < 1.0 but num >= 0.5
            sreg.int    <= (others => '0');
            sreg.mant   <= '1' & sreg.mant(sreg.mant'left downto 1);
            ctrl.cnt    <= (others => '0');
          else
            sreg.int    <= (others => '0');
            sreg.int(0) <= '1'; -- hidden one
            ctrl.cnt    <= std_ulogic_vector(unsigned(ctrl.cnt) - 127); -- remove bias to get raw number of left shifts
          end if;
          -- check terminal cases --
          if ((ctrl.class(fp_class_neg_inf_c)  or ctrl.class(fp_class_pos_inf_c) or
               ctrl.class(fp_class_neg_zero_c) or ctrl.class(fp_class_pos_zero_c) or
               ctrl.class(fp_class_snan_c)     or ctrl.class(fp_class_qnan_c)) = '1') then
            ctrl.state <= S_FINALIZE;
          else
            -- Trip: If the float exponent is to large to fit in an integer we are
            -- shifting the float mantissa out of the integer causing an overflow.
            -- We detect this when the exponent is larger than 127 + XLEN + 1.
            -- Catch: When the exponent is larger than XLEN + 1 set the overflow flag and go to the next stage.
            -- Note: We use 127 as that is an exponent of 0, XLEN for the integer width and + 1 for safety.
            -- In principle the +1 shouldn't be needed.
            if (unsigned(ctrl.cnt) > (127+XLEN+1)) then -- 0 + 32 + 1 or 127 + 32 + 1
              ctrl.over <= '1';
              ctrl.state <= S_FINALIZE;
            else
              ctrl.state <= S_NORMALIZE_BUSY;
            end if;
          end if;

        when S_NORMALIZE_BUSY => -- running normalization cycle
        -- ------------------------------------------------------------
          if (or_reduce_f(sreg.mant(sreg.mant'left-2 downto 0)) = '1') then
            sreg.ext_s <= '1'; -- sticky bit
          end if;
          if (or_reduce_f(ctrl.cnt(ctrl.cnt'left-1 downto 0)) = '0') then
            if (ctrl.unsign = '0') then -- signed conversion
              ctrl.over <= ctrl.over or sreg.int(sreg.int'left); -- update overrun flag again to check for numerical overflow into sign bit
            end if;
            ctrl.state <= S_ROUND;
          else -- shift left
            ctrl.cnt  <= std_ulogic_vector(unsigned(ctrl.cnt) - 1);
            sreg.int  <= sreg.int(sreg.int'left-1 downto 0) & sreg.mant(sreg.mant'left);
            sreg.mant <= sreg.mant(sreg.mant'left-1 downto 0) & '0';
            ctrl.over <= ctrl.over or sreg.int(sreg.int'left);
          end if;

        when S_ROUND => -- rounding cycle
        -- ------------------------------------------------------------
          ctrl.rounded    <= ctrl.rounded or round.en;
          ctrl.over       <= ctrl.over or round.output(round.output'left); -- overflow after rounding
          ctrl.result_tmp <= round.output(round.output'left-1 downto 0);
          ctrl.state      <= S_FINALIZE;

        when S_FINALIZE => -- check for corner cases and finalize result
        -- ------------------------------------------------------------
          if (ctrl.unsign = '1') then -- unsigned conversion
            if (ctrl.class(fp_class_snan_c) = '1') or (ctrl.class(fp_class_qnan_c) = '1') or (ctrl.class(fp_class_pos_inf_c) = '1') or -- NaN or +inf
               ((ctrl.sign = '0') and (ctrl.over = '1')) then -- positive out-of-range
              ctrl.result <= x"ffffffff";
            elsif (ctrl.class(fp_class_neg_zero_c) = '1') or (ctrl.class(fp_class_pos_zero_c) = '1') or (ctrl.class(fp_class_neg_inf_c) = '1') or -- subnormal zero or -inf
               (ctrl.sign = '1') or (ctrl.under = '1') then -- negative out-of-range or underflow
              ctrl.result <= x"00000000";
            else
              ctrl.result <= ctrl.result_tmp;
            end if;

          else -- signed conversion
            if (ctrl.class(fp_class_snan_c) = '1') or (ctrl.class(fp_class_qnan_c) = '1') or (ctrl.class(fp_class_pos_inf_c) = '1') or  -- NaN or +inf
                  ((ctrl.sign = '0') and (ctrl.over = '1')) then -- positive out-of-range
              ctrl.result <= x"7fffffff";
            elsif (ctrl.class(fp_class_neg_zero_c) = '1') or (ctrl.class(fp_class_pos_zero_c) = '1') or (ctrl.under = '1') then -- subnormal zero or underflow
              ctrl.result <= x"00000000";
            elsif (ctrl.class(fp_class_neg_inf_c) = '1') or ((ctrl.sign = '1') and (ctrl.over = '1')) then -- -inf or negative out-of-range
              ctrl.result <= x"80000000";
            else -- result is ok, make sign adaption
              if (ctrl.sign = '1') then
                ctrl.result <= std_ulogic_vector(0 - unsigned(ctrl.result_tmp)); -- abs()
              else
                ctrl.result <= ctrl.result_tmp;
              end if;
            end if;
          end if;
          done_o     <= '1';
          ctrl.state <= S_IDLE;

        when others => -- undefined
        -- ------------------------------------------------------------
          ctrl.state <= S_IDLE;

      end case;

      -- override: abort operation --
      if (abort_i = '1') then
        ctrl.state <= S_IDLE;
      end if;
    end if;
  end process ctrl_engine;

  -- result --
  result_o <= ctrl.result;

  -- exception flags --
  flags_o(fp_exc_nv_c) <= ctrl.class(fp_class_snan_c) or ctrl.class(fp_class_qnan_c); -- invalid operation
  flags_o(fp_exc_dz_c) <= '0'; -- divide by zero - not possible here
  flags_o(fp_exc_of_c) <= ctrl.over or ctrl.class(fp_class_pos_inf_c) or ctrl.class(fp_class_neg_inf_c); -- overflow
  flags_o(fp_exc_uf_c) <= ctrl.under; -- underflow
  flags_o(fp_exc_nx_c) <= ctrl.rounded; -- inexact if result was rounded


  -- Rounding -------------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  rounding_unit_ctrl: process(rmode_i, sreg)
  begin
    -- defaults --
    round.en  <= '0';
    round.sub <= '0';
    -- rounding mode --
    case rmode_i(2 downto 0) is
      when "000" => -- round to nearest, ties to even
        if (sreg.ext_g = '0') then
          round.en <= '0'; -- round down (do nothing)
        else
          if (sreg.ext_r = '0') and (sreg.ext_s = '0') then -- tie!
            round.en <= sreg.int(0); -- round up if LSB of integer is set
          else
            round.en <= '1'; -- round up
          end if;
        end if;
        round.sub <= '0'; -- increment
      when "001" => -- round towards zero
        round.en <= '0'; -- no rounding -> just truncate
      when "010" => -- round down (towards -infinity)
        round.en  <= sreg.ext_g or sreg.ext_r or sreg.ext_s;
        round.sub <= '1'; -- decrement
      when "011" => -- round up (towards +infinity)
        round.en  <= sreg.ext_g or sreg.ext_r or sreg.ext_s;
        round.sub <= '0'; -- increment
      when "100" => -- round to nearest, ties to max magnitude
        round.en <= '0'; -- FIXME / TODO
      when others => -- undefined
        round.en <= '0';
    end case;
  end process rounding_unit_ctrl;

  -- rounding: guard and round bits --
  sreg.ext_g <= sreg.mant(sreg.mant'left);
  sreg.ext_r <= sreg.mant(sreg.mant'left-1);


  -- incrementer/decrementer --
  rounding_unit_add: process(round, sreg)
    variable tmp_v : std_ulogic_vector(32 downto 0); -- including overflow
  begin
    tmp_v := '0' & sreg.int;
    if (round.en = '1') then
      if (round.sub = '0') then -- increment
        round.output <= std_ulogic_vector(unsigned(tmp_v) + 1);
      else -- decrement
        round.output <= std_ulogic_vector(unsigned(tmp_v) - 1);
      end if;
    else -- do nothing
      round.output <= tmp_v;
    end if;
  end process rounding_unit_add;


end neorv32_cpu_cp_fpu_f2i_rtl;

