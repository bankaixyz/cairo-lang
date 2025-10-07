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

// Bootloads a single Cairo 1 program by delegating to the simple bootloader with a
// synthetic single-task input. The Python hint populates `simple_bootloader_input`
// from the provided program payload.
//
// Hint arguments:
// * program_input - dictionary produced by the host that encodes the compiled
//   Cairo 1 program and its calldata.
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

    // Handle ec_op builtin. See docstring of `handle_uninitialized_ec_op_builtin` for more info.
    local ec_op_ptr_orig = ec_op_ptr;
    let (local ec_op_ptr) = handle_uninitialized_ec_op_builtin(ec_op_ptr=ec_op_ptr);
    local ec_op_start_ptr = ec_op_ptr;

    // Handle keccak builtin. See docstring of `handle_uninitialized_keccak_builtin` for more info.
    local keccak_ptr_orig = keccak_ptr;
    let (local keccak_ptr) = handle_uninitialized_keccak_builtin(keccak_ptr=keccak_ptr);
    local keccak_start_ptr = keccak_ptr;

    // Handle ecdsa builtin. See docstring of `handle_uninitialized_ecdsa_builtin` for more info.
    local ecdsa_ptr_orig = ecdsa_ptr;
    let (local ecdsa_ptr) = handle_uninitialized_ecdsa_builtin(ecdsa_ptr=ecdsa_ptr);
    local ecdsa_start_ptr = ecdsa_ptr;

    // Execute the wrapped simple bootloader.
    run_simple_bootloader();

    // Verify the ec_op builtin.
    let (local ec_op_ptr) = handle_ec_op_builtin_verification(
        ec_op_ptr=ec_op_ptr, ec_op_ptr_orig=ec_op_ptr_orig, ec_op_start_ptr=ec_op_start_ptr
    );

    // Verify the keccak builtin.
    let (local keccak_ptr) = handle_keccak_builtin_verification(
        keccak_ptr=keccak_ptr, keccak_ptr_orig=keccak_ptr_orig, keccak_start_ptr=keccak_start_ptr
    );

    // Verify the ecdsa builtin.
    let (local ecdsa_ptr) = handle_ecdsa_builtin_verification(
        ecdsa_ptr=ecdsa_ptr, ecdsa_ptr_orig=ecdsa_ptr_orig, ecdsa_start_ptr=ecdsa_start_ptr
    );

    return ();
}
