# Quickstart: Validating Search, Yank Feedback and Buffer Navigation

## Prerequisites

- Neovim 0.12+ with this config as `~/.config/nvim`.
- Test files:

  ```sh
  mkdir -p /tmp/sn && cd /tmp/sn
  printf 'foo Foo FOO\nbar foo\nfoo\n' > a.txt
  printf 'b\n' > b.txt; printf 'c\n' > c.txt
  seq 1 50000 > big.txt
  ```

## 1. Clean start (FR-016, SC-006)

```sh
nvim --headless "+qa"                       # expect: no output
nvim --startuptime /tmp/st.log +qa && tail -1 /tmp/st.log   # expect: < 100 ms
```

## 2. Search options (US1 #1–3, FR-001–FR-003)

`nvim a.txt`:

1. Type `/foo` but don't press Enter. Expect the cursor not to move and no matches highlighted.
2. Press Enter. Expect `foo`, `Foo`, `FOO` and the other `foo`s (5 in total) highlighted.
3. Run `/Foo` and press Enter. Expect only `Foo` to be highlighted.

## 3. Position label (US1 #4–7, FR-005–FR-008, SC-001)

1. Run `/foo` and press Enter. Expect `[2/5]`, right-aligned on line 1. The cursor started at
   1:1, so the search moves to the next match after it.
2. Press `n` repeatedly. Expect the label to step `[3/5]`, `[4/5]`, `[5/5]`, then wrap to
   `[1/5]`. Only one label is visible.
3. Press `N`. Expect the label to count down.
4. Put the cursor on `bar` and press `*`. Expect `[1/1]`.
5. Search again, then move away with `j`/`w`. Expect the label to stay where it was.
6. Press `yy` then `p`. Expect the label not to be pasted.
7. Press `x` on any line. Expect the label to disappear (buffer edited).

## 4. Clearing (US1 #6, FR-004, FR-007, SC-002)

1. Run `/foo`, press Enter, then press `<Esc>`. Expect all highlights and the label gone.
2. Press `n`. Expect the highlights and the label back.
3. Run `:noh`. Expect the label gone.
4. With a label shown, run `:e b.txt`. Expect the label gone when you come back to `a.txt`.
5. Press `<Esc>` with nothing highlighted. Expect no message and no error.

## 5. Large file (FR-009, SC-005, SC-007)

`nvim big.txt`:

1. Run `/0` and press Enter. Expect a label like `[1/>999]` with no visible delay.
2. Press `G`, then `gg`. Expect the line-number column to stay the same width the whole time.

## 6. Buffer cycling (US2, FR-010–FR-012a, SC-003)

`nvim a.txt b.txt c.txt`, starting in `a.txt`:

1. Press `<Tab>` three times. Expect `b.txt`, `c.txt`, `a.txt`.
2. Press `<S-Tab>`. Expect `c.txt`.
3. Run `:help`, then `:copen`. Press `<Tab>` from a normal window. Expect help and quickfix
   never to be shown.
4. `nvim a.txt` alone, press `<Tab>`. Expect nothing to happen and no error.
5. In insert mode, press `<Tab>`. Expect indentation to be inserted.
6. Press `<C-o>` after a jump. Expect a jump back.

## 7. Yank highlight (US3, FR-013, SC-004)

1. Press `yiw`, `yy` and `vjy` in turn. Expect the yanked region to flash briefly, under 1 s.
2. Press `dd`, then `ciw`. Expect no flash.

## 8. Mapping descriptions (FR-015)

Run `:verbose nmap <Tab>`, `:nmap <S-Tab>`, `:nmap <Esc>` and `:nmap n`. Expect each to show
a description.
