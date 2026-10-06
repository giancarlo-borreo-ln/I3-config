#!/bin/bash
# fullscreen-tabs.sh - Vista "fullscreen affiancata" per un gruppo di tab.
#
# Premi $mod+Shift+f:
#   * se il gruppo NON e' in fullscreen: dispone i tab affiancati (splith) e
#     mette in fullscreen l'intero contenitore, cosi' entrambe le finestre
#     riempiono lo schermo e la barra/polybar viene nascosta.
#   * se e' gia' in fullscreen: esce dal fullscreen e torna al layout a tab.
#
# Richiede python3 (per leggere l'albero di i3).

set -u

read -r CID FS HASWIN LAYOUT < <(
    i3-msg -t get_tree | python3 -c '
import sys, json
tree = json.load(sys.stdin)
res = {}
def walk(node, stack):
    if node.get("focused"):
        has_win = node.get("window") is not None
        current = node if not has_win else (stack[-1] if stack else node)
        chain = [node] + list(reversed(stack))
        fs = 0
        for n in chain:
            if n.get("type") in ("con", "floating_con") and n.get("fullscreen_mode"):
                fs = 1
                break
        res["id"] = current.get("id", 0)
        res["fs"] = fs
        res["haswin"] = 1 if has_win else 0
        res["layout"] = current.get("layout", "")
        return
    for child in node.get("nodes", []):
        walk(child, stack + [node])
walk(tree, [])
print(res.get("id", 0), res.get("fs", 0), res.get("haswin", 0), res.get("layout", ""))
'
)

# Nessuna finestra focalizzata: niente da fare.
if [ -z "${CID:-}" ] || [ "$CID" = "0" ]; then
    exit 0
fi

# Se il focus e' su un contenitore (non su una finestra), entra in una finestra:
# i comandi "layout" applicati a un contenitore lo avvolgono in un nuovo split.
if [ "${HASWIN:-0}" != "1" ]; then
    i3-msg "focus child" >/dev/null
fi

if [ "${FS:-0}" = "1" ]; then
    # Uscita: togli il fullscreen, ripristina i tab e riporta il focus su una finestra.
    i3-msg "focus parent" >/dev/null
    i3-msg "fullscreen disable" >/dev/null
    i3-msg "focus child" >/dev/null
    [ "${LAYOUT:-}" != "tabbed" ] && i3-msg "layout tabbed" >/dev/null
else
    # Ingresso: affianca i tab, poi mette in fullscreen l'intero contenitore.
    [ "${LAYOUT:-}" != "splith" ] && i3-msg "layout splith" >/dev/null
    i3-msg "focus parent" >/dev/null
    i3-msg "fullscreen enable" >/dev/null
    i3-msg "focus child" >/dev/null
fi
