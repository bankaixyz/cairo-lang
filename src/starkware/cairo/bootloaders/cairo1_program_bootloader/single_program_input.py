from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, List, Optional

from starkware.cairo.bootloaders.hash_program import HashFunction
from starkware.cairo.lang.compiler.program import Program

try:
    from starkware.cairo.bootloaders.simple_bootloader.objects import (
        RunProgramTask as _RunProgramTask,
        SimpleBootloaderInput as _SimpleBootloaderInput,
    )
except ImportError:  # pragma: no cover - fallback for stripped environments.
    _RunProgramTask = None
    _SimpleBootloaderInput = None


@dataclass
class _FallbackRunProgramTask:
    program: Program
    program_input: Any
    program_hash_function: int

    def get_program(self) -> Program:
        return self.program


@dataclass
class _FallbackSimpleBootloaderInput:
    tasks: List[_FallbackRunProgramTask]
    fact_topologies_path: Optional[str]
    single_page: bool

    @classmethod
    def Schema(cls):  # pragma: no cover - compatibility shim.
        class _Schema:
            def load(self, data: Dict[str, Any]) -> "_FallbackSimpleBootloaderInput":
                return _FallbackSimpleBootloaderInput(**data)

        return _Schema()


def _resolve_task_class():
    return _RunProgramTask if _RunProgramTask is not None else _FallbackRunProgramTask


def _resolve_input_class():
    return (
        _SimpleBootloaderInput
        if _SimpleBootloaderInput is not None
        else _FallbackSimpleBootloaderInput
    )


def _parse_program(raw_program: Any) -> Program:
    if isinstance(raw_program, Program):
        return raw_program
    if not isinstance(raw_program, Dict):
        raise TypeError("program must be a Program object or a JSON-like dictionary")
    return Program.Schema().load(raw_program)


def _parse_hash_function(raw_hash_function: Any) -> int:
    if raw_hash_function is None:
        return HashFunction.PEDERSEN.value
    if isinstance(raw_hash_function, int):
        return raw_hash_function
    if isinstance(raw_hash_function, str):
        return HashFunction[raw_hash_function.upper()].value
    raise TypeError("Unsupported hash function specification")


def build_single_program_bootloader_input(raw_input: Dict[str, Any]):
    """Builds a ``SimpleBootloaderInput`` for running a single Cairo 1 program.

    ``raw_input`` is expected to contain the compiled program under the ``"program"`` key
    and the encoded program input under ``"program_input"``. Optional keys:
    ``"program_hash_function"`` (string or integer compatible with ``HashFunction``),
    ``"single_page"`` and ``"fact_topologies_path"``.
    """

    if raw_input is None:
        raise TypeError("program_input must not be None")
    if "program" not in raw_input:
        raise KeyError("program_input must contain a 'program' entry")

    program = _parse_program(raw_program=raw_input["program"])
    program_input = raw_input.get("program_input")
    hash_function = _parse_hash_function(raw_input.get("program_hash_function"))

    task_cls = _resolve_task_class()
    task = task_cls(
        program=program,
        program_input=program_input,
        program_hash_function=hash_function,
    )

    input_cls = _resolve_input_class()
    return input_cls(
        tasks=[task],
        fact_topologies_path=raw_input.get("fact_topologies_path"),
        single_page=raw_input.get("single_page", True),
    )
