defmodule ExpressionParserTest do
  use ExUnit.Case
  doctest ExpressionParser

  test "tokenize" do
    assert ExpressionParser.tokenize(" ( 123 + 55) ") == [{:opening_parenthesis,"("}, {:number,"123"}, {:operator,"+"}, {:number,"55"}, {:closing_parenthesis,")"}]
    assert ExpressionParser.tokenize(" (var- 55)") == [{:opening_parenthesis,"("}, {:variable,"var"}, {:operator,"-"}, {:number,"55"}, {:closing_parenthesis,")"}]
    assert ExpressionParser.tokenize(" ( var * 55) ") == [{:opening_parenthesis,"("}, {:variable,"var"}, {:operator,"*"}, {:number,"55"}, {:closing_parenthesis,")"}]
    assert ExpressionParser.tokenize(" ( 123 / 55) ") == [{:opening_parenthesis,"("}, {:number,"123"}, {:operator,"/"}, {:number,"55"}, {:closing_parenthesis,")"}]
    assert ExpressionParser.tokenize(" (var <= 55 ) ") == [{:opening_parenthesis,"("}, {:variable,"var"}, {:comparator,"<="}, {:number,"55"}, {:closing_parenthesis,")"}]
    assert ExpressionParser.tokenize(" (var >= 55 ) ") == [{:opening_parenthesis,"("}, {:variable,"var"}, {:comparator,">="}, {:number,"55"}, {:closing_parenthesis,")"}]
    assert ExpressionParser.tokenize(" (var < 55 ) ") == [{:opening_parenthesis,"("}, {:variable,"var"}, {:comparator,"<"}, {:number,"55"}, {:closing_parenthesis,")"}]
    assert ExpressionParser.tokenize(" (var > 55 ) ") == [{:opening_parenthesis,"("}, {:variable,"var"}, {:comparator,">"}, {:number,"55"}, {:closing_parenthesis,")"}]
    assert ExpressionParser.tokenize(" ( 123!= 55) ") == [{:opening_parenthesis,"("}, {:number,"123"}, {:comparator,"!="}, {:number,"55"}, {:closing_parenthesis,")"}]
    assert ExpressionParser.tokenize(" ( 123= 55) ") == [{:opening_parenthesis,"("}, {:number,"123"}, {:comparator,"="}, {:number,"55"}, {:closing_parenthesis,")"}]
    assert ExpressionParser.tokenize(" ( 123 @ 55) ") == [{:opening_parenthesis,"("}, {:number,"123"}, {:illegal_char,"@"}, {:number,"55"}, {:closing_parenthesis,")"}]
    assert ExpressionParser.tokenize(" ( 123 + 55) <= 3500 ") == [{:opening_parenthesis,"("}, {:number,"123"}, {:operator,"+"}, {:number,"55"}, {:closing_parenthesis,")"}, {:comparator,"<="}, {:number,"3500"}]
  end

  test "add" do
    assert ExpressionParser.add(nil,{:opening_parenthesis,"("}) == {nil,nil,nil}
    assert ExpressionParser.add(nil,{:number,"51"}) == {"51",nil,nil}
    assert ExpressionParser.add(nil,{:variable,"x"}) == {"x",nil,nil}
    assert ExpressionParser.add({"x","+",nil},{:variable,"x"}) == {"x","+","x"}
    assert ExpressionParser.add({"x","+",{"51","+",nil}},{:variable,"y"}) == {"x","+",{"51","+","y"}}
    assert ExpressionParser.add({"x","+",{"51","+",nil}},{:opening_parenthesis,"("}) == {"x","+",{"51","+",{nil,nil,nil}}}
  end

  test "parse" do
    tokenized_char = ExpressionParser.tokenize(" ( 123 + 55) ")
    assert ExpressionParser.parse(nil,tokenized_char) == {"123","+","55"}
    tokenized_char = ExpressionParser.tokenize("( 123 + 55*y)/33 <= 3500 ")
    assert ExpressionParser.parse(nil,tokenized_char) == {{{"123","+",{"55","*","y"}},"/","33"},"<=","3500"}
    tokenized_char = ExpressionParser.tokenize("( 123 + 55 + y)/33 <= 3500 ")
    assert ExpressionParser.parse(nil,tokenized_char) == {{{{"123","+","55"},"+","y"},"/","33"},"<=","3500"}
    tokenized_char = ExpressionParser.tokenize("( 123 / 55*y)/33 <= 3500 ")
    assert ExpressionParser.parse(nil,tokenized_char) == {{{"123","/",{"55","*","y"}},"/","33"},"<=","3500"}
    tokenized_char = ExpressionParser.tokenize(" 123 + 55*3 + 5 <= 123 + 55*3 + 5 ")
    assert ExpressionParser.parse(nil,tokenized_char) == {{{"123", "+", {"55", "*", "3"}}, "+", "5"}, "<=",{{"123", "+", {"55", "*", "3"}}, "+", "5"}}
  end

  test "parse error handling" do
    tokenized_char_with_illegal_char = ExpressionParser.tokenize(" ( 123 @ 55) ")
    assert_raise(RuntimeError, "illegal char in the expression", fn  -> ExpressionParser.parse(nil,tokenized_char_with_illegal_char) end)
    tokenized_char_with_illegal_parenthesis = ExpressionParser.tokenize(") ( 123 + 55) ")
    assert_raise(RuntimeError, "can't start expression with a closing parenthesis", fn  -> ExpressionParser.parse(nil,tokenized_char_with_illegal_parenthesis) end)
    tokenized_char_with_illegal_parenthesis = ExpressionParser.tokenize("() 123 + 55) ")
    assert_raise(RuntimeError, "can't put closing parenthesis just after opening parenthesis", fn  -> ExpressionParser.parse(nil,tokenized_char_with_illegal_parenthesis) end)
    tokenized_char_with_illegal_comparator = ExpressionParser.tokenize("= ( 123 + 55) ")
    assert_raise(RuntimeError, "can't start expression with a comparator", fn  -> ExpressionParser.parse(nil,tokenized_char_with_illegal_comparator) end)
    tokenized_char_with_illegal_comparator = ExpressionParser.tokenize("(<= 123 + 55) ")
    assert_raise(RuntimeError, "can't put comparator just after opening parenthesis", fn  -> ExpressionParser.parse(nil,tokenized_char_with_illegal_comparator) end)
    tokenized_char_with_illegal_operator = ExpressionParser.tokenize("+ ( 123 + 55) ")
    assert_raise(RuntimeError, "can't start expression with an operator", fn  -> ExpressionParser.parse(nil,tokenized_char_with_illegal_operator) end)
    tokenized_char_with_illegal_operator = ExpressionParser.tokenize("(* 123 + 55) ")
    assert_raise(RuntimeError, "can't put operator just after opening parenthesis", fn  -> ExpressionParser.parse(nil,tokenized_char_with_illegal_operator) end)
  end
end
