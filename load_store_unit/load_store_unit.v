module load_store_unit (
  input           CLK,
  input           RST_N,

  // data mem interface
  output reg      data_req_o,
  input           data_gnt_i,
  input           data_rvalid_i,
  input           data_bus_err_i,
  //input           data_pmp_err_i,  //=0

  output  [31:0]  data_addr_o,
  output          data_we_o,
  output  [3:0]   data_be_o,
  output  [31:0]  data_wdata_o,
  output  [6:0]   data_wdata_intg_o,
  input   [31:0]  data_rdata_i,
  input   [6:0]   data_rdata_intg_i,

  // signals to/from ID/EX stage

  //input           lsu_we_i,           // write enable                     -> from ID/EX
  //input   [1:0]   lsu_type_i,         // data type: word, half word, byte -> from ID/EX
  input   [3:0]   READ_WRITE,
  input   [31:0]  lsu_wdata_i,          // data to write to memory          -> from ID/EX
  //input           lsu_sign_ext_i,     // sign extension                   -> from ID/EX

  output  [31:0]  lsu_rdata_o,          // requested data                   -> to ID/EX
  output          lsu_rdata_valid_o,
  //input           lsu_req_i,          // data request                     -> from ID/EX

  input   [31:0]  adder_result_ex_i,    // address computed in ALU          -> from ID/EX

  output reg      addr_incr_req_o,      // request address increment for
                                        // misaligned accesses              -> to ID/EX
  output  [31:0]  addr_last_o,          // address of last transaction      -> to controller
                                        // -> mtval
                                        // -> AGU for misaligned accesses

  output          lsu_req_done_o,       // Signals that data request is complete
                                        // (only need to await final data
                                        // response)                        -> to ID/EX

  output          lsu_resp_valid_o,     // LSU has response from transaction -> to ID/EX

  // exception signals
  output          load_err_o,
  output          load_resp_intg_err_o,  //=0
  output          store_err_o,
  output          store_resp_intg_err_o, //=0

  output          busy_o,

  output reg      perf_load_o,
  output reg      perf_store_o
);

  wire [31:0]  data_addr;
  wire [31:0]  data_addr_w_aligned;
  reg  [31:0]  addr_last_q, addr_last_d;

  reg          addr_update;
  reg          ctrl_update;
  reg          rdata_update;
  reg  [23:0]  rdata_q;
  reg  [1:0]   rdata_offset_q;
  reg  [1:0]   data_type_q;
  reg          data_sign_ext_q;
  reg          data_we_q;

  wire [1:0]   data_offset;   // mux control for data to be written to memory

  reg  [3:0]   data_be;
  reg  [31:0]  data_wdata;

  reg  [31:0]  data_rdata_ext;

  reg  [31:0]  rdata_w_ext; // word realignment for misaligned loads
  reg  [31:0]  rdata_h_ext; // sign extension for half words
  reg  [31:0]  rdata_b_ext; // sign extension for bytes

  wire         split_misaligned_access;
  reg          handle_misaligned_q, handle_misaligned_d; // high after receiving grant for first
                                                         // part of a misaligned access
  //reg          pmp_err_q, pmp_err_d;
  reg          lsu_err_q, lsu_err_d;
  wire         data_intg_err, data_err;
  wire [6:0]   unused_intg_i;    

  wire lsu_we_i;
  wire [1:0] lsu_type_i;
  wire lsu_sign_ext_i;
  wire lsu_req_i;
  wire LB, LH, LW, LBU, LHU, SB, SH, SW;

  assign LB = READ_WRITE[3] & !READ_WRITE[2] & !READ_WRITE[1] & !READ_WRITE[0];
  assign LH = READ_WRITE[3] & !READ_WRITE[2] & !READ_WRITE[1] & READ_WRITE[0];
  assign LW = READ_WRITE[3] & !READ_WRITE[2] & READ_WRITE[1] & !READ_WRITE[0];
  assign LBU = READ_WRITE[3] & READ_WRITE[2] & !READ_WRITE[1] & !READ_WRITE[0];
  assign LHU = READ_WRITE[3] & READ_WRITE[2] & !READ_WRITE[1] & READ_WRITE[0];

  assign SB = READ_WRITE[3] & !READ_WRITE[2] & READ_WRITE[1] & READ_WRITE[0];
  assign SH = READ_WRITE[3] & READ_WRITE[2] & READ_WRITE[1] & !READ_WRITE[0];
  assign SW = READ_WRITE[3] & READ_WRITE[2] & READ_WRITE[1] & READ_WRITE[0];

  assign lsu_we_i = (SB | SH | SW);
  assign lsu_type_i = (LW || SW) ? 2'b00 : 
                      (LH || LHU || SH) ? 2'b01 :
                      (LB || LBU || SB) ? 2'b10 : 2'b11;
  assign lsu_sign_ext_i = (LBU || LHU) ? 0 : 1;
  assign lsu_req_i = (LB | LH | LW | LBU | LHU | SB | SH | SW);

  assign unused_intg_i = data_rdata_intg_i;

  assign data_addr   = adder_result_ex_i;
  assign data_offset = data_addr[1:0];

  ///////////////////
  // BE generation //
  ///////////////////

  always @(READ_WRITE, handle_misaligned_q, data_offset) begin
    case (READ_WRITE) 
      4'b1010, 4'b1111: begin           // WORD
        if (!handle_misaligned_q) begin // first part of potentially misaligned transaction
          case (data_offset)
            2'b00:   data_be = 4'b1111;
            2'b01:   data_be = 4'b1110;
            2'b10:   data_be = 4'b1100;
            2'b11:   data_be = 4'b1000;
            default: data_be = 4'b1111;
          endcase
        end else begin // second part of misaligned transaction
          case (data_offset)
            2'b00:   data_be = 4'b0000; // this is not used, but included for completeness
            2'b01:   data_be = 4'b0001;
            2'b10:   data_be = 4'b0011;
            2'b11:   data_be = 4'b0111;
            default: data_be = 4'b1111;
          endcase
        end
      end

      4'b1001, 4'b1101, 4'b1110: begin  // HAFL WORD
        if (!handle_misaligned_q) begin // first part of potentially misaligned transaction
          case (data_offset)
            2'b00:   data_be = 4'b0011;
            2'b01:   data_be = 4'b0110;
            2'b10:   data_be = 4'b1100;
            2'b11:   data_be = 4'b1000;
            default: data_be = 4'b1111;
          endcase 
        end else begin // second part of misaligned transaction
          data_be = 4'b0001;
        end
      end

      4'b1000, 4'b1100, 4'b1011: begin // BYTE
        case (data_offset)
          2'b00:   data_be = 4'b0001;
          2'b01:   data_be = 4'b0010;
          2'b10:   data_be = 4'b0100;
          2'b11:   data_be = 4'b1000;
          default: data_be = 4'b1111;
        endcase
      end

      default:     data_be = 4'b1111;
    endcase
  end

  /////////////////////
  // WData alignment //
  /////////////////////

  // prepare data to be written to the memory
  // we handle misaligned accesses, half word and byte accesses here
  always @(data_offset, lsu_wdata_i) begin
    case (data_offset)
      2'b00:   data_wdata =  lsu_wdata_i[31:0];
      2'b01:   data_wdata = {lsu_wdata_i[23:0], lsu_wdata_i[31:24]};
      2'b10:   data_wdata = {lsu_wdata_i[15:0], lsu_wdata_i[31:16]};
      2'b11:   data_wdata = {lsu_wdata_i[7:0], lsu_wdata_i[31:8]};
      default: data_wdata =  lsu_wdata_i[31:0];
    endcase
  end

  /////////////////////
  // RData alignment //
  /////////////////////

  // register for unaligned rdata
  always @(posedge CLK or negedge RST_N) begin
    if (!RST_N) begin
      rdata_q <= 24'b0;
    end else if (rdata_update) begin
      rdata_q <= data_rdata_i[31:8];
    end
  end

  // registers for transaction control
  always @(posedge CLK or negedge RST_N) begin
    if (!RST_N) begin
      rdata_offset_q  <= 2'h0;
      data_type_q     <= 2'h0;
      data_sign_ext_q <= 1'b0;
      data_we_q       <= 1'b0;
    end else if (ctrl_update) begin
      rdata_offset_q  <= data_offset;
      data_type_q     <= lsu_type_i;
      data_sign_ext_q <= lsu_sign_ext_i;
      data_we_q       <= lsu_we_i;
    end
  end

  // Store last address for mtval + AGU for misaligned transactions.  Do not update in case of
  // errors, mtval needs the (first) failing address.  Where an aligned access or the first half of
  // a misaligned access sees an error provide the calculated access address. For the second half of
  // a misaligned access provide the word aligned address of the second half.
  assign addr_last_d = addr_incr_req_o ? data_addr_w_aligned : data_addr;

  always @(posedge CLK or negedge RST_N) begin
    if (!RST_N) begin
      addr_last_q <= 32'b0;
    end else if (addr_update) begin
      addr_last_q <= addr_last_d;
    end
  end

  // take care of misaligned words
  always @(rdata_offset_q, data_rdata_i, rdata_q) begin
    case (rdata_offset_q)
      2'b00:   rdata_w_ext =  data_rdata_i[31:0];
      2'b01:   rdata_w_ext = {data_rdata_i[7:0], rdata_q[31:8]};
      2'b10:   rdata_w_ext = {data_rdata_i[15:0], rdata_q[31:16]};
      2'b11:   rdata_w_ext = {data_rdata_i[23:0], rdata_q[31:24]};
      default: rdata_w_ext =  data_rdata_i[31:0];
    endcase
  end

  ////////////////////
  // Sign extension //
  ////////////////////

  // sign extension for half words
  always @(rdata_offset_q, data_sign_ext_q, data_rdata_i, rdata_q) begin
    case (rdata_offset_q)
      2'b00: begin
        if (!data_sign_ext_q) begin
          rdata_h_ext = {16'h0000, data_rdata_i[15:0]};
        end else begin
          rdata_h_ext = {{16{data_rdata_i[15]}}, data_rdata_i[15:0]};
        end
      end

      2'b01: begin
        if (!data_sign_ext_q) begin
          rdata_h_ext = {16'h0000, data_rdata_i[23:8]};
        end else begin
          rdata_h_ext = {{16{data_rdata_i[23]}}, data_rdata_i[23:8]};
        end
      end

      2'b10: begin
        if (!data_sign_ext_q) begin
          rdata_h_ext = {16'h0000, data_rdata_i[31:16]};
        end else begin
          rdata_h_ext = {{16{data_rdata_i[31]}}, data_rdata_i[31:16]};
        end
      end

      2'b11: begin
        if (!data_sign_ext_q) begin
          rdata_h_ext = {16'h0000, data_rdata_i[7:0], rdata_q[31:24]};
        end else begin
          rdata_h_ext = {{16{data_rdata_i[7]}}, data_rdata_i[7:0], rdata_q[31:24]};
        end
      end

      default: rdata_h_ext = {16'h0000, data_rdata_i[15:0]};
    endcase
  end

  // sign extension for bytes
  always @(rdata_offset_q, data_sign_ext_q, data_rdata_i) begin
    case (rdata_offset_q)
      2'b00: begin
        if (!data_sign_ext_q) begin
          rdata_b_ext = {24'h00_0000, data_rdata_i[7:0]};
        end else begin
          rdata_b_ext = {{24{data_rdata_i[7]}}, data_rdata_i[7:0]};
        end
      end

      2'b01: begin
        if (!data_sign_ext_q) begin
          rdata_b_ext = {24'h00_0000, data_rdata_i[15:8]};
        end else begin
          rdata_b_ext = {{24{data_rdata_i[15]}}, data_rdata_i[15:8]};
        end
      end

      2'b10: begin
        if (!data_sign_ext_q) begin
          rdata_b_ext = {24'h00_0000, data_rdata_i[23:16]};
        end else begin
          rdata_b_ext = {{24{data_rdata_i[23]}}, data_rdata_i[23:16]};
        end
      end

      2'b11: begin
        if (!data_sign_ext_q) begin
          rdata_b_ext = {24'h00_0000, data_rdata_i[31:24]};
        end else begin
          rdata_b_ext = {{24{data_rdata_i[31]}}, data_rdata_i[31:24]};
        end
      end

      default: rdata_b_ext = {24'h00_0000, data_rdata_i[7:0]};
    endcase
  end

  // select word, half word or byte sign extended version
  always @(data_type_q, rdata_w_ext, rdata_h_ext, rdata_b_ext) begin
    case (data_type_q)
      2'b00:       data_rdata_ext = rdata_w_ext;
      2'b01:       data_rdata_ext = rdata_h_ext;
      2'b10:       data_rdata_ext = rdata_b_ext;
      default:     data_rdata_ext = rdata_w_ext;
    endcase
  end

  ///////////////////////////////
  // Read data integrity check //
  ///////////////////////////////
  assign data_intg_err = 1'b0;

  /////////////
  // LSU FSM //
  /////////////

/*  typedef enum logic [2:0]  {
    IDLE, WAIT_GNT_MIS, WAIT_RVALID_MIS, WAIT_GNT,
    WAIT_RVALID_MIS_GNTS_DONE
  } ls_fsm_e;

  ls_fsm_e ls_fsm_cs, ls_fsm_ns;
*/
  parameter [2:0] IDLE = 3'b000, WAIT_GNT_MIS = 3'b001, WAIT_RVALID_MIS = 3'b010, 
                  WAIT_GNT = 3'b011, WAIT_RVALID_MIS_GNTS_DONE = 3'b100;
  reg [2:0] ls_fsm_cs, ls_fsm_ns;

  // check for misaligned accesses that need to be split into two word-aligned accesses
  assign split_misaligned_access =
      ((lsu_type_i == 2'b00) && (data_offset != 2'b00)) || // misaligned word access
      ((lsu_type_i == 2'b01) && (data_offset == 2'b11));   // misaligned half-word access

  // FSM
  always @(ls_fsm_cs, ls_fsm_ns, lsu_req_i, data_gnt_i, data_rvalid_i,
           handle_misaligned_q, lsu_err_q, lsu_we_i, split_misaligned_access, 
           data_bus_err_i, data_we_q) //data_pmp_err_i, pmp_err_q
  begin
    ls_fsm_ns           = ls_fsm_cs;

    data_req_o          = 1'b0;
    addr_incr_req_o     = 1'b0;
    handle_misaligned_d = handle_misaligned_q;
    //pmp_err_d           = pmp_err_q;
    lsu_err_d           = lsu_err_q;

    addr_update         = 1'b0;
    ctrl_update         = 1'b0;
    rdata_update        = 1'b0;

    perf_load_o         = 1'b0;
    perf_store_o        = 1'b0;

    case (ls_fsm_cs)

      IDLE: begin
        //pmp_err_d = 1'b0;
        if (lsu_req_i) begin
          data_req_o   = 1'b1;
          //pmp_err_d    = data_pmp_err_i;
          lsu_err_d    = 1'b0;
          perf_load_o  = ~lsu_we_i;
          perf_store_o = lsu_we_i;

          if (data_gnt_i) begin
            ctrl_update         = 1'b1;
            addr_update         = 1'b1;
            handle_misaligned_d = split_misaligned_access;
            ls_fsm_ns           = split_misaligned_access ? WAIT_RVALID_MIS : IDLE;
          end else begin
            ls_fsm_ns           = split_misaligned_access ? WAIT_GNT_MIS    : WAIT_GNT;
          end
        end
      end

      WAIT_GNT_MIS: begin
        data_req_o = 1'b1;
        // data_pmp_err_i is valid during the address phase of a request. An error will block the
        // external request and so a data_gnt_i might never be signalled. The registered version
        // pmp_err_q is only updated for new address phases and so can be used in WAIT_GNT* and
        // WAIT_RVALID* states
        if (data_gnt_i) begin  // || pmp_err_q
          addr_update         = 1'b1;
          ctrl_update         = 1'b1;
          handle_misaligned_d = 1'b1;
          ls_fsm_ns           = WAIT_RVALID_MIS;
        end
      end

      WAIT_RVALID_MIS: begin
        // push out second request
        data_req_o = 1'b1;
        // tell ID/EX stage to update the address
        addr_incr_req_o = 1'b1;

        // first part rvalid is received, or gets a PMP error
        if (data_rvalid_i) begin  // || pmp_err_q
          // Update the PMP error for the second part
          //pmp_err_d = data_pmp_err_i;
          // Record the error status of the first part
          lsu_err_d = data_bus_err_i;  // | pmp_err_q;
          // Capture the first rdata for loads
          rdata_update = ~data_we_q;
          // If already granted, wait for second rvalid
          ls_fsm_ns = data_gnt_i ? IDLE : WAIT_GNT;
          // Update the address for the second part, if no error
          addr_update = data_gnt_i & ~(data_bus_err_i);  // | pmp_err_q
          // clear handle_misaligned if second request is granted
          handle_misaligned_d = ~data_gnt_i;
        end else begin
          // first part rvalid is NOT received
          if (data_gnt_i) begin
            // second grant is received
            ls_fsm_ns = WAIT_RVALID_MIS_GNTS_DONE;
            handle_misaligned_d = 1'b0;
          end
        end
      end

      WAIT_GNT: begin
        // tell ID/EX stage to update the address
        addr_incr_req_o = handle_misaligned_q;
        data_req_o      = 1'b1;
        if (data_gnt_i) begin  // || pmp_err_q
          ctrl_update         = 1'b1;
          // Update the address, unless there was an error
          addr_update         = ~lsu_err_q;
          ls_fsm_ns           = IDLE;
          handle_misaligned_d = 1'b0;
        end
      end

      WAIT_RVALID_MIS_GNTS_DONE: begin
        // tell ID/EX stage to update the address (to make sure the
        // second address can be captured correctly for mtval and PMP checking)
        addr_incr_req_o = 1'b1;
        // Wait for the first rvalid, second request is already granted
        if (data_rvalid_i) begin
          // Update the pmp error for the second part
          //pmp_err_d = data_pmp_err_i;
          // The first part cannot see a PMP error in this state
          lsu_err_d = data_bus_err_i;
          // Now we can update the address for the second part if no error
          addr_update = ~data_bus_err_i;
          // Capture the first rdata for loads
          rdata_update = ~data_we_q;
          // Wait for second rvalid
          ls_fsm_ns = IDLE;
        end
      end

      default: begin
        ls_fsm_ns = IDLE;
      end
    endcase
  end

  assign lsu_req_done_o = ((ls_fsm_cs != IDLE)) & (ls_fsm_ns == IDLE);

  // registers for FSM
  always @(posedge CLK or negedge RST_N) begin
    if (!RST_N) begin
      ls_fsm_cs           <= IDLE;
      handle_misaligned_q <= '0;
      //pmp_err_q           <= '0;
      lsu_err_q           <= '0;
    end else begin
      ls_fsm_cs           <= ls_fsm_ns;
      handle_misaligned_q <= handle_misaligned_d;
      //pmp_err_q           <= pmp_err_d;
      lsu_err_q           <= lsu_err_d;
    end
  end

  /////////////
  // Outputs //
  /////////////

  assign data_err    = lsu_err_q | data_bus_err_i;  // | pmp_err_q;
  assign lsu_resp_valid_o   = (data_rvalid_i) & (ls_fsm_cs == IDLE);  // | pmp_err_q
  assign lsu_rdata_valid_o  =
    (ls_fsm_cs == IDLE) & data_rvalid_i & ~data_err & ~data_we_q & ~data_intg_err;

  // output to register file
  assign lsu_rdata_o = data_rdata_ext;

  // output data address must be word aligned
  assign data_addr_w_aligned = {data_addr[31:2], 2'b00};

  // output to data interface
  assign data_addr_o   = data_addr_w_aligned;
  assign data_we_o     = lsu_we_i;
  assign data_be_o     = data_be;

  /////////////////////////////////////
  // Write data integrity generation //
  /////////////////////////////////////

  // SEC_CM: BUS.INTEGRITY
  assign data_wdata_o = data_wdata;


  // output to ID stage: mtval + AGU for misaligned transactions
  assign addr_last_o   = addr_last_q;

  // Signal a load or store error depending on the transaction type outstanding
  assign load_err_o      = data_err & ~data_we_q & lsu_resp_valid_o;
  assign store_err_o     = data_err &  data_we_q & lsu_resp_valid_o;
  // Integrity errors are their own category for timing reasons. load_err_o is factored directly
  // into data_req_o to enable synchronous exception on load errors without performance loss (An
  // upcoming load cannot request until the current load has seen its response, so the earliest
  // point the new request can be sent is the same cycle the response is seen). If load_err_o isn't
  // factored into data_req_o there would have to be a stall cycle between all back to back loads.
  // The data_intg_err signal is generated combinatorially from the incoming data_rdata_i. Were it
  // to be factored into load_err_o there would be a feedthrough path from data_rdata_i to
  // data_req_o which is undesirable.
  assign load_resp_intg_err_o  = data_intg_err & data_rvalid_i & ~data_we_q;
  assign store_resp_intg_err_o = data_intg_err & data_rvalid_i & data_we_q;

  assign busy_o = (ls_fsm_cs != IDLE);

endmodule