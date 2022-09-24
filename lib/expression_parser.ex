defmodule ExpressionParser do
  @moduledoc """
  Documentation for `ExpressionParser`.
  """

  @spec tokenize(binary) :: nil | [binary | {integer, integer}]
  @doc """

  """
  def tokenize(char_chain) do
    String.split(char_chain,~r{\s|\(|\)|\+|\-|\*|\/|=|!=|<=|<|>=|>}, trim: true, include_captures: true)
    |> Enum.filter(fn value -> value != " " end)
    |> Enum.map(fn char -> identify_char(char) end)
  end

  def identify_char(char) do
    cond do
      String.match?(char, ~r{^([0-9]*)$}) -> {:number, char}
      String.match?(char, ~r{^([a-z]*)$}) -> {:variable, char}
      String.match?(char, ~r{\(}) -> {:opening_parenthesis, char}
      String.match?(char, ~r{\)}) -> {:closing_parenthesis, char}
      String.match?(char, ~r{\+|\-|\*|\/}) -> {:operator, char}
      String.match?(char, ~r{!=|=|<=|<|>=|>}) -> {:comparator, char}
      true -> {:illegal_char, char}
    end
  end

  def add(nil, {char_class,char_value}) do
    case char_class do
      :opening_parenthesis -> {nil,nil,nil}
      _ -> {char_value,nil,nil} #only variables and numbers will arrived till this step
    end
  end
  def add({left_tree,mid_element,right_tree},{char_class,char_value}) do
    case {char_class,mid_element} do
      {:comparator, nil} -> {left_tree,char_value,right_tree}
      {:comparator, _} -> {{left_tree,mid_element,right_tree},char_value,nil}
      {:operator, nil} -> {left_tree,char_value,right_tree}
      {:operator, _} -> cond do
        String.match?(mid_element, ~r{!=|=|<=|<|>=|>}) -> {left_tree,mid_element,add(right_tree,{char_class,char_value})} #first level of importance
        String.match?(char_value, ~r{\*|\/}) -> {left_tree,mid_element,{right_tree,char_value,nil}} #second level of importance
        true -> {{left_tree,mid_element,right_tree},char_value,nil} #last level of importance (other operators)
      end
      {:closing_parenthesis, _} -> {{left_tree,mid_element,right_tree},nil,nil}
      {:opening_parenthesis, nil} -> {add(left_tree,{char_class,char_value}),mid_element,right_tree}
      {:opening_parenthesis, _} -> {left_tree,mid_element,add(right_tree,{char_class,char_value})}
      {_, nil} -> case left_tree do
        nil -> {char_value,mid_element,right_tree}
        _ -> {add(left_tree,{char_class,char_value}),mid_element,right_tree}
      end
      {_, _} -> case right_tree do
        nil -> {left_tree,mid_element,char_value}
        _ -> {left_tree,mid_element,add(right_tree,{char_class,char_value})}
      end
    end
  end
  def add(value,{_,char_value}) do #special case for operator. Is called when a comparator is in the midlle of the tree and a value (variable or number) is in the right tree
    {value,char_value,nil}
  end

  def check_validity(_,{:illegal_char,_},_) do
    {:error,"illegal char in the expression"}
  end
  def check_validity(nil,{char_class,_},error_message_map) do
    cond do
      Map.has_key?(error_message_map,char_class) -> {:error,error_message_map[char_class][:on_start]}
      true -> {nil,nil}
    end

  end
  def check_validity({nil,nil,nil},{char_class,_},error_message_map) do
    cond do
      Map.has_key?(error_message_map,char_class) -> {:error,error_message_map[char_class][:after_opening_parenthesis]}
      true -> {nil,nil}
    end
  end
  def check_validity(_,_,_) do
    {nil,nil}
  end

  def parse(tree,[]) do
    tree
  end
  def parse(tree,[{:closing_parenthesis,_}|[]]) do
    tree
  end
  def parse(tree,[head|tail]) do
    error_message =
      %{:comparator => %{:on_start => "can't start expression with a comparator", :after_opening_parenthesis => "can't put comparator just after opening parenthesis"},
      :operator => %{:on_start => "can't start expression with an operator", :after_opening_parenthesis => "can't put operator just after opening parenthesis"},
      :closing_parenthesis => %{:on_start => "can't start expression with a closing parenthesis", :after_opening_parenthesis => "can't put closing parenthesis just after opening parenthesis"}}

    {validity_atom,validity_message} = check_validity(tree,head,error_message)
    case validity_atom do
      :error -> raise(validity_message)
      _ -> parse(add(tree,head),tail)
    end
  end
end
