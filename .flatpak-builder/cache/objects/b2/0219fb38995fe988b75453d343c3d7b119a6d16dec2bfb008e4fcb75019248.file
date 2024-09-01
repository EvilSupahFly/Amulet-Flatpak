from minecraft_model_reader.api.mesh.block.block_mesh import BlockMesh, Transparency
from minecraft_model_reader.api import Block
from minecraft_model_reader.api.mesh.block.cube import get_unit_cube
from minecraft_model_reader.api.resource_pack.bedrock.blockshapes.cube import Cube


class GreenCube(Cube):
    @property
    def blockshape(self) -> str:
        return "greencube"

    def get_block_model(
        self,
        block: Block,
        down: str,
        up: str,
        north: str,
        east: str,
        south: str,
        west: str,
        transparency: tuple[bool, bool, bool, bool, bool, bool],
    ) -> BlockMesh:
        return get_unit_cube(
            down,
            up,
            north,
            east,
            south,
            west,
            (
                Transparency.FullTranslucent
                if any(transparency)
                else Transparency.FullOpaque
            ),
            (0, 1, 0),
        )


BlockShape = GreenCube()
