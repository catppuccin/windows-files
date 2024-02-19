_default:
    @just --list

output := "themes"

setup:
    mkdir -p {{output}}

clean:
    rm -fv {{output}}/*.json

gen flavor:
  whiskers template.json {{flavor}} -o {{output}}/{{flavor}}.toml

all: setup (gen "latte") (gen "frappe") (gen "macchiato") (gen "mocha")
