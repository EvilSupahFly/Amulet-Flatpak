from typing import Dict, Iterator as PyIterator, Tuple

class LevelDBException(Exception):
    """
    The exception thrown for all leveldb related errors.
    """

    pass

class LevelDBEncrypted(LevelDBException):
    pass

class LevelDBIteratorException(LevelDBException):
    """
    The exception thrown for issues related to the iterator.
    """

class Iterator:
    def valid(self) -> bool:
        """
        Is the iterator at a valid entry.
        If False, calls to other methods may error.
        """

    def seek_to_first(self) -> None:
        """Seek to the first entry in the database."""

    def seek_to_last(self) -> None:
        """Seek to the last entry in the database."""

    def seek(self, target: bytes) -> None:
        """
        Seek to the given entry in the database.
        If the entry does not exist it will seek to the location after.
        """

    def next(self) -> None:
        """Seek to the next entry in the database."""

    def prev(self) -> None:
        """Seek to the previous entry in the database."""

    def key(self) -> bytes:
        """
        Get the key of the current entry in the database.
        If valid returns False this will error.
        """

    def value(self) -> bytes:
        """
        Get the value of the current entry in the database.
        If valid returns False this will error.
        """

class LevelDB:
    def __init__(self, path: str, create_if_missing: bool = False): ...
    def close(self, compact: bool = False) -> None: ...
    def get(self, key: bytes) -> bytes: ...
    def put(self, key: bytes, val: bytes) -> None: ...
    def putBatch(self, data: Dict[bytes, bytes]) -> None: ...
    def delete(self, key: bytes) -> None: ...
    def new_iterator(self) -> Iterator: ...
    def iterate(
        self, start: bytes | None = None, end: bytes | None = None
    ) -> PyIterator[Tuple[bytes, bytes]]: ...
    def keys(self) -> PyIterator[bytes]: ...
    def items(self) -> PyIterator[Tuple[bytes, bytes]]: ...
    def compact(self) -> None: ...
    def __contains__(self, key: bytes) -> bool: ...
    def __getitem__(self, key: bytes) -> bytes: ...
    def __setitem__(self, key: bytes, value: bytes) -> None: ...
    def __delitem__(self, key: bytes) -> None: ...
    def __iter__(self) -> PyIterator[bytes]: ...
