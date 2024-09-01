from minecraft_model_reader.api.resource_pack.bedrock.blockshapes.pumpkin import Pumpkin
from minecraft_model_reader.api import Block


class PumpkinCarved(Pumpkin):
    @property
    def blockshape(self) -> str:
        return "pumpkin_carved"

    def texture_index(self, block: Block, aux_value: int) -> int:
        return 0


BlockShape = PumpkinCarved()
