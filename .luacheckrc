std = "luajit"

globals = {
  "vim",
  "nixInfo",
}

read_globals = {
  "require",
}

max_line_length = false

-- Ignore unused loop variables starting with _
ignore = {
  "212/_.*",
}

exclude_files = {
  "result",
  "result/**",
}
