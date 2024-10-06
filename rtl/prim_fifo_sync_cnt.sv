// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Generic synchronous fifo for use in a variety of devices.

`include "prim_assert.sv"

module prim_fifo_sync_cnt #(
  parameter int Depth = 4,
  parameter int Width = 16,
  parameter bit Secure = 1'b0
) (
  input clk_i,
  input rst_ni,
  input clr_i,
  input incr_wptr_i,
  input incr_rptr_i,
  output logic [Width-1:0] wptr_o,
  output logic [Width-1:0] rptr_o,
  output logic err_o
);

  logic wptr_wrap;
  logic [Width-1:0] wptr_wrap_cnt;
  logic rptr_wrap;
  logic [Width-1:0] rptr_wrap_cnt;

  assign wptr_wrap = incr_wptr_i & (wptr_o[Width-2:0] == unsigned'((Width-1)'(Depth-1)));
  assign rptr_wrap = incr_rptr_i & (rptr_o[Width-2:0] == unsigned'((Width-1)'(Depth-1)));

  assign wptr_wrap_cnt = {~wptr_o[Width-1],{(Width-1){1'b0}}};
  assign rptr_wrap_cnt = {~rptr_o[Width-1],{(Width-1){1'b0}}};

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      wptr_o <= {(Width){1'b0}};
    end else if (clr_i) begin
      wptr_o <= {(Width){1'b0}};
    end else if (wptr_wrap) begin
      wptr_o <= wptr_wrap_cnt;
    end else if (incr_wptr_i) begin
      wptr_o <= wptr_o + {{(Width-1){1'b0}},1'b1};
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rptr_o <= {(Width){1'b0}};
    end else if (clr_i) begin
      rptr_o <= {(Width){1'b0}};
    end else if (rptr_wrap) begin
        rptr_o <= rptr_wrap_cnt;
    end else if (incr_rptr_i) begin
        rptr_o <= rptr_o + {{(Width-1){1'b0}},1'b1};
    end
  end

  assign err_o = '0;

endmodule // prim_fifo_sync_cnt