# Deterministic Randomness in Elixir

Randomness in programming can be challenging, especially when we need consistent,
repeatable results. This article explores how to manage this using Elixir, a
functional programming language known for its clarity and ease of use. We'll
start by reviewing how to create random values. Then, we'll move on to
techniques for ensuring these values remain consistent for reproducibility each
time we run a program. This approach is particularly useful in testing scenarios
or simulations where reproducibility is key.

First, let's set up our working environment:
```bash
mkdir simulixir
cd simulixir
```

With our workspace `simulixir` set up (a name only a coder could like) we're set to begin.
Before we explore the methods of deterministic randomness, let's cover the basics. We'll
start with the straightforward approach to producing random values in Elixir.

_All the code you'll see is in [this](https://github.com/mrdimosthenis/simulixir)
repo, with different commits for each section._

## The Impure Way

Creating random numbers in the impure way is quite straightforward. This method,
while simple, lacks the predictability we often seek in functional programming.

Start by creating a file named `impure.exs`. This file will be our playground for the
impure approach. We'll write a small script that produces a random number and prints
it out. The code is as simple as it can be:
```elixir
x = :rand.uniform()
IO.puts("x: #{x}")
```

When we run `elixir impure.exs`, the script is executed and the `:rand.uniform()` function
creates a random number between 0 and 1. Naturally, executing the script multiple
times, different values are produced. But what if we want consistent results?
Let's see how to achieve that.

Begin by adding these lines at the start of the file:
```elixir
seed = 1000
:rand.seed(:exs1024, seed)
```

A seed serves as the initial trigger in random number creation, acting as a fixed
starting point that determines the sequence of values. When the same seed is used,
it ensures that the produced values remain identical in each execution. This is
achieved by the `:rand.seed(:exs1024, seed)` statement in our script. Here, `:exs1024`
specifies the algorithm that creates the random numbers, which is suitable for
statistical simulations.

But what if we ask for another random number before setting `x`?
```elixir
seed = 1000
:rand.seed(:exs1024, seed)
_ = :rand.uniform() # <- new line
x = :rand.uniform()
IO.puts("x: #{x}")
```

The new line changes the sequence of the creation. So, the line `x = :rand.uniform()`
doesn't give us the first number in the sequence anymore. It gives us the second number.
Because of this new line, the number we see for `x` is now different from before,
even though we're using the same seed.

## Shifting to Generators

Generators offer a more refined and controllable approach to producing random values. This is
crucial in scenarios where we need predictable and reproducible randomness, such as in testing
or simulations.

To demonstrate this concept, let's create a new file named `generators.exs`. This script
will be our exploration ground for working with generators. Here's the initial setup:
```elixir
Mix.install([
  {:minigen, "~> 0.1", manager: :rebar3}
])
alias :minigen, as: MG
seed = 1000

x_gen = MG.float()
x = x_gen |> MG.run_with_seed(seed)
IO.puts("x: #{x}")
```

In this script, we're using [minigen](https://hexdocs.pm/minigen/minigen.html).
A library in the Erlang ecosystem that I might know a thing or two about.
It's appropriate for generating pure random data for realistic simulations.
The `MG.float()` creates a generator for floating-point numbers.
By using `MG.run_with_seed(seed)`, we ensure that the generated value is reproducible
and consistent across runs, as long as the seed remains the same.

Now, let's consider a scenario where we set a different random number before `x`. Will
the behavior of our generator change?
```elixir
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
```

Here, we added two new lines before generating `x`. These lines also generate a random float,
but do not affect the value of `x`. This demonstrates the isolation and predictability of
this method. Each generator's behavior stays the same, unaffected by irrelevant generators.

Next, we'll expand our exploration by introducing more complex generator constructs.
We'll see how to transform and combine generators to create versatile and controlled
random values. This approach not only enhances our ability to control randomness but also
aligns with the functional programming paradigm, emphasizing immutability and predictability.

## Transform and Combine Generators

Generators can be manipulated to create complex random data structures. This is particularly
useful when you need to simulate scenarios that require more than simple random numbers.
Let's explore how to do this.

In our `generators.exs` script, we'll first demonstrate generator transformation.
This involves modifying the output of a generator. As an example, by applying `MG.map`,
we can alter a float generator to produce boolean values instead.
```elixir
b_gen = MG.map(x_gen, fn r -> r < 0.5 end)
b = b_gen |> MG.run_with_seed(seed)
IO.puts("b: #{b}")
```

Here, `b_gen` transforms each float from `x_gen` into a boolean.

Moving on, our next step in `generators.exs` involves combining several generators.
This process enables the creation of composite structures, such as tuples or lists,
from basic generators. We'll exemplify this by employing `MG.map3` to merge
float, boolean, and integer generators, crafting a generator that outputs tuples.
```elixir
i_gen = MG.integer(15)
t_gen = MG.map3(x_gen, b_gen, i_gen, fn r1, r2, r3 -> {r1, r2, r3} end)
t = t_gen |> MG.run_with_seed(seed)
IO.puts("t: #{inspect(t)}")
```

Here, `t_gen` combines `x_gen`, `b_gen`, and `i_gen` to create a tuple of
a float, a boolean, and an integer.

Finally, let's create a list generator that depends on the output of another generator.

In the code snippet below, `l_gen` constructs a boolean list whose length is dictated
by the `MG.integer(8)` generator:
```elixir
l_gen = MG.then(MG.integer(8), fn r -> MG.list(MG.boolean(), r) end)
l = l_gen |> MG.run_with_seed(seed)
IO.puts("l: #{inspect(l)}")
```

Run the script with `elixir generators.exs`. The follwing values will be printed:
```
x: 0.27586903946041397
b: true
t: {0.27586903946041397, true, 10}
l: [false, true]
```

These methods highlight the adaptability of generators:
* Using transformation methods like `map` and `map3`, we effectively create varied structures.
* The `then` function introduces an additional level of randomness. This new randomness
might dependent on previous results.

Together, these techniques enable the creation of diverse yet predictable data sets,
ideal for complex applications.

## Purely Functional Simulations

We will create and run simulations of algorithms for three different situations.
Each algorithm's code will be in its own file, and they all should start with these lines:
```elixir
Mix.install([
  {:minigen, "~> 0.1", manager: :rebar3}
])
alias :minigen, as: MG
seed = 1000

simulate = fn gen ->
  gen
  |> Stream.iterate(fn g ->
    MG.then(g, fn _ -> gen end)
  end)
  |> Enum.reduce(
       {0, 0},
       fn g, {i_acc, n_acc} ->
         i =
           case MG.run_with_seed(g, seed) do
             true -> i_acc + 1
             false -> i_acc
           end

         n = n_acc + 1
         IO.puts("estimation: #{i / n} --- sample_size: #{n}")
         {i, n}
       end
     )
end
```

The `simulate` function is designed to conduct a series of experiments, taking
a boolean generator as its only parameter. This generator is used to simulate
new experiments consecutively. The use of a `seed` ensures that these simulations
are consistent and can be replicated exactly in subsequent runs. The function
keeps track of the number of times the generator returns `true` and
the total number of experiments conducted. This allows for observing how
the ratio of `true` results to the total number of experiments evolves as
more simulations are performed.

## Coin Toss

In this section, we will simulate a classic probabilistic scenario: a coin toss.
We'll use a boolean generator, which produces a `true` or `false` value each time,
mimicking the flip of a coin.

Create a file named `coin_toss.exs`. Put the initial setup code from the previous
section at the start of this file. Then, add these lines at the end:
```elixir
b_gen = MG.boolean()
simulate.(b_gen)
```

When we run this script with `elixir coin_toss.exs`, it will simulate a series of coin tosses.
Due to the usage of generators, the results are predictable and consistent. As such,
each time we execute the script, we will get the exact same sequence of outcomes,
demonstrating the deterministic nature of the simulation. The output will be exactly as follows:
```
estimation: 1.0 --- sample_size: 1
estimation: 1.0 --- sample_size: 2
estimation: 0.6666666666666666 --- sample_size: 3
estimation: 0.75 --- sample_size: 4
estimation: 0.8 --- sample_size: 5
...
estimation: 0.5000635028152914 --- sample_size: 23621
estimation: 0.5000423334180002 --- sample_size: 23622
estimation: 0.5000211658129788 --- sample_size: 23623
```

As expected, when the size of the sample gets larger, the estimation gets closer to `0.5`.

## Pi Estimation

We'll now address a geometrical challenge: estimating the value of `Pi` using a Monte
Carlo simulation. This method generates random points within a unit square and determines
how many fall inside a quadrant (a quarter circle) inscribed within the square. The ratio
of the points inside the quadrant to the total number of points is an approximation of `Pi/4`.

Create the `pi_estimation.exs` file and include the setup code from the previous sections.
Then, define a specific generator for this simulation:
```elixir
x_gen = MG.float()
y_gen = MG.float()
point_gen = MG.map2(x_gen, y_gen, fn x, y -> [x, y] end)
b_gen = MG.map(point_gen, fn [x, y] -> x * x + y * y < 1 end)

simulate.(b_gen)
```

Run the simulation with `elixir pi_estimation.exs`. As the simulation progresses and the
sample size grows, the estimation becomes more precise:
```
estimation: 1.0 --- sample_size: 1
estimation: 1.0 --- sample_size: 2
estimation: 1.0 --- sample_size: 3
estimation: 0.75 --- sample_size: 4
estimation: 0.8 --- sample_size: 5
...
estimation: 0.7853973376361436 --- sample_size: 7437
```

Multiplying `0.7853973376361436` by `4` gives `3.1415893505445744`, which is not a bad
estimation of Pi.

## The Monty Hall Game

In this final simulation, we explore the Monty Hall problem. This classic puzzle involves
choosing one of three doors: behind one of them there is a car (the prize), and behind the
others, goats. After the player's initial choice, Monty, the host, reveals a goat behind
one of the remaining doors. The player then decides whether to stick with their first choice
or switch. Our setup will estimate the probability of winning when the player switches
their choice.

Let's create one more file named `monty_hall.exs` and place the usual part of code at the start.

At first, we will design the generator that defines Monty's behaviour.
His selection depends on the player's initial choice and the content of the doors:
```elixir
monty_opens_gen = fn player_init_choice, doors ->
  monty_choices = Enum.reject([0, 1, 2], &(&1 == player_init_choice))
  [monty_first_choice, monty_second_choice] = monty_choices

  case {Enum.at(doors, monty_first_choice), Enum.at(doors, monty_second_choice)} do
    {:car, :goat} ->
      MG.always(monty_second_choice)

    {:goat, :car} ->
      MG.always(monty_first_choice)

    {:goat, :goat} ->
      monty_choices
      |> MG.shuffled_list()
      |> MG.map(&Enum.at(&1, 0))
  end
end
```

Then, we will implement a new function. It accepts three parameters:
Monty's selection, the content of the doors, and the player's initial choice.
It returns a generator that checks whether the player won the game or not:
```elixir
did_player_win_gen = fn monty_opens_gen, doors, player_init_choice ->
  MG.then(
    monty_opens_gen,
    fn monty_opens ->
      [prayer_final_choice] =
        Enum.reject(
          [0, 1, 2],
          &(&1 == player_init_choice || &1 == monty_opens)
        )

      prayer_final_choice_gen = MG.always(prayer_final_choice)

      MG.map(
        prayer_final_choice_gen,
        fn prayer_final_choice ->
          Enum.at(doors, prayer_final_choice) == :car
        end
      )
    end
  )
end
```

At last, we will combine the above defined generators to design the simulation:
```elixir
b_gen =
  MG.then(
    MG.shuffled_list([:car, :goat, :goat]),
    fn doors ->
      MG.then(
        MG.integer(3),
        fn player_init_choice ->
          player_init_choice
          |> monty_opens_gen.(doors)
          |> did_player_win_gen.(doors, player_init_choice)
        end
      )
    end
  )

simulate.(b_gen)
```

If we add these three definitions to the `monty_hall.exs` file and execute the script,
we'll see that when the player changes their initial decision, the probability of winning
is about `0.6666666666666667`.

## Conclusion

To wrap up, our journey through deterministic randomness focused on generators. We saw how
they make random values predictable and repeatable. From starting with simple random numbers
to tackling complex simulations like the Monty Hall problem, we used generators to keep
everything consistent.
