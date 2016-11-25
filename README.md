# direnv.el

`direnv.el` is a small helper library to apply
[direnv](https://github.com/direnv/direnv) environments to processes
started from Emacs (`M-x compile`, `M-x eshell`, `M-x run-python`,
...).

Please note that this software is very young wasn't tested by anyone
me. Expect rough edges and breakage.

# Usage

Please refer to `man direnv` on how to set up `direnv`.

After adding `direnv.el` to `load-path` (or installing it via `M-x
package-install`, *not* available yet) open any file inside a folder
with a `.envrc` and run: `M-x direnv-apply`. This will call out to
`direnv` and apply the generated environment to the current buffer.

You can also add a hook for any major mode to automate this process.
For example, I use `direnv` extensively for `rust-mode` to
automatically make `rustc`, `cargo`, and other dependencies available:

    (add-hook 'rust-mode-hook #'direnv-apply)

Now opening a file in `rust-mode` will automatically check for a
`.envrc` and apply the environment defined in it.

## Caching Environments

`direnv.el` caches the results of from `direnv` so it doesn't have to
start a direnv process every time a new buffer is opened. If you find
yourself with an outdated environment you can run `C-u M-x
direnv-apply` to refresh the environment of the current file/buffer or
run `M-x direnv-clear-cache` to clear the cache completely

## Direnv + Nix

`direnv` has great support for the [nix](https://nixos.org/nix/)
package manager. A `.envrc` with the following contents will
automatically apply a `nix-shell` environment from a `default.nix` or
`shell.nix`:

    use nix
