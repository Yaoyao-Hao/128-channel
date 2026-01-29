# 128-channel
A 128-channel fully implantable system with COTS components for intracortical neural sensing and decoding

Multi-Shank Silicon Probe (MSSP):
  
    Layer 1: Metal
    Defines the metallization pattern, including bond pads, recording sites, and interconnection traces. The metal stack is Ti/Au/Ti 
    with a thickness of 5/100/5 nm. The metal pattern is implemented by sputter deposition followed by lift-off.
    
    Layer 2: Openings
    Defines the pad and site opening regions for the top 500 nm silicon nitride insulation, so that the bond pads and recording 
    sites are exposed.
    
    Layer 3: Outline
    Defines the probe outline. This layer is used to generate the photoresist mask pattern, which serves as the etch mask for silicon 
    nitride stack (total 1 um, two 500 nm layers) etching, for subsequent DRIE of the 25 um SOI device layer, and for the removal of 
    the 1 um SOI burried oxide layer after DRIE.

Flexible Cable:

    Layer 1: Metal
    Defines the metallization pattern, including bond pads and interconnection traces. The metal stack is Ti/Au/Ti with a 
    thickness of 5/100/5 nm. The metal pattern is implemented by sputter deposition followed by lift-off.
    
    Layer 2: Outline
    Defines the cable outline. This layer is used to generate the photoresist mask pattern, which serves as the etch 
    mask for polyimide stack (total 16 um, two 8 um layers) etching.
    
    Layer 3: Openings
    Defines the pad opening regions for the top 8 um polyimide insulation.
