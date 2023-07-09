# obi-lib
This repository is a collection of designs I have created and tested in complete systems using the RI5CY subset of the OBI (Open Bus Interface) memory bus. The standard is maintained by the OpenHW group, and its full definition can be found [here](https://github.com/openhwgroup/obi). 

Because there are so many useful tools that do not support various features of SystemVerilog, the devices have been written in a basic subset of verilog and work with even the most restrictive open source tools. There is an included makefile to verify the compatibility of all modules against some popular open source tools.
## OBI Subset Pins
I have opted for the minimal "RI5CY" implementation in all of the designs in this repository. The pins used in the interface are described briefly here. To get the full definition, these pins adhere to the specification set forth in the [OBI spec](https://github.com/openhwgroup/obi).

| Pin Name  | Pin Count | Direction               | Description                                                    |
|-----------|:---------:|-------------------------|----------------------------------------------------------------|
| req     | 1  | Controller -> Peripheral    | Asserted by the master to request a memory transaction. The master is responsible to keep all address signals valid while req is high. |
| gnt     | 1  | Peripheral -> Controller    | Asserted by the Peripheral when new transactions can be accepted. A transaction is accepted on the rising edge of the clock if req and gnt are both high.   |
| addr    | 32 | Controller -> Peripheral    | Address output from the master |
| we      | 1  | Controller -> Peripheral    | Asserted by the master on writes. de-asserted for reads |
| be      | 4  | Controller -> Peripheral    | Byte enable output (strobe), to specify which bytes towrite to |
| wdata   | 32 | Controller -> Peripheral    | Write data output from the controller to be written to memory |
| rvalid  | 1  | Peripheral -> Controller    | Asserted by the memory system to signal valid read data. The read response is completed on the first rising clock edge when rvalid is asserted. rdata must be valid as long as rvalid is high. |
| rdata   | 32 | Peripheral -> Controller    | Read data input to the controller from the memory system |

# MUXes

The MUXes connect multiple OBI master devices to a single slave device. These MUXes all support only a single outstanding read transaction, meaning that once a read has been accepted on one device, the MUX does not allow any new requests through until the read has been completed for at least one clock posedge.

The MUXes currently used fixed priority arbitration. This results in starvation of the lower priority masters if the higher priority master is in use. For some designs this is desireable, such as an instruction and data port on a single issue, pipelined CPU when yielding the data port to the instruction port might cause a deadlock. In situations like a multicore CPU, however, this is not a good solution.

The MUXes **do NOT** validate that the masters are requesting an address in the slave device's address range, it is assumed that the request is valid by the time it reaches the MUX. 

# deMUXes

The deMUXes connect a single OBI master device to multiple slave devices. Like the MUXes, they only support a single outstanding read transaction at a time, meaning that once a read has been accepted on one device, the deMUX does not allow any new requests through until the read has been completed for at least one clock posedge. 

The deMUXes also set a `illegal_access_o` flag if the master is attempting to request a transaction from a memory address that does not correspond to any of the ports.

# Adapters

As I create and test them, I will also add adapters from OBI to other systems. Currently the only one I have needed to create is a WishboneB4-to-OBI adapter.
