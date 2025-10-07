# Cairo1 Program Bootloader

This document summarizes the minimal Cairo 0 bootloader that executes a single
Cairo 1 program while reusing the existing simple bootloader infrastructure.
The implementation lives in
`starkware/cairo/bootloaders/cairo1_program_bootloader/cairo1_program_bootloader.cairo`
and delegates nearly all heavy lifting to `run_simple_bootloader` so builtin
handling stays identical to the battle-tested task pipeline.

## Overview

* Accept a compiled Cairo 1 executable (plain program, no contract wrapper) and
  its serialized program input.
* Convert that payload into a `SimpleBootloaderInput` with a single
  `RunProgramTask` using a small Python helper.
* Invoke `run_simple_bootloader`, which loads the program, wires builtin
  pointers, executes the code, and validates that builtin usage matches the
  Cairo runner expectations.

## Cairo entry point

The Cairo program mirrors `simple_bootloader.cairo`: it prepares the optional
builtins, runs the simple bootloader, and replays the builtin verification
helpers.【F:src/starkware/cairo/bootloaders/cairo1_program_bootloader/cairo1_program_bootloader.cairo†L1-L67】

```cairo
%builtins output pedersen range_check ecdsa bitwise ec_op keccak poseidon range_check96 add_mod mul_mod

from starkware.cairo.bootloaders.simple_bootloader.run_simple_bootloader import (
    run_simple_bootloader,
)
from starkware.cairo.bootloaders.simple_bootloader.verify_builtins import (
    handle_ec_op_builtin_verification,
    handle_ecdsa_builtin_verification,
    handle_keccak_builtin_verification,
    handle_uninitialized_ec_op_builtin,
    handle_uninitialized_ecdsa_builtin,
    handle_uninitialized_keccak_builtin,
)
from starkware.cairo.common.cairo_builtins import HashBuiltin, PoseidonBuiltin

func main{
    output_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr,
    ecdsa_ptr,
    bitwise_ptr,
    ec_op_ptr,
    keccak_ptr,
    poseidon_ptr: PoseidonBuiltin*,
    range_check96_ptr,
    add_mod_ptr,
    mul_mod_ptr,
}() {
    alloc_locals;
    %{
        from starkware.cairo.bootloaders.cairo1_program_bootloader.single_program_input import (
            build_single_program_bootloader_input,
        )

        simple_bootloader_input = build_single_program_bootloader_input(program_input)
    %}

    let (local ec_op_ptr) = handle_uninitialized_ec_op_builtin(ec_op_ptr=ec_op_ptr);
    let (local keccak_ptr) = handle_uninitialized_keccak_builtin(keccak_ptr=keccak_ptr);
    let (local ecdsa_ptr) = handle_uninitialized_ecdsa_builtin(ecdsa_ptr=ecdsa_ptr);

    run_simple_bootloader();

    let (local ec_op_ptr) = handle_ec_op_builtin_verification(
        ec_op_ptr=ec_op_ptr, ec_op_ptr_orig=ec_op_ptr_orig, ec_op_start_ptr=ec_op_start_ptr
    );
    let (local keccak_ptr) = handle_keccak_builtin_verification(
        keccak_ptr=keccak_ptr, keccak_ptr_orig=keccak_ptr_orig, keccak_start_ptr=keccak_start_ptr
    );
    let (local ecdsa_ptr) = handle_ecdsa_builtin_verification(
        ecdsa_ptr=ecdsa_ptr, ecdsa_ptr_orig=ecdsa_ptr_orig, ecdsa_start_ptr=ecdsa_start_ptr
    );

    return ();
}
```

The output format and builtin pointer updates remain exactly the same as the
simple bootloader because the inner logic is unchanged.【F:src/starkware/cairo/bootloaders/simple_bootloader/run_simple_bootloader.cairo†L52-L203】

## Input conversion helper

The Python helper that feeds the hint lives in
`starkware/cairo/bootloaders/cairo1_program_bootloader/single_program_input.py`.
It converts a plain dictionary into the structured `SimpleBootloaderInput`
consumed by the existing hints.  The helper accepts a Cairo program expressed as
JSON (or an already-loaded `Program` object), optional calldata, and an optional
hash function selector.  When the official `simple_bootloader.objects`
definitions are available they are reused; otherwise lightweight fallback
implementations keep the bootloader usable in stripped environments.【F:src/starkware/cairo/bootloaders/cairo1_program_bootloader/single_program_input.py†L1-L104】

## Expected inputs and outputs

* **Inputs:** dictionary with at least a `"program"` entry holding the compiled
  Cairo 1 program, plus optional `"program_input"`, `"program_hash_function"`,
  `"single_page"`, and `"fact_topologies_path"` fields.
* **Outputs:** identical to the simple bootloader—number of tasks (always 1),
  program hash, then the Cairo program output segment.
* **Builtins:** initialized and verified via the same helpers used by the simple
  bootloader, ensuring compatibility with existing tooling.【F:src/starkware/cairo/bootloaders/simple_bootloader/verify_builtins.cairo†L1-L126】

With this wiring, a host can load Cairo 1 bytecode and calldata into the Cairo 0
VM without dealing with the broader task abstraction or modifying the proven
simple bootloader pipeline.
