/*
Reorder buffer

Structure
 - implemented as a circular buffer
 - 8 entries
 - Each entry has:
        1. ready bit (1 bit) - set to 1 if instruction is ready to commit
        2. instruction (75 bits) will include ALL of the metadata and the instruction. This includes
        MajorOpcode_in, Source1_in, Source2_in, OffsetScale_in, Destination_in, MinorOpcode_in, HasAddress_in, Address_in, OffsetSub_in. 
        3. value (64 bits) - data to commit; determined once instruction finishes executing
 - order is: [ready, instruction, value]
 -  indices: [  139,      138:64,  63:0]

Notes:
- Reservation stations are keeping track of ROB entry location in their tag -- output reg Entry_num will pass that back
- MUST COMMIT IN ORDER. IF THERE IS AN INSTR AHEAD OF YOU IN ROB, HAVE TO WAIT.
- Mispredicted branch = discard all ROB entries
*/

module rob (
    input wire clk, 
    input wire[3:0] MajorOpcode_in, // index location in ROB entry: [138:135] 
    input wire[4:0] Source1_in, // [134: 130]
    input wire[4:0] Source2_in, // [129:125]
    input wire[1:0] OffsetScale_in, //[124:123]
    input wire[4:0] Destination_in, //[122:118]
    input wire[3:0] MinorOpcode_in, //[117:114]
    input wire HasAddress_in, //[113]
    input wire[47:0] Address_in, //[112:65]
    input wire OffsetSub_in, //[64]
    input wire[2:0] data_entry, // Which ROB entry to update? Other components need to specify this in order to update ROB.
    input wire data_ready, // Set to 1 when value has been calculated. Need to update ROB[data_entry] with Data_in
    input wire[63:0] Data_in, // The calculated value
    input wire commit_ready, // Is the entry ready to commit?
    output reg commit_ready_reg, // Are we committing to a register file?
    output reg commit_ready_mem, // Are we committing to memory?
    output reg[63:0] Data, // Data to commit
    output reg[4:0] Destination_out, // Destination register that we are committing to
    output reg[47:0] Address_out, // Memory addr we are committing to
    output reg[2:0] Entry_num, // Which ROB entry is your instruction located in? Used by RS
    output reg stall_out // ROB is full, so we need to stall
);

// ROB: 140 bits wide * 8 entries
reg [139:0] rob [7:0];

// Location of next instruction to commit (aka start of buffer)
integer start_idx = 0;

// Location to append next instruction (aka end of the buffer)
integer end_idx = 0;

// Number of entries that are currently in the buffer
integer counter = 0;

// Concatenation of all metadata held in ROB 
reg [139:0] rob_entry;

// Temp var - had to use a register so we could concatenate to the ROB entry
reg ready = 0;

// Temp var used to store HasAddress_in state (see commit-handling code)
reg is_memory_op;

always @(negedge clk) begin 
    if(counter == 8) begin
        stall_out = 1;
    end else begin
        stall_out = 0;
    end
end

always @(posedge clk) begin 
    // Commit-handling code (if entry at start_idx is ready to commit and buffer is not empty)
    if (counter > 0 && rob[start_idx][139] == 1) begin
        rob_entry = rob[start_idx];

        // Set data to commit
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

        // Reset start_idx when we reach the end of the buffer
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
        // Concatenation of instruction metadata that composes an ROB entry
        rob_entry = {ready, MajorOpcode_in, Source1_in, Source2_in, OffsetScale_in, Destination_in, MinorOpcode_in, HasAddress_in, Address_in, OffsetSub_in};
        $display("rob_entry: %b", rob_entry);

        rob[end_idx] = rob_entry;
        $display("rob info: %b", rob[end_idx]);
        counter = counter + 1;
        $display("counter: %d", counter);

        // Reset end_idx when we reach the end of the buffer
        if(end_idx == 7) begin
            end_idx = 0;
        end else begin
            end_idx = end_idx + 1;
        end
        $display("end_idx: %d", end_idx);
    end 

    // Updating value in ROB
    if(data_ready) begin
        rob[data_entry][63:0] = Data_in;
    end

    // Updating if ROB entry is ready to commit
    if(commit_ready) begin
        rob[data_entry][139] = 1;
    end
end
endmodule 