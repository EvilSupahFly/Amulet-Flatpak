from typing import TYPE_CHECKING

from .block_mesh import BlockMesh
from .cube import get_unit_cube

if TYPE_CHECKING:
    from minecraft_model_reader.api.resource_pack.base import BaseResourcePackManager


def get_missing_block(resource_pack: "BaseResourcePackManager") -> BlockMesh:
    texture_path = resource_pack.get_texture_path("minecraft", "missing_no")
    return get_unit_cube(
        texture_path,
        texture_path,
        texture_path,
        texture_path,
        texture_path,
        texture_path,
    )
