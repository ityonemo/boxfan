defmodule Boxfan.GPIOBehaviour do
  @moduledoc """
  Behavior for GPIO operations to allow mocking in tests.
  """

  @callback open(pin :: non_neg_integer(), direction :: :input | :output) ::
              {:ok, reference()} | {:error, term()}
  @callback write(ref :: reference(), value :: 0 | 1) :: :ok | {:error, term()}
  @callback close(ref :: reference()) :: :ok
end
