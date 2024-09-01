from minecraft_model_reader.api.resource_pack.bedrock.blockshapes.cross_texture import (
    Cross,
)
from minecraft_model_reader.api import Block, BlockMesh


class BubbleColumn(Cross):
    @property
    def blockshape(self) -> str:
        return "bubble_column"

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
        return super().get_block_model(
            block, north, north, north, north, north, north, transparency
        )


BlockShape = BubbleColumn()
