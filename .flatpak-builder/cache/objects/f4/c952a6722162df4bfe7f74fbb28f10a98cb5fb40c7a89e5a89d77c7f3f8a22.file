from minecraft_model_reader.api.resource_pack.bedrock.blockshapes.cube import Cube
from minecraft_model_reader.api import Block


class TurtleEgg(Cube):
    @property
    def blockshape(self) -> str:
        return "turtle_egg"

    def texture_index(self, block: Block, aux_value: int) -> int:
        """The texture index to use within the list for the given Block"""
        return (aux_value // 4) % 3


BlockShape = TurtleEgg()
