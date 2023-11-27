----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/26/2023 03:59:36 PM
-- Design Name: 
-- Module Name: neorv32_cpu_cp_fpu_normalizer - Behavioral
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

entity neorv32_cpu_cp_fpu_normalizer is
  port (
    -- control --
    clk_i      : in  std_ulogic; -- global clock, rising edge
    rstn_i     : in  std_ulogic; -- global reset, low-active, async
    start_i    : in  std_ulogic; -- trigger operation
    abort_i    : in  std_ulogic; -- abort current operation
    rmode_i    : in  std_ulogic_vector(02 downto 0); -- rounding mode
    funct_i    : in  std_ulogic; -- operating mode (0=norm&round, 1=int-to-float)
    -- input --
    sign_i     : in  std_ulogic; -- sign
    exponent_i : in  std_ulogic_vector(08 downto 0); -- extended exponent
    mantissa_i : in  std_ulogic_vector(47 downto 0); -- extended mantissa
    integer_i  : in  std_ulogic_vector(31 downto 0); -- integer input
    class_i    : in  std_ulogic_vector(09 downto 0); -- input number class
    flags_i    : in  std_ulogic_vector(04 downto 0); -- exception flags input
    -- output --
    result_o   : out std_ulogic_vector(31 downto 0); -- float result
    flags_o    : out std_ulogic_vector(04 downto 0); -- exception flags output
    done_o     : out std_ulogic -- operation done
  );
end neorv32_cpu_cp_fpu_normalizer;

architecture neorv32_cpu_cp_fpu_normalizer_rtl of neorv32_cpu_cp_fpu_normalizer is

  -- controller --
  type ctrl_engine_state_t is (S_IDLE, S_PREPARE_I2F, S_CHECK_I2F, S_PREPARE_NORM, S_PREPARE_SHIFT, S_NORMALIZE_BUSY, S_ROUND, S_CHECK, S_FINALIZE);
  type ctrl_t is record
    state   : ctrl_engine_state_t; -- current state
    norm_r  : std_ulogic; -- normalization round 0 or 1
    cnt     : std_ulogic_vector(08 downto 0); -- interation counter/exponent (incl. overflow)
    cnt_pre : std_ulogic_vector(08 downto 0);
    cnt_of  : std_ulogic; -- counter overflow
    cnt_uf  : std_ulogic; -- counter underflow
    rounded : std_ulogic; -- output is rounded
    res_sgn : std_ulogic;
    res_exp : std_ulogic_vector(07 downto 0);
    res_man : std_ulogic_vector(22 downto 0);
    class   : std_ulogic_vector(09 downto 0);
    flags   : std_ulogic_vector(04 downto 0);
  end record;
  signal ctrl : ctrl_t;

  -- normalization shift register --
  type sreg_t is record
    done  : std_ulogic;
    dir   : std_ulogic; -- shift direction: 0=right, 1=left
    zero  : std_ulogic;
    upper : std_ulogic_vector(31 downto 0);
    lower : std_ulogic_vector(22 downto 0);
    ext_g : std_ulogic; -- guard bit
    ext_r : std_ulogic; -- round bit
    ext_s : std_ulogic; -- sticky bit
  end record;
  signal sreg : sreg_t;

  -- rounding unit --
  type round_t is record
    en     : std_ulogic; -- enable rounding
    sub    : std_ulogic; -- 0=decrement, 1=increment
    output : std_ulogic_vector(24 downto 0); -- mantissa size + hidden one + 1
  end record;
  signal round : round_t;

begin

  -- Control Engine -------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  ctrl_engine: process(rstn_i, clk_i)
  begin
    if (rstn_i = '0') then
      ctrl.state   <= S_IDLE;
      ctrl.norm_r  <= '0';
      ctrl.cnt     <= (others => '0');
      ctrl.cnt_pre <= (others => '0');
      ctrl.cnt_of  <= '0';
      ctrl.cnt_uf  <= '0';
      ctrl.rounded <= '0';
      ctrl.res_exp <= (others => '0');
      ctrl.res_man <= (others => '0');
      ctrl.res_sgn <= '0';
      ctrl.class   <= (others => '0');
      ctrl.flags   <= (others => '0');
      --
      sreg.upper   <= (others => '0');
      sreg.lower   <= (others => '0');
      sreg.dir     <= '0';
      sreg.ext_g   <= '0';
      sreg.ext_r   <= '0';
      sreg.ext_s   <= '0';
      --
      done_o       <= '0';
    elsif rising_edge(clk_i) then
      -- defaults --
      ctrl.cnt_pre <= ctrl.cnt;
      done_o       <= '0';

      -- exponent counter underflow/overflow --
      if ((ctrl.cnt_pre(8 downto 7) = "01") and (ctrl.cnt(8 downto 7) = "10")) then -- overflow
        ctrl.cnt_of <= '1';
      elsif (ctrl.cnt_pre(8 downto 7) = "00") and (ctrl.cnt(8 downto 7) = "11") then -- underflow
        ctrl.cnt_uf <= '1';
      end if;

      -- fsm --
      case ctrl.state is

        when S_IDLE => -- wait for operation trigger
        -- ------------------------------------------------------------
          ctrl.norm_r  <= '0'; -- start with first normalization
          ctrl.rounded <= '0'; -- not rounded yet
          ctrl.cnt_of  <= '0';
          ctrl.cnt_uf  <= '0';
          --
          if (start_i = '1') then
            ctrl.cnt     <= exponent_i;
            ctrl.res_sgn <= sign_i;
            ctrl.class   <= class_i;
            ctrl.flags   <= flags_i;
            if (funct_i = '0') then -- float -> float
              ctrl.state <= S_PREPARE_NORM;
            else -- integer -> float
              ctrl.state <= S_PREPARE_I2F;
            end if;
          end if;

        when S_PREPARE_I2F => -- prepare integer-to-float conversion
        -- ------------------------------------------------------------
          sreg.upper <= integer_i;
          sreg.lower <= (others => '0');
          sreg.ext_g <= '0';
          sreg.ext_r <= '0';
          sreg.ext_s <= '0';
          sreg.dir   <= '0'; -- shift right
          ctrl.state <= S_CHECK_I2F;

        when S_CHECK_I2F => -- check if converting zero
        -- ------------------------------------------------------------
          if (sreg.zero = '1') then -- all zero
            ctrl.class(fp_class_pos_zero_c) <= '1';
            ctrl.state <= S_FINALIZE;
          else
            ctrl.state <= S_NORMALIZE_BUSY;
          end if;

        when S_PREPARE_NORM => -- prepare "normal" normalization & rounding
        -- ------------------------------------------------------------
          sreg.upper(31 downto 02) <= (others => '0');
          sreg.upper(01 downto 00) <= mantissa_i(47 downto 46);
          sreg.lower <= mantissa_i(45 downto 23);
          sreg.ext_g <= mantissa_i(22);
          sreg.ext_r <= mantissa_i(21);
          if (or_reduce_f(mantissa_i(20 downto 0)) = '1') then
            sreg.ext_s <= '1';
          else
            sreg.ext_s <= '0';
          end if;
          -- check for special cases --
          if ((ctrl.class(fp_class_snan_c)       or ctrl.class(fp_class_qnan_c)       or -- NaN
               ctrl.class(fp_class_neg_zero_c)   or ctrl.class(fp_class_pos_zero_c)   or -- zero
               ctrl.class(fp_class_neg_denorm_c) or ctrl.class(fp_class_pos_denorm_c) or -- subnormal
               ctrl.class(fp_class_neg_inf_c)    or ctrl.class(fp_class_pos_inf_c)    or -- infinity
               ctrl.flags(fp_exc_uf_c) or -- underflow
               ctrl.flags(fp_exc_of_c) or -- overflow
               ctrl.flags(fp_exc_nv_c)) = '1') then -- invalid
            ctrl.state <= S_FINALIZE;
          -- The normalizer only checks the class of the inputs and not the result.
          -- Check whether adder result is 0.0 which can happen if eg. 1.0 - 1.0
          -- Set the ctrl.cnt to 0 to force the resulting exponent to be 0
          -- Do not change sreg.lower as that is already all 0s
          -- Do not change sign as that should be the right sign from the add/sub
          elsif (unsigned(mantissa_i(47 downto 0)) = 0) then
            ctrl.cnt <= (others => '0');
            ctrl.state <= S_FINALIZE;
          else
            ctrl.state <= S_PREPARE_SHIFT;
          end if;

        when S_PREPARE_SHIFT => -- prepare shift direction (for "normal" normalization only)
        -- ------------------------------------------------------------
          if (sreg.zero = '0') then -- number < 1.0
            sreg.dir <= '0'; -- shift right
          else -- number >= 1.0
            sreg.dir <= '1'; -- shift left
          end if;
          ctrl.state <= S_NORMALIZE_BUSY;

        when S_NORMALIZE_BUSY => -- running normalization cycle
        -- ------------------------------------------------------------
          -- shift until normalized or exception --
          if (sreg.done = '1') or (ctrl.cnt_uf = '1') or (ctrl.cnt_of = '1') then
            -- normalization control --
            ctrl.norm_r <= '1';
            if (ctrl.norm_r = '0') then -- first normalization cycle done
              ctrl.state <= S_ROUND;
            else -- second normalization cycle done
              ctrl.state <= S_CHECK;
            end if;
          else
            if (sreg.dir = '0') then -- shift right
              ctrl.cnt   <= std_ulogic_vector(unsigned(ctrl.cnt) + 1);
              sreg.upper <= '0' & sreg.upper(sreg.upper'left downto 1);
              sreg.lower <= sreg.upper(0) & sreg.lower(sreg.lower'left downto 1);
              sreg.ext_g <= sreg.lower(0);
              sreg.ext_r <= sreg.ext_g;
              sreg.ext_s <= sreg.ext_r or sreg.ext_s; -- sticky bit
            else -- shift left
              ctrl.cnt   <= std_ulogic_vector(unsigned(ctrl.cnt) - 1);
              sreg.upper <= sreg.upper(sreg.upper'left-1 downto 0) & sreg.lower(sreg.lower'left);
              sreg.lower <= sreg.lower(sreg.lower'left-1 downto 0) & sreg.ext_g;
              sreg.ext_g <= sreg.ext_r;
              sreg.ext_r <= sreg.ext_s;
              sreg.ext_s <= sreg.ext_s; -- sticky bit
            end if;
          end if;

        when S_ROUND => -- rounding cycle (after first normalization)
        -- ------------------------------------------------------------
          ctrl.rounded <= ctrl.rounded or round.en;
          sreg.upper(31 downto 02) <= (others => '0');
          sreg.upper(01 downto 00) <= round.output(24 downto 23);
          sreg.lower <= round.output(22 downto 00);
          sreg.ext_g <= '0';
          sreg.ext_r <= '0';
          sreg.ext_s <= '0';
          ctrl.state <= S_PREPARE_SHIFT;

        when S_CHECK => -- check for overflow/underflow
        -- ------------------------------------------------------------
          if (ctrl.cnt_uf = '1') then -- underflow
            ctrl.flags(fp_exc_uf_c) <= '1';
          elsif (ctrl.cnt_of = '1') then -- overflow
            ctrl.flags(fp_exc_of_c) <= '1';
          elsif (ctrl.cnt(7 downto 0) = x"00") then -- subnormal
            ctrl.flags(fp_exc_uf_c) <= '1';
          elsif (ctrl.cnt(7 downto 0) = x"FF") then -- infinity
            ctrl.flags(fp_exc_of_c) <= '1';
          end if;
          ctrl.state <= S_FINALIZE;

        when S_FINALIZE => -- result finalization
        -- ------------------------------------------------------------
          -- generate result word (the ORDER of checks is important here!) --
          if (ctrl.class(fp_class_snan_c) = '1') or (ctrl.class(fp_class_qnan_c) = '1') then -- sNaN / qNaN
            ctrl.res_sgn <= fp_single_qnan_c(31);
            ctrl.res_exp <= fp_single_qnan_c(30 downto 23);
            ctrl.res_man <= fp_single_qnan_c(22 downto 00);
          elsif (ctrl.class(fp_class_neg_inf_c) = '1') or (ctrl.class(fp_class_pos_inf_c) = '1') or -- infinity
                (ctrl.flags(fp_exc_of_c) = '1') then -- overflow
            ctrl.res_exp <= fp_single_pos_inf_c(30 downto 23); -- keep original sign
            ctrl.res_man <= fp_single_pos_inf_c(22 downto 00);
          elsif (ctrl.class(fp_class_neg_zero_c) = '1') or (ctrl.class(fp_class_pos_zero_c) = '1') then -- zero
            ctrl.res_sgn <= ctrl.class(fp_class_neg_zero_c);
            ctrl.res_exp <= fp_single_pos_zero_c(30 downto 23);
            ctrl.res_man <= fp_single_pos_zero_c(22 downto 00);
          elsif (ctrl.flags(fp_exc_uf_c) = '1') or -- underflow
                (sreg.zero = '1') or (ctrl.class(fp_class_neg_denorm_c) = '1') or (ctrl.class(fp_class_pos_denorm_c) = '1') then -- denormalized (flush-to-zero)
            ctrl.res_exp <= fp_single_pos_zero_c(30 downto 23); -- keep original sign
            ctrl.res_man <= fp_single_pos_zero_c(22 downto 00);
          else -- result is ok
            ctrl.res_exp <= ctrl.cnt(7 downto 0);
            ctrl.res_man <= sreg.lower;
          end if;
          -- generate exception flags --
          ctrl.flags(fp_exc_nv_c) <= ctrl.flags(fp_exc_nv_c) or ctrl.class(fp_class_snan_c); -- invalid if input is SIGNALING NaN
          ctrl.flags(fp_exc_nx_c) <= ctrl.flags(fp_exc_nx_c) or ctrl.rounded; -- inexcat if result is rounded
          --
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

  -- stop shifting when normalized --
  sreg.done <= '1' when (or_reduce_f(sreg.upper(sreg.upper'left downto 1)) = '0') and (sreg.upper(0) = '1') else '0'; -- input is zero, hidden one is set

  -- all-zero including hidden bit --
  sreg.zero <= '1' when (or_reduce_f(sreg.upper) = '0') else '0';

  -- result --
  result_o(31)           <= ctrl.res_sgn;
  result_o(30 downto 23) <= ctrl.res_exp;
  result_o(22 downto  0) <= ctrl.res_man;

  -- exception flags --
  flags_o(fp_exc_nv_c) <= ctrl.flags(fp_exc_nv_c); -- invalid operation
  flags_o(fp_exc_dz_c) <= ctrl.flags(fp_exc_dz_c); -- divide by zero
  flags_o(fp_exc_of_c) <= ctrl.flags(fp_exc_of_c); -- overflow
  flags_o(fp_exc_uf_c) <= ctrl.flags(fp_exc_uf_c); -- underflow
  flags_o(fp_exc_nx_c) <= ctrl.flags(fp_exc_nx_c); -- inexact


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
            round.en <= sreg.lower(0); -- round up if LSB of mantissa is set
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


  -- incrementer/decrementer --
  rounding_unit_add: process(round, sreg)
    variable tmp_v : std_ulogic_vector(24 downto 0);
  begin
    tmp_v := '0' & sreg.upper(0) & sreg.lower;
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


end neorv32_cpu_cp_fpu_normalizer_rtl;