# Nushell Prompt Config File

# Global Functions
use std null-device
export def main [] {[(session), (directory), (duration), (gitstat)] | str join ""}

# Global Helpers
def style [] {
    {
        USER_STYLE: (ansi green_bold),
        ADMIN_STYLE: (ansi red_bold),
        DIRECTORY_STYLE: (ansi blue),
        DURATION_STYLE: (ansi yellow),
        DATETIME_STYLE: (ansi purple),
        BRANCH_STYLE: (ansi light_yellow),

        UPDATED_STYLE: $"(ansi light_cyan)(char record_separator)",
        OUTDATED_STYLE: $"(ansi light_red)(char unit_separator)",
        AHEAD_STYLE: $"(ansi green)(char branch_ahead)",
        BEHIND_STYLE: $"(ansi yellow)(char branch_behind)",

        STAGED_STYLE: $"(ansi light_blue)S",
        UNSTAGED_STYLE: $"(ansi dark_gray)U",
        NEW_STYLE: $"(ansi green)N",
        ADD_STYLE: $"(ansi green)A",
        MODIFY_STYLE: $"(ansi yellow)M",
        DELETE_STYLE: $"(ansi red)D",
        CONFLICT_STYLE: $"(ansi light_purple)C"
    }
}

# Base Functions
def session [] {
    let color = (style)
    let user = (username)
    let host = (hostname)
    let ssh = (remote)

    if ($ssh) {
        $"($color.USER_STYLE)($user)(ansi dark_gray)@($color.USER_STYLE)($host)(ansi reset) "
    } else {
        $"($color.USER_STYLE)($user)(ansi dark_gray):($color.USER_STYLE)($host)(ansi reset) "
    }
}

def directory [] {
    let color = (style)
    let cwd = (location)

    if (is-admin) {
        $"($color.ADMIN_STYLE)($cwd | str replace --all \ /)(ansi reset) "
    } else {
        $"($color.DIRECTORY_STYLE)($cwd | str replace --all \ /)(ansi reset) "
    }
}

def duration [] {
    let color = (style)
    mut seconds = ($env.CMD_DURATION_MS | into int) / 1000
    mut label = [$"[($color.DURATION_STYLE)took "]

    if ($seconds >= 3600) {
        $label = ($label | append $"($seconds // 3600)h ($seconds mod 3600 // 60)m ")
        $seconds = ($seconds mod 60)
    } else if ($seconds >= 60) {
        $label = ($label | append $"($seconds // 60)m ")
        $seconds = ($seconds mod 60)
    } else if ($seconds <= 0.1) {
        $seconds = 0.1
    }

    ($label | append $"($seconds | math round -p 1)s(ansi reset)] " | str join)
}

def datetime [] {
    let color = (style)
    let date = (date now | format date "%m/%d/%y")
    let day = (date now |format date "%a" | str upcase)
    let time = (date now | format date "%I:%M:%S")
    let ext = (date now |format date "%P" | str upcase)

    if (is-terminal -i) {
        $"[($color.DATETIME_STYLE)($date) ($day)(ansi white) | ($color.DATETIME_STYLE)($time) ($ext)(ansi reset)] "
    } else {
        ""
    }
}

# Base Helpers
def username [] {
    if ("USERNAME" in $env) {
        $env.USERNAME
    } else if ("USER" in $env) {
        $env.USER
    } else {
        ""
    }
}

def hostname [] {
    if ("COMPUTERNAME" in $env) {
        $env.COMPUTERNAME
    } else if ("HOSTNAME" in $env) {
        $env.HOSTNAME
    } else {
        ""
    }
}

def remote [] {
    if ("SSH_CONNECTION" in $env) {
        true
    } else if ("SSH_CLIENT" in $env) {
        true
    } else if ("SSH_TTY" in $env) {
        true
    } else {
        false
    }
}

def location [] {
    if ($env.PWD == $nu.home-path) {
        "~"
    } else if ($env.PWD | str contains $env.HOMEPATH) {
        $"~/($env.PWD | str replace $env.HOMEPATH ~ | path split | range 1.. | path join | path relative-to $nu.home-path)"
    } else {
        $"($env.PWD | str replace : (char nul) | path parse | str downcase parent | path join)"
    }
}

# Git Functions
def gitstat [] {
    let color = (style)
    let info = (git --no-optional-locks status --porcelain=2 --branch err> (null-device) | str trim | lines)
    let data = (generator $info)

    if ($info | is-empty) {
        ""
    } else {
        $"[((combiner (brancher $data) (stager $data) (unstager $data)) | str join)(ansi reset)] "
    }
}

# Git Helpers
def generator [info] {
    let color = (style)
    mut list = []

    mut data = ($info | reduce -f {
        output: [],
        staged: {a: 0, m: 0, d: 0},
        unstaged: {n: 0, m: 0, d: 0, c: 0},
        track: false,
        remote: false
    } {|list, context|
        let line = ($list | split row -n 3 " ")
        mut output = $context.output
        mut staged = $context.staged
        mut unstaged = $context.unstaged
        mut track = $context.track
        mut remote = $context.remote

        if ($track == false) {
            if (($line.0 == "#") and ($line.1 == "branch.upstream")) {
                $track = true
            }
        }

        if ($line.0 == "#") {
            if ($line.1 == "branch.oid") {
                $output = [$"($color.BRANCH_STYLE)\(HEAD detached at (check $line B)\)(ansi reset)"]
            } else if ($line.1 == "branch.head") {
                if ($line.2 != "\(detached\)") {
                    $output = ($output | update 0 $"($color.BRANCH_STYLE)($line.2)(ansi reset)")
                }
            } else if ($track) {
                if ($line.1 == "branch.ab") {
                    $remote = true
                    if ((check $line B).an.0 != "0") {
                        $output = ($output | append $" ($color.AHEAD_STYLE)((check $line B).an.0)(ansi reset)")
                    }; if ((check $line B).bn.0 != "0") {
                        $output = ($output | append $" ($color.BEHIND_STYLE)((check $line B).bn.0)")
                    }
                }
            }
        }

        if ($line.0 == "?") {
            $unstaged = ($unstaged | update n ($unstaged.n + 1))
        } else if ($line.0 == "u") {
            $unstaged = ($unstaged | update c ($unstaged.c + 1))
        } else if (($line.0 == "1") or ($line.0 == "2")) {
            $staged = (count $staged (check $line S).0)
            $unstaged = (count $unstaged (check $line S).1)
        }

        {
            output: $output,
            staged: $staged,
            unstaged: $unstaged,
            track: $track,
            remote: $remote
        }
    })

    return $data
}

def check [line, section] {
    if ($section == "B") {
        if ($line.1 == "branch.oid") {
            ($line.2 | str substring 0..7)
        } else if ($line.1 == "branch.ab") {
            ($line.2 | parse "+{an} -{bn}")
        }
    } else if ($section == "S") {
        if (($line.0 == "1") or ($line.0 == "2")) {
            ($line.1 | split chars)
        }
    }
}

def count [value, status] {
    if ($status == "A") {
        ($value | update a (($value.a | into int) + 1))
    } else if ($status == "M") {
        ($value | update m (($value.m | into int) + 1))
    } else if ($status == "D") {
        ($value | update d (($value.d | into int) + 1))
    } else {
        $value
    }
}

def combiner [branch, stages, unstages] {
    let color = (style)
    mut combined = $branch

    if (($stages | length) > 0) {
        $combined = ($combined | append $"(ansi reset) | ($color.STAGED_STYLE)(ansi reset):" | append $stages)
    }; if (($unstages | length) > 0) {
        $combined = ($combined | append $"(ansi reset) | ($color.UNSTAGED_STYLE)(ansi reset):" | append $unstages)
    }

    return $combined
}

def brancher [data] {
    let color = (style)
    mut branch = []

    if ($data.track) {
        if ($data.remote == false) {
            $branch = ($data.output | append $" ($color.OUTDATED_STYLE)")
        } else if (($data.output | length) < 2)  {
            $branch = ($data.output | append $" ($color.UPDATED_STYLE)")
        } else {
            $branch = $data.output
        }
    } else {
        $branch = $data.output
    }

    return $branch
}

def stager [data] {
    let color = (style)
    mut stages = []

    if ($data.staged.a > 0) {
        $stages = ($stages | append $" ($color.ADD_STYLE)($data.staged.a)(ansi reset)")
    }; if ($data.staged.m > 0) {
        $stages = ($stages | append $" ($color.MODIFY_STYLE)($data.staged.m)(ansi reset)")
    }; if ($data.staged.d > 0) {
        $stages = ($stages | append $" ($color.DELETE_STYLE)($data.staged.d)(ansi reset)")
    }

    return $stages
}

def unstager [data] {
    let color = (style)
    mut unstages = []

    if ($data.unstaged.c > 0) {
        $unstages = ($unstages | append $" ($color.CONFLICT_STYLE)($data.unstaged.c)(ansi reset)")
    }; if ($data.unstaged.n > 0) {
        $unstages = ($unstages | append $" ($color.NEW_STYLE)($data.unstaged.n)(ansi reset)")
    }; if ($data.unstaged.m > 0) {
        $unstages = ($unstages | append $" ($color.MODIFY_STYLE)($data.unstaged.m)(ansi reset)")
    }; if ($data.unstaged.d > 0) {
        $unstages = ($unstages | append $" ($color.DELETE_STYLE)($data.unstaged.d)(ansi reset)")
    }

    return $unstages
}
