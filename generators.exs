Mix.install([
  {:minigen, "~> 0.1", manager: :rebar3}
])
alias :minigen, as: MG
seed = 1000

x_gen = MG.float()
x = x_gen |> MG.run_with_seed(seed)
IO.puts("x: #{x}")

b_gen = MG.map(x_gen, fn r -> r < 0.5 end)
b = b_gen |> MG.run_with_seed(seed)
IO.puts("b: #{b}")

i_gen = MG.integer(15)
t_gen = MG.map3(x_gen, b_gen, i_gen, fn r1, r2, r3 -> {r1, r2, r3} end)
t = t_gen |> MG.run_with_seed(seed)
IO.puts("t: #{inspect(t)}")

l_gen = MG.then(MG.integer(8), fn r -> MG.list(MG.boolean(), r) end)
l = l_gen |> MG.run_with_seed(seed)
IO.puts("l: #{inspect(l)}")
