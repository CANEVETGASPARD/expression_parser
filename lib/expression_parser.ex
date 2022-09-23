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
      _ -> {char_value,nil,nil}
    end
  end
  def add({left_tree,mid_element,right_tree},{char_class,char_value}) do
    case {char_class,mid_element} do
      {:comparator, nil} -> {left_tree,char_value,right_tree}
      {:comparator, _} -> {{left_tree,mid_element,right_tree},char_value,nil}
      {:operator, nil} -> {left_tree,char_value,right_tree}
      {:operator, _} -> case String.match?(char_value, ~r{\*|\/}) do
        true -> {left_tree,mid_element,{right_tree,char_value,nil}}
        false -> {{left_tree,mid_element,right_tree},char_value,nil}
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

  def check_validity(_,{:illegal_char,_}) do
    raise("illegal char in the expression")
  end
  def check_validity(_,_) do

  end

  def parse(tree,[]) do
    tree
  end
  def parse(tree,[{:closing_parenthesis,_}|[]]) do
    tree
  end
  def parse(tree,[head|tail]) do
    check_validity(tree,head)
    parse(add(tree,head),tail)
  end
end
