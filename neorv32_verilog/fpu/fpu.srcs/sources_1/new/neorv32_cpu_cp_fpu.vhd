----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/26/2023 04:07:02 PM
-- Design Name: 
-- Module Name: neorv32_cpu_cp_fpu - Behavioral
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

entity neorv32_cpu_cp_fpu is
  port (
    -- global control --
    clk_i       : in  std_ulogic; -- global clock, rising edge
    rstn_i      : in  std_ulogic; -- global reset, low-active, async
    ctrl_i      : in  ctrl_bus_t; -- main control bus
    start_i     : in  std_ulogic; -- trigger operation
    -- CSR interface --
    csr_we_i    : in  std_ulogic; -- global write enable
    csr_addr_i  : in  std_ulogic_vector(11 downto 0); -- address
    csr_wdata_i : in  std_ulogic_vector(XLEN-1 downto 0); -- write data
    csr_rdata_o : out std_ulogic_vector(XLEN-1 downto 0); -- read data
    -- data input --
    cmp_i       : in  std_ulogic_vector(1 downto 0); -- comparator status
    rs1_i       : in  std_ulogic_vector(XLEN-1 downto 0); -- rf source 1
    rs2_i       : in  std_ulogic_vector(XLEN-1 downto 0); -- rf source 2
    rs3_i       : in  std_ulogic_vector(XLEN-1 downto 0); -- rf source 3
    -- result and status --
    res_o       : out std_ulogic_vector(XLEN-1 downto 0); -- operation result
    valid_o     : out std_ulogic -- data output valid
  );
end neorv32_cpu_cp_fpu;

architecture neorv32_cpu_cp_fpu_rtl of neorv32_cpu_cp_fpu is

  -- FPU core functions --
  constant op_class_c  : std_ulogic_vector(2 downto 0) := "000";
  constant op_comp_c   : std_ulogic_vector(2 downto 0) := "001";
  constant op_i2f_c    : std_ulogic_vector(2 downto 0) := "010";
  constant op_f2i_c    : std_ulogic_vector(2 downto 0) := "011";
  constant op_sgnj_c   : std_ulogic_vector(2 downto 0) := "100";
  constant op_minmax_c : std_ulogic_vector(2 downto 0) := "101";
  constant op_addsub_c : std_ulogic_vector(2 downto 0) := "110";
  constant op_mul_c    : std_ulogic_vector(2 downto 0) := "111";

  -- FPU CSRs --
  signal csr_frm    : std_ulogic_vector(2 downto 0); -- FPU rounding mode
  signal csr_fflags : std_ulogic_vector(4 downto 0); -- FPU exception flags
  signal fflags     : std_ulogic_vector(4 downto 0); -- exception flags

  -- float-to-integer unit --
  component neorv32_cpu_cp_fpu_f2i
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
  end component;

  -- normalizer + rounding unit --
  component neorv32_cpu_cp_fpu_normalizer
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
    result_o   : out std_ulogic_vector(31 downto 0); -- result (float or int)
    flags_o    : out std_ulogic_vector(04 downto 0); -- exception flags
    done_o     : out std_ulogic -- operation done
  );
  end component;

  -- commands (one-hot) --
  type cmd_t is record
    instr_class  : std_ulogic;
    instr_sgnj   : std_ulogic;
    instr_comp   : std_ulogic;
    instr_i2f    : std_ulogic;
    instr_f2i    : std_ulogic;
    instr_minmax : std_ulogic;
    instr_addsub : std_ulogic;
    instr_mul    : std_ulogic;
    funct        : std_ulogic_vector(2 downto 0);
  end record;
  signal cmd : cmd_t;
  signal funct_ff : std_ulogic_vector(2 downto 0);

  -- co-processor control engine --
  type ctrl_state_t is (S_IDLE, S_BUSY);
  type ctrl_engine_t is record
    state : ctrl_state_t;
    start : std_ulogic;
    valid : std_ulogic;
  end record;
  signal ctrl_engine : ctrl_engine_t;

  -- floating-point operands --
  type op_data_t  is array (0 to 1) of std_ulogic_vector(31 downto 0);
  type op_class_t is array (0 to 1) of std_ulogic_vector(09 downto 0);
  type fpu_operands_t is record
    rs1       : std_ulogic_vector(31 downto 0); -- operand 1
    rs1_class : std_ulogic_vector(09 downto 0); -- operand 1 number class
    rs2       : std_ulogic_vector(31 downto 0); -- operand 2
    rs2_class : std_ulogic_vector(09 downto 0); -- operand 2 number class
    frm       : std_ulogic_vector(02 downto 0); -- rounding mode
  end record;
  signal op_data      : op_data_t;
  signal op_class     : op_class_t;
  signal fpu_operands : fpu_operands_t;

  -- floating-point comparator --
  signal cmp_ff        : std_ulogic_vector(01 downto 0);
  signal comp_equal_ff : std_ulogic;
  signal comp_less_ff  : std_ulogic;

  -- functional units interface --
  type fu_interface_t is record
    result : std_ulogic_vector(31 downto 0);
    flags  : std_ulogic_vector(04 downto 0);
    start  : std_ulogic;
    done   : std_ulogic;
  end record;
  signal fu_classify    : fu_interface_t;
  signal fu_compare     : fu_interface_t;
  signal fu_sign_inject : fu_interface_t;
  signal fu_min_max     : fu_interface_t;
  signal fu_conv_f2i    : fu_interface_t;
  signal fu_addsub      : fu_interface_t;
  signal fu_mul         : fu_interface_t;
  signal fu_core_done   : std_ulogic; -- FU operation completed

  -- integer-to-float --
  type fu_i2f_interface_t is record
    result : std_ulogic_vector(31 downto 0);
    sign   : std_ulogic;
    start  : std_ulogic;
    done   : std_ulogic;
  end record;
  signal fu_conv_i2f : fu_i2f_interface_t; -- float result

  -- multiplier unit --
  type multiplier_t is record
    opa       : unsigned(23 downto 0); -- mantissa A plus hidden one
    opb       : unsigned(23 downto 0); -- mantissa B plus hidden one
    buf_ff    : unsigned(47 downto 0); -- product buffer
    sign      : std_ulogic; -- resulting sign
    product   : std_ulogic_vector(47 downto 0); -- product
    exp_sum   : std_ulogic_vector(08 downto 0); -- incl 1x overflow/underflow bit
    exp_res   : std_ulogic_vector(09 downto 0); -- resulting exponent incl 2x overflow/underflow bit
    --
    res_class : std_ulogic_vector(09 downto 0);
    flags     : std_ulogic_vector(04 downto 0); -- exception flags
    --
    start     : std_ulogic;
    latency   : std_ulogic_vector(02 downto 0); -- unit latency
    done      : std_ulogic;
  end record;
  signal multiplier : multiplier_t;

  -- adder/subtractor unit --
  type addsub_t is record
    -- input comparison --
    exp_comp  : std_ulogic_vector(01 downto 0); -- equal & less
    small_exp : std_ulogic_vector(07 downto 0);
    small_man : std_ulogic_vector(23 downto 0); -- mantissa + hidden one
    large_exp : std_ulogic_vector(07 downto 0);
    large_man : std_ulogic_vector(23 downto 0); -- mantissa + hidden one
    -- smaller mantissa alginment --
    man_sreg  : std_ulogic_vector(23 downto 0); -- mantissa + hidden one
    man_g_ext : std_ulogic;
    man_r_ext : std_ulogic;
    man_s_ext : std_ulogic;
    exp_cnt   : std_ulogic_vector(08 downto 0);
    -- adder/subtractor stage --
    man_comp  : std_ulogic;
    man_s     : std_ulogic_vector(26 downto 0); -- mantissa + hidden one + GRS
    man_l     : std_ulogic_vector(26 downto 0); -- mantissa + hidden one + GRS
    add_stage : std_ulogic_vector(27 downto 0); -- adder result incl. overflow
    -- result --
    res_sign  : std_ulogic;
    res_sum   : std_ulogic_vector(27 downto 0); -- mantissa sum (+1 bit) + GRS bits (for rounding)
    res_class : std_ulogic_vector(09 downto 0);
    flags     : std_ulogic_vector(04 downto 0); -- exception flags
    -- arbitration --
    start     : std_ulogic;
    latency   : std_ulogic_vector(04 downto 0); -- unit latency
    done      : std_ulogic;
  end record;
  signal addsub : addsub_t;

  -- normalizer interface (normalization & rounding and int-to-float) --
  type normalizer_t is record
    start     : std_ulogic;
    mode      : std_ulogic;
    sign      : std_ulogic;
    xexp      : std_ulogic_vector(08 downto 0);
    xmantissa : std_ulogic_vector(47 downto 0);
    result    : std_ulogic_vector(31 downto 0);
    class     : std_ulogic_vector(09 downto 0);
    flags_in  : std_ulogic_vector(04 downto 0);
    flags_out : std_ulogic_vector(04 downto 0);
    done      : std_ulogic;
  end record;
  signal normalizer : normalizer_t;

begin

-- ****************************************************************************************************************************
-- Control
-- ****************************************************************************************************************************

  -- CSR Access -----------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------

  -- write access --
  csr_write: process(rstn_i, clk_i)
  begin
    if (rstn_i = '0') then
      csr_frm    <= (others => '0');
      csr_fflags <= (others => '0');
    elsif rising_edge(clk_i) then
      if (csr_we_i = '1') then
        if (csr_addr_i(11 downto 2) = csr_fflags_c(11 downto 2)) then
          -- exception flags --
          if (csr_addr_i(1 downto 0) = csr_fflags_c(1 downto 0)) then
            csr_fflags <= csr_wdata_i(4 downto 0);
          end if;
          -- rounding mode --
          if (csr_addr_i(1 downto 0) = csr_frm_c(1 downto 0)) then
            csr_frm <= csr_wdata_i(2 downto 0);
          end if;
          -- control/status (frm & fflags) --
          if (csr_addr_i(1 downto 0) = csr_fcsr_c(1 downto 0)) then
            csr_frm    <= csr_wdata_i(7 downto 5);
            csr_fflags <= csr_wdata_i(4 downto 0);
          end if;
        end if;
      else -- auto-update
        csr_fflags <= csr_fflags or fflags;
      end if;
    end if;
  end process csr_write;


  -- read access --
  csr_read: process(csr_addr_i, csr_fflags, csr_frm)
  begin
    csr_rdata_o <= (others => '0'); -- default
    case csr_addr_i is
      when csr_fflags_c => csr_rdata_o(4 downto 0) <= csr_fflags; -- exception flags
      when csr_frm_c    => csr_rdata_o(2 downto 0) <= csr_frm; -- rounding mode
      when csr_fcsr_c   => csr_rdata_o(7 downto 0) <= csr_frm & csr_fflags; -- control/status (frm & fflags)
      when others       => NULL;
    end case;
  end process csr_read;


  -- Instruction Decoding -------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  -- one-hot re-encoding --
  cmd.instr_class  <= '1' when (ctrl_i.ir_funct12(11 downto 7) = "11100") else '0';
  cmd.instr_comp   <= '1' when (ctrl_i.ir_funct12(11 downto 7) = "10100") else '0';
  cmd.instr_i2f    <= '1' when (ctrl_i.ir_funct12(11 downto 7) = "11010") else '0';
  cmd.instr_f2i    <= '1' when (ctrl_i.ir_funct12(11 downto 7) = "11000") else '0';
  cmd.instr_sgnj   <= '1' when (ctrl_i.ir_funct12(11 downto 7) = "00100") else '0';
  cmd.instr_minmax <= '1' when (ctrl_i.ir_funct12(11 downto 7) = "00101") else '0';
  cmd.instr_addsub <= '1' when (ctrl_i.ir_funct12(11 downto 8) = "0000")  else '0';
  cmd.instr_mul    <= '1' when (ctrl_i.ir_funct12(11 downto 7) = "00010") else '0';

  -- binary re-encoding --
  cmd.funct <= op_mul_c     when (cmd.instr_mul    = '1') else
               op_addsub_c  when (cmd.instr_addsub = '1') else
               op_minmax_c  when (cmd.instr_minmax = '1') else
               op_sgnj_c    when (cmd.instr_sgnj   = '1') else
               op_f2i_c     when (cmd.instr_f2i    = '1') else
               op_i2f_c     when (cmd.instr_i2f    = '1') else
               op_comp_c    when (cmd.instr_comp   = '1') else
               op_class_c;--when (cmd.instr_class  = '1') else (others => '-');


  -- Input Operands: Check for subnormal numbers (flush to zero) ----------------------------
  -- -------------------------------------------------------------------------------------------
  -- Subnormal numbers are not supported and are "flushed to zero"! FIXME / TODO
  -- rs1 --
  op_data(0)(31)           <= rs1_i(31);
  op_data(0)(30 downto 23) <= rs1_i(30 downto 23);
  op_data(0)(22 downto 00) <= (others => '0') when (rs1_i(30 downto 23) = "00000000") else rs1_i(22 downto 0); -- flush mantissa to zero if subnormal
  -- rs2 --
  op_data(1)(31)           <= rs2_i(31);
  op_data(1)(30 downto 23) <= rs2_i(30 downto 23);
  op_data(1)(22 downto 00) <= (others => '0') when (rs2_i(30 downto 23) = "00000000") else rs2_i(22 downto 0); -- flush mantissa to zero if subnormal


  -- Number Classifier ----------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  number_classifier: process(op_data)
    variable op_m_all_zero_v, op_e_all_zero_v, op_e_all_one_v       : std_ulogic;
    variable op_is_zero_v, op_is_inf_v, op_is_denorm_v, op_is_nan_v : std_ulogic;
  begin
    for i in 0 to 1 loop -- for rs1 and rs2 inputs
      -- check for all-zero/all-one --
      op_m_all_zero_v := '0';
      op_e_all_zero_v := '0';
      op_e_all_one_v  := '0';
      if (or_reduce_f(op_data(i)(22 downto 00)) = '0') then
        op_m_all_zero_v := '1';
      end if;
      if (or_reduce_f(op_data(i)(30 downto 23)) = '0') then
        op_e_all_zero_v := '1';
      end if;
      if (and_reduce_f(op_data(i)(30 downto 23)) = '1') then
        op_e_all_one_v  := '1';
      end if;

      -- check special cases --
      op_is_zero_v   := op_e_all_zero_v and      op_m_all_zero_v;  -- zero
      op_is_inf_v    := op_e_all_one_v  and      op_m_all_zero_v;  -- infinity
      op_is_denorm_v := '0'; -- FIXME / TODO -- op_e_all_zero_v and (not op_m_all_zero_v); -- subnormal
      op_is_nan_v    := op_e_all_one_v  and (not op_m_all_zero_v); -- NaN

      -- actual attributes --
      op_class(i)(fp_class_neg_inf_c)    <= op_data(i)(31) and op_is_inf_v; -- negative infinity
      op_class(i)(fp_class_neg_norm_c)   <= op_data(i)(31) and (not op_is_denorm_v) and (not op_is_nan_v) and (not op_is_inf_v) and (not op_is_zero_v); -- negative normal number
      op_class(i)(fp_class_neg_denorm_c) <= op_data(i)(31) and op_is_denorm_v; -- negative subnormal number
      op_class(i)(fp_class_neg_zero_c)   <= op_data(i)(31) and op_is_zero_v; -- negative zero
      op_class(i)(fp_class_pos_zero_c)   <= (not op_data(i)(31)) and op_is_zero_v; -- positive zero
      op_class(i)(fp_class_pos_denorm_c) <= (not op_data(i)(31)) and op_is_denorm_v; -- positive subnormal number
      op_class(i)(fp_class_pos_norm_c)   <= (not op_data(i)(31)) and (not op_is_denorm_v) and (not op_is_nan_v) and (not op_is_inf_v) and (not op_is_zero_v); -- positive normal number
      op_class(i)(fp_class_pos_inf_c)    <= (not op_data(i)(31)) and op_is_inf_v; -- positive infinity
      op_class(i)(fp_class_snan_c)       <= op_is_nan_v and (not op_data(i)(22)); -- signaling NaN
      op_class(i)(fp_class_qnan_c)       <= op_is_nan_v and (    op_data(i)(22)); -- quiet NaN
    end loop; -- i
  end process number_classifier;


  -- Co-Processor Control Engine ------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  control_engine_fsm: process(rstn_i, clk_i)
  begin
    if (rstn_i = '0') then
      ctrl_engine.state      <= S_IDLE;
      ctrl_engine.valid      <= '0';
      ctrl_engine.start      <= '0';
      fpu_operands.frm       <= (others => '0');
      fpu_operands.rs1       <= (others => '0');
      fpu_operands.rs1_class <= (others => '0');
      fpu_operands.rs2       <= (others => '0');
      fpu_operands.rs2_class <= (others => '0');
      funct_ff               <= (others => '0');
      cmp_ff                 <= (others => '0');
    elsif rising_edge(clk_i) then
      -- arbiter defaults --
      ctrl_engine.valid <= '0';
      ctrl_engine.start <= '0';

      -- state machine --
      case ctrl_engine.state is

        when S_IDLE => -- waiting for operation trigger
        -- ------------------------------------------------------------
          funct_ff <= cmd.funct; -- actual operation to execute
          cmp_ff   <= cmp_i; -- main ALU comparator
          -- rounding mode --
          -- TODO / FIXME "round to nearest, ties to max magnitude" (0b100) is not supported yet
          if (ctrl_i.ir_funct3 = "111") then
            fpu_operands.frm <= '0' & csr_frm(1 downto 0);
          else
            fpu_operands.frm <= '0' & ctrl_i.ir_funct3(1 downto 0);
          end if;
          --
          if (start_i = '1') then
            -- operand data --
            fpu_operands.rs1       <= op_data(0);
            fpu_operands.rs1_class <= op_class(0);
            fpu_operands.rs2       <= op_data(1);
            fpu_operands.rs2_class <= op_class(1);
            -- execute! --
            ctrl_engine.start <= '1';
            ctrl_engine.state <= S_BUSY;
          end if;

        when S_BUSY => -- operation in progress (multi-cycle)
        -- -----------------------------------------------------------
          if (fu_core_done = '1') or (ctrl_i.cpu_trap = '1') then -- processing done? abort if trap
            ctrl_engine.valid <= '1';
            ctrl_engine.state <= S_IDLE;
          end if;

        when others => -- undefined
        -- ------------------------------------------------------------
          ctrl_engine.state <= S_IDLE;

      end case;
    end if;
  end process control_engine_fsm;

  -- operation done / valid output --
  valid_o <= ctrl_engine.valid;


  -- Functional Unit Interface (operation-start trigger) ------------------------------------
  -- -------------------------------------------------------------------------------------------
  fu_classify.start    <= ctrl_engine.start and cmd.instr_class;
  fu_compare.start     <= ctrl_engine.start and cmd.instr_comp;
  fu_sign_inject.start <= ctrl_engine.start and cmd.instr_sgnj;
  fu_min_max.start     <= ctrl_engine.start and cmd.instr_minmax;
  fu_conv_i2f.start    <= ctrl_engine.start and cmd.instr_i2f;
  fu_conv_f2i.start    <= ctrl_engine.start and cmd.instr_f2i;
  fu_addsub.start      <= ctrl_engine.start and cmd.instr_addsub;
  fu_mul.start         <= ctrl_engine.start and cmd.instr_mul;


-- ****************************************************************************************************************************
-- FPU Core - Functional Units
-- ****************************************************************************************************************************

  -- Number Classifier (FCLASS) -------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  fu_classify.flags <= (others => '0'); -- does not generate flags at all
  fu_classify.result(31 downto 10) <= (others => '0');
  fu_classify.result(09 downto 00) <= fpu_operands.rs1_class;
  fu_classify.done <= fu_classify.start;


  -- Floating-Point Comparator --------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  float_comparator: process(clk_i)
    variable cond_v : std_ulogic_vector(1 downto 0);
  begin
    if rising_edge(clk_i) then
      -- equal --
      if ((fpu_operands.rs1_class(fp_class_pos_inf_c)   = '1') and (fpu_operands.rs2_class(fp_class_pos_inf_c) = '1')) or -- +inf == +inf
         ((fpu_operands.rs1_class(fp_class_neg_inf_c)   = '1') and (fpu_operands.rs2_class(fp_class_neg_inf_c) = '1')) or -- -inf == -inf
         (((fpu_operands.rs1_class(fp_class_pos_zero_c) = '1') or (fpu_operands.rs1_class(fp_class_neg_zero_c) = '1')) and
          ((fpu_operands.rs2_class(fp_class_pos_zero_c) = '1') or (fpu_operands.rs2_class(fp_class_neg_zero_c) = '1'))) or  -- +/-zero == +/-zero
         (cmp_ff(cmp_equal_c) = '1') then -- identical in every way (comparator result from main ALU)
        comp_equal_ff <= '1';
      else
        comp_equal_ff <= '0';
      end if;

      -- less than --
      if ((fpu_operands.rs1_class(fp_class_pos_inf_c)  = '1') and (fpu_operands.rs2_class(fp_class_pos_inf_c) = '1')) or -- +inf !< +inf
         ((fpu_operands.rs1_class(fp_class_neg_inf_c)  = '1') and (fpu_operands.rs2_class(fp_class_neg_inf_c) = '1')) or -- -inf !< -inf
         (((fpu_operands.rs1_class(fp_class_pos_zero_c) = '1') or (fpu_operands.rs1_class(fp_class_neg_zero_c) = '1')) and
          ((fpu_operands.rs2_class(fp_class_pos_zero_c) = '1') or (fpu_operands.rs2_class(fp_class_neg_zero_c) = '1'))) then  -- +/-zero !< +/-zero
        comp_less_ff <= '0';
      else
        cond_v := fpu_operands.rs1(31) & fpu_operands.rs2(31);
        case cond_v is
          when "10"   => comp_less_ff <= '1'; -- rs1 negative, rs2 positive
          when "01"   => comp_less_ff <= '0'; -- rs1 positive, rs2 negative
          when "00"   => comp_less_ff <= cmp_ff(cmp_less_c); -- both positive (comparator result from main ALU)
          when "11"   => comp_less_ff <= not cmp_ff(cmp_less_c); -- both negative (comparator result from main ALU)
          when others => comp_less_ff <= '0'; -- undefined
        end case;
      end if;

      -- comparator latency --
      fu_compare.done <= fu_compare.start; -- for actual comparison operation
      fu_min_max.done <= fu_min_max.start; -- for min/max operations
    end if;
  end process float_comparator;


  -- Comparison (FEQ/FLT/FLE) ---------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  float_comparison: process(fpu_operands, ctrl_i, comp_equal_ff, comp_less_ff)
    variable snan_v : std_ulogic; -- at least one input is sNaN
    variable qnan_v : std_ulogic; -- at least one input is qNaN
  begin
    -- check for NaN --
    snan_v := fpu_operands.rs1_class(fp_class_snan_c) or fpu_operands.rs2_class(fp_class_snan_c);
    qnan_v := fpu_operands.rs1_class(fp_class_qnan_c) or fpu_operands.rs2_class(fp_class_qnan_c);

    -- condition evaluation --
    fu_compare.result <= (others => '0');
    case ctrl_i.ir_funct3(1 downto 0) is
      when "00" => -- FLE: less than or equal
        fu_compare.result(0) <= (comp_less_ff or comp_equal_ff) and (not (snan_v or qnan_v)); -- result is zero if either input is NaN
      when "01" => -- FLT: less than
        fu_compare.result(0) <= comp_less_ff and (not (snan_v or qnan_v)); -- result is zero if either input is NaN
      when "10" => -- FEQ: equal
        fu_compare.result(0) <= comp_equal_ff and (not (snan_v or qnan_v)); -- result is zero if either input is NaN
      when others => -- undefined
        fu_compare.result(0) <= '0';
    end case;
  end process float_comparison;

  -- latency --
  -- -> done in "float_comparator"

  -- exceptions --
  fu_compare.flags <= (others => '0'); -- does not generate exceptions here, but normalizer can generate exceptions


  -- Min/Max Select (FMIN/FMAX) -------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  min_max_select: process(fpu_operands, comp_less_ff, fu_compare, ctrl_i)
    variable cond_v : std_ulogic_vector(2 downto 0);
  begin
    -- comparison result - check for special cases: -0 is less than +0
    if ((fpu_operands.rs1_class(fp_class_neg_zero_c) = '1') and (fpu_operands.rs2_class(fp_class_pos_zero_c) = '1')) then
      cond_v(0) := ctrl_i.ir_funct3(0);
    elsif ((fpu_operands.rs1_class(fp_class_pos_zero_c) = '1') and (fpu_operands.rs2_class(fp_class_neg_zero_c) = '1')) then
      cond_v(0) := not ctrl_i.ir_funct3(0);
    else -- "normal= comparison
      cond_v(0) := comp_less_ff xnor ctrl_i.ir_funct3(0); -- min/max select
    end if;

    -- number NaN check --
    cond_v(2) := fpu_operands.rs1_class(fp_class_snan_c) or fpu_operands.rs1_class(fp_class_qnan_c);
    cond_v(1) := fpu_operands.rs2_class(fp_class_snan_c) or fpu_operands.rs2_class(fp_class_qnan_c);

    -- data output --
    case cond_v is
      when "000"         => fu_min_max.result <= fpu_operands.rs1;
      when "001"         => fu_min_max.result <= fpu_operands.rs2;
      when "010" | "011" => fu_min_max.result <= fpu_operands.rs1; -- if one input is NaN output the non-NaN one
      when "100" | "101" => fu_min_max.result <= fpu_operands.rs2; -- if one input is NaN output the non-NaN one
      when others        => fu_min_max.result <= fp_single_qnan_c; -- output quiet NaN if both inputs are NaN
    end case;
  end process min_max_select;

  -- latency --
  -- -> done in "float_comparator"

  -- exceptions --
  fu_min_max.flags <= (others => '0'); -- does not generate exceptions here, but normalizer can generate exceptions


  -- Convert: Float to [unsigned] Integer (FCVT.S.W) ----------------------------------------
  -- -------------------------------------------------------------------------------------------
  neorv32_cpu_cp_fpu_f2i_inst: neorv32_cpu_cp_fpu_f2i
  port map (
    -- control --
    clk_i      => clk_i,                          -- global clock, rising edge
    rstn_i     => rstn_i,                         -- global reset, low-active, async
    start_i    => fu_conv_f2i.start,              -- trigger operation
    abort_i    => ctrl_i.cpu_trap,                -- abort current operation
    rmode_i    => fpu_operands.frm,               -- rounding mode
    funct_i    => ctrl_i.ir_funct12(0),           -- 0=signed, 1=unsigned
    -- input --
    sign_i     => fpu_operands.rs1(31),           -- sign
    exponent_i => fpu_operands.rs1(30 downto 23), -- exponent
    mantissa_i => fpu_operands.rs1(22 downto 00), -- mantissa
    class_i    => fpu_operands.rs1_class,         -- operand class
    -- output --
    result_o   => fu_conv_f2i.result,             -- integer result
    flags_o    => fu_conv_f2i.flags,              -- exception flags
    done_o     => fu_conv_f2i.done                -- operation done
  );


  -- Sign-Injection (FSGNJ) -----------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  sign_injector: process(ctrl_i, fpu_operands)
  begin
    case ctrl_i.ir_funct3(1 downto 0) is
      when "00"   => fu_sign_inject.result(31) <= fpu_operands.rs2(31); -- FSGNJ
      when "01"   => fu_sign_inject.result(31) <= not fpu_operands.rs2(31); -- FSGNJN
      when "10"   => fu_sign_inject.result(31) <= fpu_operands.rs1(31) xor fpu_operands.rs2(31); -- FSGNJX
      when others => fu_sign_inject.result(31) <= fpu_operands.rs2(31); -- undefined
    end case;
    fu_sign_inject.result(30 downto 0) <= fpu_operands.rs1(30 downto 0);
    fu_sign_inject.flags <= (others => '0'); -- does not generate flags
  end process sign_injector;

  -- latency --
  fu_sign_inject.done <= fu_sign_inject.start;


  -- Convert: [unsigned] Integer to Float (FCVT.W.S) ----------------------------------------
  -- -------------------------------------------------------------------------------------------
  convert_i2f: process(clk_i)
  begin
    -- this process only computes the absolute input value
    -- the actual conversion is done by the normalizer
    if rising_edge(clk_i) then
      if (ctrl_i.ir_funct12(0) = '0') and (rs1_i(31) = '1') then -- convert signed integer
        fu_conv_i2f.result <= std_ulogic_vector(0 - unsigned(rs1_i));
        fu_conv_i2f.sign   <= rs1_i(31); -- original sign
      else -- convert unsigned integer
        fu_conv_i2f.result <= rs1_i;
        fu_conv_i2f.sign   <= '0';
      end if;
      fu_conv_i2f.done <= fu_conv_i2f.start; -- actual conversion is done by the normalizer unit
    end if;
  end process convert_i2f;


  -- Multiplier Core (FMUL) -----------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  multiplier_core: process(clk_i)
  begin
    if rising_edge(clk_i) then
      -- multiplier core --
      if (multiplier.start = '1') then -- FIXME / TODO remove buffer?
        multiplier.opa <= unsigned('1' & fpu_operands.rs1(22 downto 0)); -- append hidden one
        multiplier.opb <= unsigned('1' & fpu_operands.rs2(22 downto 0)); -- append hidden one
      end if;
      multiplier.buf_ff  <= multiplier.opa * multiplier.opb;
      multiplier.product <= std_ulogic_vector(multiplier.buf_ff(47 downto 0)); -- let the register balancing do the magic here
      multiplier.sign    <= fpu_operands.rs1(31) xor fpu_operands.rs2(31); -- resulting sign

      -- exponent computation --
      multiplier.exp_res <= std_ulogic_vector(unsigned('0' & multiplier.exp_sum) - 127);
      if (multiplier.exp_res(multiplier.exp_res'left) = '1') then -- underflow (exp_res is "negative")
        multiplier.flags(fp_exc_of_c) <= '0';
        multiplier.flags(fp_exc_uf_c) <= '1';
      elsif (multiplier.exp_res(multiplier.exp_res'left-1) = '1') then -- overflow
        multiplier.flags(fp_exc_of_c) <= '1';
        multiplier.flags(fp_exc_uf_c) <= '0';
      else
        multiplier.flags(fp_exc_of_c) <= '0';
        multiplier.flags(fp_exc_uf_c) <= '0';
      end if;

      -- invalid operation --
      multiplier.flags(fp_exc_nv_c) <=
        ((fpu_operands.rs1_class(fp_class_pos_zero_c) or fpu_operands.rs1_class(fp_class_neg_zero_c)) and
         (fpu_operands.rs2_class(fp_class_pos_inf_c)  or fpu_operands.rs2_class(fp_class_neg_inf_c))) or -- mul(+/-zero, +/-inf)
        ((fpu_operands.rs1_class(fp_class_pos_inf_c)  or fpu_operands.rs1_class(fp_class_neg_inf_c)) and
         (fpu_operands.rs2_class(fp_class_pos_zero_c) or fpu_operands.rs2_class(fp_class_neg_zero_c))); -- mul(+/-inf, +/-zero)

      -- latency shift register --
      multiplier.latency <= multiplier.latency(multiplier.latency'left-1 downto 0) & multiplier.start;
    end if;
  end process multiplier_core;

  -- exponent sum --
  multiplier.exp_sum <= std_ulogic_vector(unsigned('0' & fpu_operands.rs1(30 downto 23)) + unsigned('0' & fpu_operands.rs2(30 downto 23)));

  -- latency --
  multiplier.start <= fu_mul.start;
  multiplier.done  <= multiplier.latency(multiplier.latency'left);
  fu_mul.done      <= multiplier.done;

  -- unused exception flags --
  multiplier.flags(fp_exc_dz_c) <= '0'; -- division by zero: not possible here
  multiplier.flags(fp_exc_nx_c) <= '0'; -- inexcat: not possible here


  -- result class --
  multiplier_class_core: process(clk_i)
    variable a_pos_norm_v, a_neg_norm_v, b_pos_norm_v, b_neg_norm_v : std_ulogic;
    variable a_pos_subn_v, a_neg_subn_v, b_pos_subn_v, b_neg_subn_v : std_ulogic;
    variable a_pos_zero_v, a_neg_zero_v, b_pos_zero_v, b_neg_zero_v : std_ulogic;
    variable a_pos_inf_v,  a_neg_inf_v,  b_pos_inf_v,  b_neg_inf_v  : std_ulogic;
    variable a_snan_v,     a_qnan_v,     b_snan_v,     b_qnan_v     : std_ulogic;
  begin
    if rising_edge(clk_i) then
      -- minions --
      a_pos_norm_v := fpu_operands.rs1_class(fp_class_pos_norm_c);    b_pos_norm_v := fpu_operands.rs2_class(fp_class_pos_norm_c);
      a_neg_norm_v := fpu_operands.rs1_class(fp_class_neg_norm_c);    b_neg_norm_v := fpu_operands.rs2_class(fp_class_neg_norm_c);
      a_pos_subn_v := fpu_operands.rs1_class(fp_class_pos_denorm_c);  b_pos_subn_v := fpu_operands.rs2_class(fp_class_pos_denorm_c);
      a_neg_subn_v := fpu_operands.rs1_class(fp_class_neg_denorm_c);  b_neg_subn_v := fpu_operands.rs2_class(fp_class_neg_denorm_c);
      a_pos_zero_v := fpu_operands.rs1_class(fp_class_pos_zero_c);    b_pos_zero_v := fpu_operands.rs2_class(fp_class_pos_zero_c);
      a_neg_zero_v := fpu_operands.rs1_class(fp_class_neg_zero_c);    b_neg_zero_v := fpu_operands.rs2_class(fp_class_neg_zero_c);
      a_pos_inf_v  := fpu_operands.rs1_class(fp_class_pos_inf_c);     b_pos_inf_v  := fpu_operands.rs2_class(fp_class_pos_inf_c);
      a_neg_inf_v  := fpu_operands.rs1_class(fp_class_neg_inf_c);     b_neg_inf_v  := fpu_operands.rs2_class(fp_class_neg_inf_c);
      a_snan_v     := fpu_operands.rs1_class(fp_class_snan_c);        b_snan_v     := fpu_operands.rs2_class(fp_class_snan_c);
      a_qnan_v     := fpu_operands.rs1_class(fp_class_qnan_c);        b_qnan_v     := fpu_operands.rs2_class(fp_class_qnan_c);

      -- +normal --
      multiplier.res_class(fp_class_pos_norm_c) <=
        (a_pos_norm_v and b_pos_norm_v) or -- +norm * +norm
        (a_neg_norm_v and b_neg_norm_v);   -- -norm * -norm
      -- -normal --
      multiplier.res_class(fp_class_neg_norm_c) <=
        (a_pos_norm_v and b_neg_norm_v) or -- +norm * -norm
        (a_neg_norm_v and b_pos_norm_v);   -- -norm * +norm

      -- +infinity --
      multiplier.res_class(fp_class_pos_inf_c) <=
        (a_pos_inf_v  and b_pos_inf_v)  or -- +inf    * +inf
        (a_neg_inf_v  and b_neg_inf_v)  or -- -inf    * -inf
        (a_pos_norm_v and b_pos_inf_v)  or -- +norm   * +inf
        (a_pos_inf_v  and b_pos_norm_v) or -- +inf    * +norm
        (a_neg_norm_v and b_neg_inf_v)  or -- -norm   * -inf
        (a_neg_inf_v  and b_neg_norm_v) or -- -inf    * -norm
        (a_neg_subn_v and b_neg_inf_v)  or -- -denorm * -inf
        (a_neg_inf_v  and b_neg_subn_v);   -- -inf    * -denorm
      -- -infinity --
      multiplier.res_class(fp_class_neg_inf_c) <=
        (a_pos_inf_v  and b_neg_inf_v)  or -- +inf    * -inf
        (a_neg_inf_v  and b_pos_inf_v)  or -- -inf    * +inf
        (a_pos_norm_v and b_neg_inf_v)  or -- +norm   * -inf
        (a_neg_inf_v  and b_pos_norm_v) or -- -inf    * +norm
        (a_neg_norm_v and b_pos_inf_v)  or -- -norm   * +inf
        (a_pos_inf_v  and b_neg_norm_v) or -- +inf    * -norm
        (a_pos_subn_v and b_neg_inf_v)  or -- +denorm * -inf
        (a_neg_inf_v  and b_pos_subn_v) or -- -inf    * +de-norm
        (a_neg_subn_v and b_pos_inf_v)  or -- -denorm * +inf
        (a_pos_inf_v  and b_neg_subn_v);   -- +inf    * -de-norm

      -- +zero --
      multiplier.res_class(fp_class_pos_zero_c) <=
        (a_pos_zero_v and b_pos_zero_v) or -- +zero   * +zero
        (a_pos_zero_v and b_pos_norm_v) or -- +zero   * +norm
        (a_pos_zero_v and b_pos_subn_v) or -- +zero   * +denorm
        (a_neg_zero_v and b_neg_zero_v) or -- -zero   * -zero
        (a_neg_zero_v and b_neg_norm_v) or -- -zero   * -norm
        (a_neg_zero_v and b_neg_subn_v) or -- -zero   * -denorm
        (a_pos_norm_v and b_pos_zero_v) or -- +norm   * +zero
        (a_pos_subn_v and b_pos_zero_v) or -- +denorm * +zero
        (a_neg_norm_v and b_neg_zero_v) or -- -norm   * -zero
        (a_neg_subn_v and b_neg_zero_v);   -- -denorm * -zero

      -- -zero --
      multiplier.res_class(fp_class_neg_zero_c) <=
        (a_pos_zero_v and b_neg_zero_v) or -- +zero   * -zero
        (a_pos_zero_v and b_neg_norm_v) or -- +zero   * -norm
        (a_pos_zero_v and b_neg_subn_v) or -- +zero   * -denorm
        (a_neg_zero_v and b_pos_zero_v) or -- -zero   * +zero
        (a_neg_zero_v and b_pos_norm_v) or -- -zero   * +norm
        (a_neg_zero_v and b_pos_subn_v) or -- -zero   * +denorm
        (a_neg_norm_v and b_pos_zero_v) or -- -norm   * +zero
        (a_neg_subn_v and b_pos_zero_v) or -- -denorm * +zero
        (a_pos_norm_v and b_neg_zero_v) or -- +norm   * -zero
        (a_pos_subn_v and b_neg_zero_v);   -- +denorm * -zero

      -- sNaN --
      multiplier.res_class(fp_class_snan_c) <= (a_snan_v or b_snan_v); -- any input is sNaN
      -- qNaN --
      multiplier.res_class(fp_class_qnan_c) <=
        (a_snan_v or b_snan_v) or -- any input is sNaN
        (a_qnan_v or b_qnan_v) or -- nay input is qNaN
        ((a_pos_inf_v  or a_neg_inf_v)  and (b_pos_zero_v or b_neg_zero_v)) or -- +/-inf * +/-zero
        ((a_pos_zero_v or a_neg_zero_v) and (b_pos_inf_v  or b_neg_inf_v));    -- +/-zero * +/-inf

      -- subnormal result --
      multiplier.res_class(fp_class_pos_denorm_c) <= '0'; -- is evaluated by the normalizer
      multiplier.res_class(fp_class_neg_denorm_c) <= '0'; -- is evaluated by the normalizer
    end if;
  end process multiplier_class_core;

  -- unused --
  fu_mul.result <= (others => '0');
  fu_mul.flags  <= (others => '0');


  -- Adder/Subtractor Core (FADD, FSUB) -----------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  adder_subtractor_core: process(clk_i)
  begin
    if rising_edge(clk_i) then
      -- arbitration / latency --
      if (ctrl_engine.state = S_IDLE) then -- hacky "reset"
        addsub.latency <= (others => '0');
      else
        addsub.latency(0) <= addsub.start; -- input comparator delay
        if (addsub.latency(0) = '1') then
          addsub.latency(1) <= '1';
          addsub.latency(2) <= '0';
        elsif (addsub.exp_cnt(7 downto 0) = addsub.large_exp) then -- radix point not yet aligned
          addsub.latency(1) <= '0';
          addsub.latency(2) <= addsub.latency(1) and (not addsub.latency(0)); -- "shift done"
        end if;
        addsub.latency(3) <= addsub.latency(2); -- adder stage
        addsub.latency(4) <= addsub.latency(3); -- final stage
      end if;

      -- exponent check: find smaller number (radix-offset-only) --
      if (unsigned(fpu_operands.rs1(30 downto 23)) < unsigned(fpu_operands.rs2(30 downto 23))) then
        addsub.exp_comp(0) <= '1'; -- rs1 < rs2
      else
        addsub.exp_comp(0) <= '0'; -- rs1 >= rs2
      end if;
      if (unsigned(fpu_operands.rs1(30 downto 23)) = unsigned(fpu_operands.rs2(30 downto 23))) then
        addsub.exp_comp(1) <= '1'; -- rs1 == rs2
      else -- rs1 != rs2
        addsub.exp_comp(1) <= '0';
      end if;

      -- shift right small mantissa to align radix point --
      if (addsub.latency(0) = '1') then
        if ((fpu_operands.rs1_class(fp_class_pos_zero_c) or fpu_operands.rs2_class(fp_class_pos_zero_c) or
             fpu_operands.rs1_class(fp_class_neg_zero_c) or fpu_operands.rs2_class(fp_class_neg_zero_c)) = '0') then -- no input is zero
          addsub.man_sreg <= addsub.small_man;
        else
          addsub.man_sreg <= (others => '0');
        end if;
        addsub.exp_cnt   <= '0' & addsub.small_exp;
        addsub.man_g_ext <= '0';
        addsub.man_r_ext <= '0';
        addsub.man_s_ext <= '0';
      elsif (addsub.exp_cnt(7 downto 0) /= addsub.large_exp) then -- shift right until same magnitude
        -- Trip: Exponent difference larger than mantissa width + 3
        -- When the difference between large_exp - small_exp is larger than 27
        -- the normalizer will always shift the smaller mantissa to 0.
        -- Catch: Set the smaller mantissa to 0 and the s_ext to '1' end go to next step.
        -- Note: The comparison is 24 mantissa bits 1.23 + 3 underflow bits.
        -- The +3 is to account for the grs underflow bits, could be set to +2 as we are always setting s to 1
        if (unsigned(addsub.large_exp(7 downto 0)) - unsigned(addsub.small_exp(7 downto 0))) > 27 then
          addsub.man_sreg  <= (others => '0');
          addsub.man_g_ext <= '0';
          addsub.man_r_ext <= '0';
          -- set s_ext to 1 as it will always be 1 from the implied 1 being shifted out.
          addsub.man_s_ext <= '1';
          addsub.exp_cnt(7 downto 0) <= addsub.large_exp(7 downto 0);
        else
          addsub.man_sreg  <= '0' & addsub.man_sreg(addsub.man_sreg'left downto 1);
          addsub.man_g_ext <= addsub.man_sreg(0);
          addsub.man_r_ext <= addsub.man_g_ext;
          addsub.man_s_ext <= addsub.man_s_ext or addsub.man_r_ext; -- sticky bit
          addsub.exp_cnt   <= std_ulogic_vector(unsigned(addsub.exp_cnt) + 1);
        end if;
      end if;

      -- mantissa check: find smaller number (magnitude-only) --
      if (unsigned(addsub.man_sreg) <= unsigned(addsub.large_man)) then
        addsub.man_comp <= '1';
      else
        addsub.man_comp <= '0';
      end if;

      -- actual addition/subtraction (incl. overflow) --
      if ((ctrl_i.ir_funct12(7) xor (fpu_operands.rs1(31) xor fpu_operands.rs2(31))) = '0') then -- add
        addsub.add_stage <= std_ulogic_vector(unsigned('0' & addsub.man_l) + unsigned('0' & addsub.man_s));
      else -- sub
        addsub.add_stage <= std_ulogic_vector(unsigned('0' & addsub.man_l) - unsigned('0' & addsub.man_s));
      end if;

      -- result sign --
      if (ctrl_i.ir_funct12(7) = '0') then -- add
        if (fpu_operands.rs1(31) = fpu_operands.rs2(31)) then -- identical signs
          addsub.res_sign <= fpu_operands.rs1(31);
        else -- different signs
          if (addsub.exp_comp(1) = '1') then -- exp are equal (also check relation of mantissas)
            addsub.res_sign <= fpu_operands.rs1(31) xor (not addsub.man_comp);
          else
            addsub.res_sign <= fpu_operands.rs1(31) xor addsub.exp_comp(0);
          end if;
        end if;
      else -- sub
        if (fpu_operands.rs1(31) = fpu_operands.rs2(31)) then -- identical signs
          if (addsub.exp_comp(1) = '1') then -- exp are equal (also check relation of mantissas)
            addsub.res_sign <= fpu_operands.rs1(31) xor (not addsub.man_comp);
          else
            addsub.res_sign <= fpu_operands.rs1(31) xor addsub.exp_comp(0);
          end if;
        else -- different signs
          addsub.res_sign <= fpu_operands.rs1(31);
        end if;
      end if;

      -- exception flags --
      addsub.flags(fp_exc_nv_c) <= ((fpu_operands.rs1_class(fp_class_pos_inf_c) or fpu_operands.rs1_class(fp_class_neg_inf_c)) and
                                    (fpu_operands.rs2_class(fp_class_pos_inf_c) or fpu_operands.rs2_class(fp_class_neg_inf_c))); -- +/-inf +/- +/-inf
    end if;
  end process adder_subtractor_core;

  -- exceptions - unused --
  addsub.flags(fp_exc_dz_c) <= '0'; -- division by zero -> not possible
  addsub.flags(fp_exc_of_c) <= '0'; -- not possible here (but may occur in normalizer)
  addsub.flags(fp_exc_uf_c) <= '0'; -- not possible here (but may occur in normalizer)
  addsub.flags(fp_exc_nx_c) <= '0'; -- not possible here (but may occur in normalizer)

  -- exponent check: find smaller number (magnitude-only) --
  addsub.small_exp <=        fpu_operands.rs1(30 downto 23)  when (addsub.exp_comp(0) = '1') else        fpu_operands.rs2(30 downto 23);
  addsub.large_exp <=        fpu_operands.rs2(30 downto 23)  when (addsub.exp_comp(0) = '1') else        fpu_operands.rs1(30 downto 23);
  addsub.small_man <= ('1' & fpu_operands.rs1(22 downto 00)) when (addsub.exp_comp(0) = '1') else ('1' & fpu_operands.rs2(22 downto 00));
  addsub.large_man <= ('1' & fpu_operands.rs2(22 downto 00)) when (addsub.exp_comp(0) = '1') else ('1' & fpu_operands.rs1(22 downto 00));

  -- mantissa check: find smaller number (magnitude-only) --
  addsub.man_s <= (addsub.man_sreg & addsub.man_g_ext & addsub.man_r_ext & addsub.man_s_ext) when (addsub.man_comp = '1') else (addsub.large_man & "000");
  addsub.man_l <= (addsub.large_man & "000") when (addsub.man_comp = '1') else (addsub.man_sreg & addsub.man_g_ext & addsub.man_r_ext & addsub.man_s_ext);

  -- latency --
  addsub.start   <= fu_addsub.start;
  addsub.done    <= addsub.latency(addsub.latency'left);
  fu_addsub.done <= addsub.done;

  -- mantissa result --
  addsub.res_sum <= addsub.add_stage(27 downto 0);


  -- result class --
  adder_subtractor_class_core: process(clk_i)
    variable a_pos_norm_v, a_neg_norm_v, b_pos_norm_v, b_neg_norm_v : std_ulogic;
    variable a_pos_subn_v, a_neg_subn_v, b_pos_subn_v, b_neg_subn_v : std_ulogic;
    variable a_pos_zero_v, a_neg_zero_v, b_pos_zero_v, b_neg_zero_v : std_ulogic;
    variable a_pos_inf_v,  a_neg_inf_v,  b_pos_inf_v,  b_neg_inf_v  : std_ulogic;
    variable a_snan_v,     a_qnan_v,     b_snan_v,     b_qnan_v     : std_ulogic;
  begin
    if rising_edge(clk_i) then
      -- minions --
      a_pos_norm_v := fpu_operands.rs1_class(fp_class_pos_norm_c);    b_pos_norm_v := fpu_operands.rs2_class(fp_class_pos_norm_c);
      a_neg_norm_v := fpu_operands.rs1_class(fp_class_neg_norm_c);    b_neg_norm_v := fpu_operands.rs2_class(fp_class_neg_norm_c);
      a_pos_subn_v := fpu_operands.rs1_class(fp_class_pos_denorm_c);  b_pos_subn_v := fpu_operands.rs2_class(fp_class_pos_denorm_c);
      a_neg_subn_v := fpu_operands.rs1_class(fp_class_neg_denorm_c);  b_neg_subn_v := fpu_operands.rs2_class(fp_class_neg_denorm_c);
      a_pos_zero_v := fpu_operands.rs1_class(fp_class_pos_zero_c);    b_pos_zero_v := fpu_operands.rs2_class(fp_class_pos_zero_c);
      a_neg_zero_v := fpu_operands.rs1_class(fp_class_neg_zero_c);    b_neg_zero_v := fpu_operands.rs2_class(fp_class_neg_zero_c);
      a_pos_inf_v  := fpu_operands.rs1_class(fp_class_pos_inf_c);     b_pos_inf_v  := fpu_operands.rs2_class(fp_class_pos_inf_c);
      a_neg_inf_v  := fpu_operands.rs1_class(fp_class_neg_inf_c);     b_neg_inf_v  := fpu_operands.rs2_class(fp_class_neg_inf_c);
      a_snan_v     := fpu_operands.rs1_class(fp_class_snan_c);        b_snan_v     := fpu_operands.rs2_class(fp_class_snan_c);
      a_qnan_v     := fpu_operands.rs1_class(fp_class_qnan_c);        b_qnan_v     := fpu_operands.rs2_class(fp_class_qnan_c);

      if (ctrl_i.ir_funct12(7) = '0') then -- addition
        -- +infinity --
        addsub.res_class(fp_class_pos_inf_c) <=
          (a_pos_inf_v  and b_pos_inf_v)  or -- +inf    + +inf
          (a_pos_inf_v  and b_pos_zero_v) or -- +inf    + +zero
          (a_pos_zero_v and b_pos_inf_v)  or -- +zero   + +inf
          (a_pos_inf_v  and b_neg_zero_v) or -- +inf    + -zero
          (a_neg_zero_v and b_pos_inf_v)  or -- -zero   + +inf
          --
          (a_pos_inf_v  and b_pos_norm_v) or -- +inf    + +norm
          (a_pos_norm_v and b_pos_inf_v)  or -- +norm   + +inf
          (a_pos_inf_v  and b_pos_subn_v) or -- +inf    + +denorm
          (a_pos_subn_v and b_pos_inf_v)  or -- +denorm + +inf
          --
          (a_pos_inf_v  and b_neg_norm_v) or -- +inf    + -norm
          (a_neg_norm_v and b_pos_inf_v)  or -- -norm   + +inf
          (a_pos_inf_v  and b_neg_subn_v) or -- +inf    + -denorm
          (a_neg_subn_v and b_pos_inf_v);    -- -denorm + +inf
        -- -infinity --
        addsub.res_class(fp_class_neg_inf_c) <=
          (a_neg_inf_v  and b_neg_inf_v)  or -- -inf    + -inf
          (a_neg_inf_v  and b_pos_zero_v) or -- -inf    + +zero
          (a_pos_zero_v and b_neg_inf_v)  or -- +zero   + -inf
          (a_neg_inf_v  and b_neg_zero_v) or -- -inf    + -zero
          (a_neg_zero_v and b_neg_inf_v)  or -- -zero   + -inf
          --
          (a_neg_inf_v  and b_pos_norm_v) or -- -inf    + +norm
          (a_pos_norm_v and b_neg_inf_v)  or -- +norm   + -inf
          (a_neg_inf_v  and b_neg_norm_v) or -- -inf    + -norm
          (a_neg_norm_v and b_neg_inf_v)  or -- -norm   + -inf
          --
          (a_neg_inf_v  and b_pos_subn_v) or -- -inf    + +denorm
          (a_pos_subn_v and b_neg_inf_v)  or -- +denorm + -inf
          (a_neg_inf_v  and b_neg_subn_v) or -- -inf    + -denorm
          (a_neg_subn_v and b_neg_inf_v);    -- -denorm + -inf

        -- +zero --
        addsub.res_class(fp_class_pos_zero_c) <=
          (a_pos_zero_v and b_pos_zero_v) or -- +zero + +zero
          (a_pos_zero_v and b_neg_zero_v) or -- +zero + -zero
          (a_neg_zero_v and b_pos_zero_v);   -- -zero + +zero
        -- -zero --
        addsub.res_class(fp_class_neg_zero_c) <=
          (a_neg_zero_v and b_neg_zero_v);   -- -zero + -zero

        -- qNaN --
        addsub.res_class(fp_class_qnan_c) <=
          (a_snan_v    or  b_snan_v)    or -- any input is sNaN
          (a_qnan_v    or  b_qnan_v)    or -- any input is qNaN
          (a_pos_inf_v and b_neg_inf_v) or -- +inf + -inf
          (a_neg_inf_v and b_pos_inf_v);   -- -inf + +inf

      else -- subtraction
        -- +infinity --
        addsub.res_class(fp_class_pos_inf_c) <=
          (a_pos_inf_v  and b_neg_inf_v)  or -- +inf    - -inf
          (a_pos_inf_v  and b_pos_zero_v) or -- +inf    - +zero
          (a_pos_inf_v  and b_neg_zero_v) or -- +inf    - -zero
          (a_pos_inf_v  and b_pos_norm_v) or -- +inf    - +norm
          (a_pos_inf_v  and b_pos_subn_v) or -- +inf    - +denorm
          (a_pos_inf_v  and b_neg_norm_v) or -- +inf    - -norm
          (a_pos_inf_v  and b_neg_subn_v) or -- +inf    - -denorm
          --
          (a_pos_zero_v and b_neg_inf_v)  or -- +zero   - -inf
          (a_neg_zero_v and b_neg_inf_v)  or -- -zero   - -inf
          --
          (a_pos_norm_v and b_neg_inf_v)  or -- +norm   - -inf
          (a_pos_subn_v and b_neg_inf_v)  or -- +denorm - -inf
          (a_neg_norm_v and b_neg_inf_v)  or -- -norm   - -inf
          (a_neg_subn_v and b_neg_inf_v);    -- -denorm - -inf
        -- -infinity --
        addsub.res_class(fp_class_neg_inf_c) <=
          (a_neg_inf_v  and b_pos_inf_v)  or -- -inf    - +inf
          (a_neg_inf_v  and b_pos_zero_v) or -- -inf    - +zero
          (a_neg_inf_v  and b_neg_zero_v) or -- -inf    - -zero
          (a_neg_inf_v  and b_pos_norm_v) or -- -inf    - +norm
          (a_neg_inf_v  and b_pos_subn_v) or -- -inf    - +denorm
          (a_neg_inf_v  and b_neg_norm_v) or -- -inf    - -norm
          (a_neg_inf_v  and b_neg_subn_v) or -- -inf    - -denorm
          --
          (a_pos_zero_v and b_pos_inf_v)  or -- +zero   - +inf
          (a_neg_zero_v and b_pos_inf_v)  or -- -zero   - +inf
          --
          (a_pos_norm_v and b_pos_inf_v)  or -- +norm   - +inf
          (a_pos_subn_v and b_pos_inf_v)  or -- +denorm - +inf
          (a_neg_norm_v and b_pos_inf_v)  or -- -norm   - +inf
          (a_neg_subn_v and b_pos_inf_v);    -- -denorm - +inf

        -- +zero --
        addsub.res_class(fp_class_pos_zero_c) <=
          (a_pos_zero_v and b_pos_zero_v) or -- +zero - +zero
          (a_pos_zero_v and b_neg_zero_v) or -- +zero - -zero
          (a_neg_zero_v and b_neg_zero_v);   -- -zero - -zero
        -- -zero --
        addsub.res_class(fp_class_neg_zero_c) <=
          (a_neg_zero_v and b_pos_zero_v);   -- -zero - +zero

        -- qNaN --
        addsub.res_class(fp_class_qnan_c) <=
          (a_snan_v    or  b_snan_v)    or -- any input is sNaN
          (a_qnan_v    or  b_qnan_v)    or -- any input is qNaN
          (a_pos_inf_v and b_pos_inf_v) or -- +inf - +inf
          (a_neg_inf_v and b_neg_inf_v);   -- -inf - -inf
      end if;

      -- normal --
      addsub.res_class(fp_class_pos_norm_c) <= (a_pos_norm_v or a_neg_norm_v) and (b_pos_norm_v or b_neg_norm_v); -- +/-norm +/- +-/norm [sign is irrelevant here]
      addsub.res_class(fp_class_neg_norm_c) <= (a_pos_norm_v or a_neg_norm_v) and (b_pos_norm_v or b_neg_norm_v); -- +/-norm +/- +-/norm [sign is irrelevant here]

      -- sNaN --
      addsub.res_class(fp_class_snan_c) <= (a_snan_v or b_snan_v); -- any input is sNaN

      -- subnormal result --
      addsub.res_class(fp_class_pos_denorm_c) <= '0'; -- is evaluated by the normalizer
      addsub.res_class(fp_class_neg_denorm_c) <= '0'; -- is evaluated by the normalizer
    end if;
  end process adder_subtractor_class_core;

  -- unused --
  fu_addsub.result <= (others => '0');
  fu_addsub.flags  <= (others => '0');


-- ****************************************************************************************************************************
-- FPU Core - Normalize & Round
-- ****************************************************************************************************************************

  -- Normalizer Input -----------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  normalizer_input_select: process(funct_ff, addsub, multiplier, fu_conv_i2f)
  begin
    case funct_ff is
      when op_addsub_c => -- addition/subtraction
        normalizer.mode      <= '0'; -- normalization
        normalizer.sign      <= addsub.res_sign;
        normalizer.xexp      <= addsub.exp_cnt;
        normalizer.xmantissa(47 downto 23) <= addsub.res_sum(27 downto 3);
        normalizer.xmantissa(22) <= addsub.res_sum(2);
        normalizer.xmantissa(21) <= addsub.res_sum(1);
        normalizer.xmantissa(20 downto 01) <= (others => '0');
        normalizer.xmantissa(00) <= addsub.res_sum(0);
        normalizer.class     <= addsub.res_class;
        normalizer.flags_in  <= addsub.flags;
        normalizer.start     <= addsub.done;
      when op_mul_c => -- multiplication
        normalizer.mode      <= '0'; -- normalization
        normalizer.sign      <= multiplier.sign;
        normalizer.xexp      <= '0' & multiplier.exp_res(7 downto 0);
        normalizer.xmantissa <= multiplier.product;
        normalizer.class     <= multiplier.res_class;
        normalizer.flags_in  <= multiplier.flags;
        normalizer.start     <= multiplier.done;
      when others => -- op_i2f_c
        normalizer.mode      <= '1'; -- int_to_float
        normalizer.sign      <= fu_conv_i2f.sign;
        normalizer.xexp      <= "001111111"; -- bias = 127
        normalizer.xmantissa <= (others => '0'); -- don't care
        normalizer.class     <= (others => '0'); -- don't care
        normalizer.flags_in  <= (others => '0'); -- no flags yet
        normalizer.start     <= fu_conv_i2f.done;
    end case;
  end process normalizer_input_select;


  -- Normalizer & Rounding Unit -------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  neorv32_cpu_cp_fpu_normalizer_inst: neorv32_cpu_cp_fpu_normalizer
  port map (
    -- control --
    clk_i      => clk_i,                -- global clock, rising edge
    rstn_i     => rstn_i,               -- global reset, low-active, async
    start_i    => normalizer.start,     -- trigger operation
    abort_i    => ctrl_i.cpu_trap,      -- abort current operation
    rmode_i    => fpu_operands.frm,     -- rounding mode
    funct_i    => normalizer.mode,      -- operation mode
    -- input --
    sign_i     => normalizer.sign,      -- sign
    exponent_i => normalizer.xexp,      -- extended exponent
    mantissa_i => normalizer.xmantissa, -- extended mantissa
    integer_i  => fu_conv_i2f.result,   -- integer input
    class_i    => normalizer.class,     -- input number class
    flags_i    => normalizer.flags_in,  -- exception flags input
    -- output --
    result_o   => normalizer.result,    -- result (float or int)
    flags_o    => normalizer.flags_out, -- exception flags
    done_o     => normalizer.done       -- operation done
  );


-- ****************************************************************************************************************************
-- FPU Core - Result
-- ****************************************************************************************************************************

  -- Output Result to CPU Pipeline ----------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  output_gate: process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (ctrl_engine.valid = '1') then
        case funct_ff is
          when op_class_c =>
            res_o  <= fu_classify.result;
            fflags <= fu_classify.flags;
          when op_comp_c =>
            res_o  <= fu_compare.result;
            fflags <= fu_compare.flags;
          when op_f2i_c =>
            res_o  <= fu_conv_f2i.result;
            fflags <= fu_conv_f2i.flags;
          when op_sgnj_c =>
            res_o  <= fu_sign_inject.result;
            fflags <= fu_sign_inject.flags;
          when op_minmax_c =>
            res_o  <= fu_min_max.result;
            fflags <= fu_min_max.flags;
          when others => -- op_mul_c, op_addsub_c, op_i2f_c, ...
            res_o  <= normalizer.result;
            fflags <= normalizer.flags_out;
        end case;
      else
        res_o  <= (others => '0');
        fflags <= (others => '0');
      end if;
    end if;
  end process output_gate;

  -- operation done --
  fu_core_done <= fu_compare.done or fu_classify.done or fu_sign_inject.done or fu_min_max.done or normalizer.done or fu_conv_f2i.done;


end neorv32_cpu_cp_fpu_rtl;