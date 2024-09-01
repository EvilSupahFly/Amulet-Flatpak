from minecraft_model_reader.api.resource_pack.base.resource_pack import BaseResourcePack


class UnknownResourcePack(BaseResourcePack):
    def __repr__(self) -> str:
        return f"UnknownResourcePack({self._root_dir})"

    @staticmethod
    def is_valid(pack_path: str) -> bool:
        return True
