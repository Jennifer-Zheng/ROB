/*
Reorder buffer 

Structure
 - 8 entries
 - Each entry has:
        1. ready bit (1 bit) - set to 1 if instruction is ready to commit
        2. instruction type (75 bits) will include:
            - destination - destination register or memory address
        3. value (64 bits) - data to commit; determined once instruction finishes executing (will be retrieved from CDB when the instr is done) (ALU)
 - order is [ready, instruction, destination, value]
[139, 138:64, 63:0]
RS is keeping track of ROB entry location in their tag -- must pass back?

MUSt COMMIT IN ORDER. IF THERE IS AN INSTR AHEAD OF YOU IN ROB, HAVE TO WAIT

Mispredicted branch = discard all ROB entries

Implement circular buffer for queue. Keep track of start and end indices. When end idx reaches end of queue
loop back up. 
on commit check if idx = start idx (aka first entry in queue)
*/

module rob (
    input wire[3:0] MajorOpcode_in, // [138:135]
    input wire[4:0] Source1_in, // [134: 130]
    input wire[4:0] Source2_in, // [129:125]
    input wire[1:0] OffsetScale_in, //[124:123]
    input wire[4:0] Destination_in, //[122:118]
    input wire[3:0] MinorOpcode_in, //[117:114]
    input wire HasAddress_in, //[113]
    input wire[47:0] Address_in, //[112:65]
    input wire OffsetSub_in, //[64]
    input wire[2:0] data_entry,
    input wire data_ready,
    input wire[63:0] Data_in,
    input wire commit_ready,
    output reg commit_ready_reg,
    output reg commit_ready_mem,
    output reg[63:0] Data,
    output reg[4:0] Destination_out,
    output reg HasAddress_out,
    output reg[47:0] Address_out,
    output reg[2:0] Entry_num,
    output reg stall_out
);

// ROB: 140 bits wide * 8 entries
reg [139:0] rob [7:0];

// Location of next instruction to commit (aka start of buffer)
integer start_idx = 0;

// Location to append next ins (aka end of queue)
integer end_idx = 0;

// Number of entries that are currently in the queue
integer counter = 0;

// Concatenation of all metadata held in ROB 
reg [139:0] rob_entry;

reg is_memory_op;
always @(negedge clk) begin 
    if(counter == 8) begin
        stall_out = 1;
    end else begin
        stall_out = 0;
    end
end

integer test = 0;
always @(posedge clk) begin 
    if(test < 5) begin
    // Commit handling code (if entry at start_idx is ready to commit and queue is not empty)
    if (counter > 0 && rob[start_idx][139] == 1) begin
        rob_entry = rob[start_idx];
        Data = rob_entry[63:0];
        // is memory op if HasAddress_in == 1
        is_memory_op = rob_entry[113];

        // Memory operation
        if (is_memory_op) begin
            Address_out = rob_entry[112:65];
            commit_ready_mem = 1;
        end else begin
            // Register operation
            Destination_out = rob_entry[122:118];
            commit_ready_reg = 1;
        end
        // Reset start_idx when we reach the end of the queue
        if(start_idx == 7) begin
            start_idx = 0;
        end else begin
            start_idx = start_idx + 1;
        end
        $display("start_idx: %d", start_idx);

        counter = counter - 1;
        $display("counter: %d", counter);
    end

    // Handle appending an ROB entry (only when we are not at capacity)
    if(counter != 8) begin
        rob_entry = {0, MajorOpcode_in, Source1_in, Source2_in, OffsetScale_in, Destination_in, MinorOpcode_in, HasAddress_in, Address_in, OffsetSub_in};
        $display("rob_entry: %b", rob_entry);

        rob[end_idx] = rob_entry;
        $display("rob info: %b", rob[end_idx]);
        counter = counter + 1;
        $display("counter: %d", counter);

        // Reset end_idx when we reach the end of the queue
        if(end_idx == 7) begin
            end_idx = 0;
        end else begin
            end_idx = end_idx + 1;
        end
        $display("end_idx: %d", end_idx);
    end 

    //TODO: handle update of columns
    if(data_ready) begin
        rob[data_entry][63:0] = Data_in;
    end

    if(commit_ready) {
        rob[data_entry][139] = 1;
    }

    test = test + 1;
    end
end
endmodule 