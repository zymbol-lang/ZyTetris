#!/usr/bin/env bash
# тесты/запуск.sh — every test through every engine that can run it, against its .expected.
#   bash запуск.sh            compare
#   bash запуск.sh --regen    rewrite the .expected from the VM (read the diff before committing)
# Plain tests (*.zy with an .expected) run on the VM, the tree-walker and the browser engine.
# Games (партия*.keys) need a screen: VM and tree-walker only, the keys from the .keys file.
# The ZYMBOL_BIN / ZYJS_RUN variables point at other builds; node is optional.
cd "$(dirname "$0")" || exit 2
ZY="${ZYMBOL_BIN:-zymbol}"
JS="${ZYJS_RUN:-../../web/tests/run_one.mjs}"
export NO_COLOR=1
regen=0; [ "$1" = "--regen" ] && regen=1
fail=0; ran=0

run() {  # engine-flag file [keys]
    rm -f рекорды_тест.json
    if [ -n "$3" ]; then timeout 120 "$ZY" run $1 --keys "$3" "$2" </dev/null 2>&1
    else timeout 120 "$ZY" run $1 "$2" </dev/null 2>&1; fi
}
check() {  # label expected actual
    ran=$((ran + 1))
    if ! diff -q "$2" "$3" >/dev/null; then
        echo "FAIL $1"; diff "$2" "$3" | head -8; fail=$((fail + 1))
    fi
}

for t in ядро язык ввод рекорды; do
    exp="$t.expected"
    run "" "$t.zy" > /tmp/zt_vm.$$
    [ $regen = 1 ] && cp /tmp/zt_vm.$$ "$exp"
    check "$t [vm]" "$exp" /tmp/zt_vm.$$
    run "--tw" "$t.zy" > /tmp/zt_tw.$$
    check "$t [tw]" "$exp" /tmp/zt_tw.$$
    if command -v node >/dev/null && [ -f "$JS" ]; then
        rm -f рекорды_тест.json
        timeout 120 node "$JS" "$t.zy" </dev/null > /tmp/zt_js.$$ 2>&1
        check "$t [js]" "$exp" /tmp/zt_js.$$
    fi
done

for k in партия_*.keys; do
    t="${k%.keys}"
    run "" партия.zy "$k" > /tmp/zt_vm.$$
    [ $regen = 1 ] && cp /tmp/zt_vm.$$ "$t.expected"
    check "$t [vm]" "$t.expected" /tmp/zt_vm.$$
    run "--tw" партия.zy "$k" > /tmp/zt_tw.$$
    check "$t [tw]" "$t.expected" /tmp/zt_tw.$$
done
rm -f /tmp/zt_*.$$ рекорды_тест.json
echo "$ran comparisons, $fail failed"
[ $fail = 0 ]
