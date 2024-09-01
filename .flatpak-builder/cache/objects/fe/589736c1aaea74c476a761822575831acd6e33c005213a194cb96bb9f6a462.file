from minecraft_model_reader.api.resource_pack.bedrock.blockshapes.pumpkin import Pumpkin
from minecraft_model_reader.api import Block


class PumpkinLit(Pumpkin):
    @property
    def blockshape(self) -> str:
        return "pumpkin_lit"

    def texture_index(self, block: Block, aux_value: int) -> int:
        return 1


BlockShape = PumpkinLit()
