# Next steps

- Harden the Python daemon with proper error handling and logging.
- Replace shell calls with a library that manages ZFS and PostgreSQL directly.
- Add authentication and permission checks for branch commands.
- Expand test coverage and add integration tests for snapshot and drop flows.
- Support cleanup of stale datasets and periodic `zpool trim` operations.
- Package a macOS helper to manage the sparse image file.
