Mix.install([
  {:minigen, "~> 0.1", manager: :rebar3}
])
alias :minigen, as: MG
seed = 1000

_gen = MG.float()                  # <- new line
_ = _gen |> MG.run_with_seed(seed) # <- new line

x_gen = MG.float()
x = x_gen |> MG.run_with_seed(seed)
IO.puts("x: #{x}")
