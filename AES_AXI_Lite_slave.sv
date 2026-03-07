`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2026 03:46:22 AM
// Design Name: 
// Module Name: AES_AXI_Lite_slave
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module AES_AXI_Lite_slave #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 6   // 6 bits covers 0x00 to 0x3C (Word 15)
)(
    // Global Signals
    input  logic                                  S_AXI_ACLK,
    input  logic                                  S_AXI_ARESETN,

    // Write Address Channel (AW)
    input  logic [C_S_AXI_ADDR_WIDTH-1 : 0]       S_AXI_AWADDR,
    //input  logic [2 : 0]                          S_AXI_AWPROT,
    input  logic                                  S_AXI_AWVALID,
    output logic                                  S_AXI_AWREADY,

    // Write Data Channel (W)
    input  logic [C_S_AXI_DATA_WIDTH-1 : 0]       S_AXI_WDATA,
    input  logic [(C_S_AXI_DATA_WIDTH/8)-1 : 0]   S_AXI_WSTRB,
    input  logic                                  S_AXI_WVALID,
    output logic                                  S_AXI_WREADY,

    // Write Response Channel (B)
    output logic [1 : 0]                          S_AXI_BRESP,
    output logic                                  S_AXI_BVALID,
    input  logic                                  S_AXI_BREADY,

    // Read Address Channel (AR)
    input  logic [C_S_AXI_ADDR_WIDTH-1 : 0]       S_AXI_ARADDR,
    //input  logic [2 : 0]                          S_AXI_ARPROT,
    input  logic                                  S_AXI_ARVALID,
    output logic                                  S_AXI_ARREADY,

    // Read Data Channel (R)
    output logic [C_S_AXI_DATA_WIDTH-1 : 0]       S_AXI_RDATA,
    output logic [1 : 0]                          S_AXI_RRESP,
    output logic                                  S_AXI_RVALID,
    input  logic                                  S_AXI_RREADY
);

    localparam DW = C_S_AXI_DATA_WIDTH;
    localparam AW = C_S_AXI_ADDR_WIDTH - 2;
    localparam ADDR_LSB = 2;

    logic axi_awready;
    logic axi_wready;
    logic axi_bvalid;
    logic axi_arready;
    logic [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
    logic axi_rvalid;
    
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY = axi_wready;
    assign S_AXI_BRESP = 2'b00;
    assign S_AXI_BVALID = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA = axi_rdata;
    assign S_AXI_RRESP = 2'b00;
    assign S_AXI_RVALID = axi_rvalid;
    
    logic valid_read_request, read_response_stall;
    
    logic [DW - 1 : 0] slv_mem [0:63];
    
    assign valid_read_request = !S_AXI_ARREADY || S_AXI_ARVALID;
    assign read_response_stall = !S_AXI_RREADY && S_AXI_RVALID;
    
    initial	axi_rvalid = 1'b0;
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)
            axi_rvalid <= 1'b0;
        else if (valid_read_request || read_response_stall)
            axi_rvalid <= 1'b1;
        else 
            axi_rvalid <= 1'b0;
    end
    
    initial	axi_arready = 1'b0;
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)
            axi_arready <= 1'b1;
        else if (read_response_stall)
            axi_arready <= !valid_read_request;
        else
            axi_arready <= 1'b1;
    end

    
    logic [C_S_AXI_ADDR_WIDTH - 1 : 0] rd_addr, pre_rd_addr;
    
    always_ff @(posedge S_AXI_ACLK) 
        if (S_AXI_ARREADY)
            pre_rd_addr <= S_AXI_ARADDR;
            
    always_comb
        if (!S_AXI_ARREADY)
            rd_addr <= pre_rd_addr;
        else
            rd_addr <= S_AXI_ARADDR;
            
    always @(posedge S_AXI_ACLK) 
        if (!read_response_stall)
            axi_rdata <= slv_mem[rd_addr[AW + ADDR_LSB - 1 : ADDR_LSB]];
          
    logic [C_S_AXI_ADDR_WIDTH - 1 : 0] pre_wr_addr, wr_addr; 
    logic [C_S_AXI_DATA_WIDTH - 1 : 0] pre_wr_data, wr_data;
    logic [(C_S_AXI_DATA_WIDTH/8) - 1 : 0] pre_wr_strb, wr_strb;
    
    logic valid_write_address, valid_write_data, write_response_stall;
    
    assign valid_write_address = S_AXI_AWVALID || !S_AXI_AWREADY; 
    assign valid_write_data = S_AXI_WVALID || !S_AXI_WREADY;
    assign write_response_stall = S_AXI_BVALID && !S_AXI_BREADY;
    
    initial	axi_awready = 1'b1;
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)
            axi_awready <= 1'b1;
        else if (write_response_stall)
            axi_awready <= !valid_write_address;
        else if (valid_write_data)
            axi_awready <= 1'b1;
        else
            axi_awready <= !S_AXI_AWVALID && S_AXI_AWREADY;
    end
    
    initial	axi_wready = 1'b1;
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)
            axi_wready <= 1'b1;
        else if (write_response_stall)
            axi_wready <= !valid_write_data;
        else if (valid_write_address)
            axi_wready <= 1'b1;
        else
            axi_wready <= !S_AXI_WVALID && S_AXI_WREADY;
    end
    
    always @(posedge S_AXI_ACLK) 
        if (S_AXI_AWREADY)
            pre_wr_addr <= S_AXI_AWADDR;
            
    always @(posedge S_AXI_ACLK)
        if (S_AXI_WREADY) begin
            pre_wr_data <= S_AXI_WDATA;
            pre_wr_strb <= S_AXI_WSTRB;
        end
        
    always_comb
        if (!S_AXI_AWREADY)
            wr_addr = pre_wr_addr;
        else
            wr_addr = S_AXI_AWADDR;
            
     always_comb
        if (!S_AXI_WREADY) begin
            wr_data = pre_wr_data;
            wr_strb = pre_wr_strb;
        end else begin
            wr_data = S_AXI_WDATA;
            wr_strb = S_AXI_WSTRB;
        end
        
    always @(posedge S_AXI_ACLK) 
        if (!write_response_stall && valid_write_address && valid_write_data) begin
		    if (wr_strb[0])
			    slv_mem[wr_addr[AW+ADDR_LSB-1:ADDR_LSB]][7:0]
				<= wr_data[7:0];
		    if (wr_strb[1])
			    slv_mem[wr_addr[AW+ADDR_LSB-1:ADDR_LSB]][15:8]
				<= wr_data[15:8];
		    if (wr_strb[2])
			    slv_mem[wr_addr[AW+ADDR_LSB-1:ADDR_LSB]][23:16]
				<= wr_data[23:16];
		    if (wr_strb[3])
			    slv_mem[wr_addr[AW+ADDR_LSB-1:ADDR_LSB]][31:24]
				<= wr_data[31:24];
		end
	
	initial	axi_bvalid = 1'b0;	
    always @(posedge S_AXI_ACLK)
        if (!S_AXI_ARESETN)
            axi_bvalid <= 1'b0;
        else if (valid_write_address && valid_write_data)
            axi_bvalid <= 1'b1;
        else if (S_AXI_BREADY)
            axi_bvalid <= 1'b0;

endmodule
