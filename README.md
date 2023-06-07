# obi-lib
This repository is a collection of designs I have created and tested in complete systems using the RI5CY subset of the OBI (Open Bus Interface) memory bus. The standard is maintained by the OpenHW group, and its full definition can be found [here](https://github.com/openhwgroup/obi). I have opted for the minimal "RI5CY" implementation in all of the designs in this repository.

Because there are so many useful tools that do not support various features of SystemVerilog, the devices have been written in verilog and work with even the most restrictive open source tools.

# MUXes

The MUXes connect multiple OBI master devices to a single slave device. These MUXes all support only a single outstanding read transaction, meaning that once a read has been accepted on one device, the MUX does not allow any new requests through until the read has been completed for at least one clock posedge.

The MUXes **do NOT** validate that the masters are requesting an address in the slave device's address range, it is assumed that the request is valid by the time it reaches the MUX. 

# deMUXes

The deMUXes connect a single OBI master device to multiple slave devices. Like the MUXes, they only support a single outstanding read transaction at a time, meaning that once a read has been accepted on one device, the deMUX does not allow any new requests through until the read has been completed for at least one clock posedge. 

The deMUXes also set a `illegal_access_o` flag if the master is attempting to request a transaction from a memory address that does not correspond to any of the ports.

# Adapters

As I create and test them, I will also add adapters from OBI to other systems. Currently the only one I have needed to create is a WishboneB4-to-OBI adapter.
