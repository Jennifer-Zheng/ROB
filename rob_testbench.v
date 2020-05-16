module rob_testbench;

    reg [3:0] MajorOpcode_in; // [138:135]
    reg [4:0] Source1_in; // [134: 130]
    reg [4:0] Source2_in; // [129:125]
    reg [1:0] OffsetScale_in; //[124:123]
    reg [4:0] Destination_in; //[122:118]
    reg [3:0] MinorOpcode_in; //[117:114]
    reg  HasAddress_in; //[113]
    reg [47:0] Address_in; //[112:65]
    reg  OffsetSub_in; //[64]
    reg [2:0] data_entry;
    reg  data_ready;
    reg [63:0] Data_in;
    reg  commit_ready;
    wire commit_ready_reg;
    wire commit_ready_mem;
    wire [63:0] Data;
    wire [4:0] Destination_out;
    wire HasAddress_out;
    wire [47:0] Address_out;
    wire [2:0] Entry_num;
    wire stall_out = 0;

rob r (clk, MajorOpcode_in, Source1_in, Source2_in, OffsetScale_in, Destination_in, MinorOpcode_in, HasAddress_in, Address_in, OffsetSub_in, data_entry, data_ready, Data_in, commit_ready, commit_ready_reg, commit_ready_mem, Data, Destination_out, HasAddress_out, Address_out, Entry_num, stall_out);



endmodule
