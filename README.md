# ExpressionParser

Project based on the first homework of the UE FIAB. This project is made of a tokenizer function that transform a char chain into a list of useful elements (space are removed). Then a parse function transform the list into a tree in order to evaluate the equation using the last function eval. Unfortunatly my parse function do not handle parenthesis but we can still evaluate equation without parenthesis.

## Dependencies

Elixir and git need to be installed to run and test the project.

## project installation

clone the repo on a dedicated folder using the command bellow:

```cmd
project_loaction> git clone https://github.com/CANEVETGASPARD/expression_parser.git
```

## Compile and run 

Use your command line interpreter and move to the project directory and run the following commands.

```console
project_loaction> mix compile
Compiling 1 file (.ex)
Generated expression_parser app
```

```console
project_loaction> iex -S mix  
Interactive Elixir (1.14.0) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)>
```

Then you will be able to try the tokenize, parse and eval function by following the below rules.

## Rules to try ExpressionParser functions

**/!\ Disclaimer: As I said before, my parser function cannot handle parenthesis but my tokenize function do. Thus do not try to put parenthesis within char chain for eval and parse function but do not hesitate to do it for tokenize function.**

- _tokenize_ function take a char chain as input and renturn the list of char chain elements.

```console
iex(1)> ExpressionParser.tokenize("30 > 50") 
[number: "30", comparator: ">", number: "50"]
```

- _parse_ function take the tokenized list of the char chain and nil object as input and return the tree of the given list.

```console
iex(2)> token = ExpressionParser.tokenize("30 > 50") 
[number: "30", comparator: ">", number: "50"]
iex(3)> token = ExpressionParser.parse(token,nil)    
{{:number, "30"}, {:comparator, ">"}, {:number, "50"}}
```

- _eval_ function take the char chain and the variable table (can be empty if there is no variable in the expression) as input and return true if the equation is verified and false if it is not.

```console
iex(4)> token = ExpressionParser.eval("3<y",%{"y"=>5}) 
true
iex(5)> expression = "50*3 + 40/4 >= 4*40/2"
"50*3 + 40/4 >= 4*40/2"
iex(6)> ExpressionParser.eval(expression,%{}) 
true
```

## Contributing

If you want to contribute and fix my parenthesis problem, you can use mix test tool. To do so you just have to put your tests within the expression_parser_test.exs file and run the command below:

```console
project_loaction> mix test
```

It will help you inspect the output of your new immplementations

