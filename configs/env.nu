# ENVIRONMENT OVERRIDES
use prompt.nu main

$env.PATH = ($env.PATH | uniq)
$env.CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense"

$env.PROMPT_COMMAND = {|| prompt}
$env.PROMPT_COMMAND_RIGHT = {|| ""}
$env.PROMPT_MULTILINE_INDICATOR = {|| "# "}


# ADDITIONAL COMMANDS
mkdir $"($nu.cache-dir)"
carapace _carapace nushell | save --force $"($nu.cache-dir)/carapace.nu"
