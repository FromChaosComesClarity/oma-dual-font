# Oma Dual Font

One font for the system, a different one for the terminal.

![The popup](preview.png)

## Why

Omarchy has exactly one font. `omarchy-font-set` points the fontconfig
`monospace` alias at a family and rewrites every terminal config to match, so
the bar, Qt apps and the terminals all move together.

That is fine until you want something proportional on the desktop. I put
Poppins on mine, admired it for about four seconds, then opened a terminal and
watched my prompt turn into modern art. The font menu only lists monospace
families, which is Omarchy quietly protecting me from exactly this, and I went
around it anyway.

This plugin lets you have both. Pick any family for the system, keep a proper
monospace one in the terminal, and they stop fighting.

## How it works

Every terminal names its font family explicitly in its own config, so it
ignores the fontconfig alias entirely. That is the whole trick.

- The system font stays stock. Picking one just runs `omarchy-font-set`.
- The terminal font writes only the alacritty, kitty, ghostty and foot configs,
  and records the choice in `~/.config/omarchy/terminal-font`.
- A hook in `~/.config/omarchy/hooks/font-set.d/` replays that choice after any
  system font change, which is what stops one from dragging the other along.

With no terminal font pinned, every part of this is a no-op and Omarchy behaves
exactly as shipped. The hook installs itself the first time the widget loads.

The terminal list is monospace only, on purpose. I already know how that story
ends.

Both pickers also carry the six fonts Omarchy offers under Install > Style >
Font, even when they are not on the machine yet. They are marked as such, and
picking one opens the same floating terminal Omarchy uses to install a font,
then applies it. Showing fewer fonts than the stock menu offers felt like the
wrong kind of surprise.

## Install

```bash
git clone https://github.com/FromChaosComesClarity/oma-dual-font \
  ~/.config/omarchy/plugins/io.github.fromchaoscomesclarity.oma-dual-font
omarchy-shell shell rescanPlugins
```

Then add **Oma Dual Font** to the bar from the Omarchy menu, under
Style > Menu Bar, or drop it into `bar.layout` in
`~/.config/omarchy/shell.json`:

```json
{ "id": "io.github.fromchaoscomesclarity.oma-dual-font" }
```

Click the icon on the bar and both pickers are there. Both are searchable,
because the system list is every family fontconfig knows and that runs to a few
hundred on most machines.

## From a shell

The widget is a view over a CLI that works on its own:

```bash
bin/oma-dual-font doctor            # what is installed and what is set
bin/oma-dual-font terminal-options  # picker rows, installable fonts included
bin/oma-dual-font system-set Poppins
bin/oma-dual-font terminal-set 'iA Writer Mono S'
bin/oma-dual-font terminal-clear    # terminals follow the system font again
bin/oma-dual-font install-hook      # if you ever need to put the hook back
```

Ghostty and foot cannot reload a font in place, so you get a notification
asking you to restart them. Alacritty and kitty pick it up immediately.

## Uninstall

```bash
bin/oma-dual-font terminal-clear
rm ~/.config/omarchy/hooks/font-set.d/10-oma-dual-font
rm -rf ~/.config/omarchy/plugins/io.github.fromchaoscomesclarity.oma-dual-font
```

Remove the widget from `bar.layout` and you are back to stock.

## License

GPL-3.0-or-later.
