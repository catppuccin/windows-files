# Print out all recipes when running `just`
_default:
    @just --list

# Generate a single file containing all four flavors
gen:
  whiskers files.tera