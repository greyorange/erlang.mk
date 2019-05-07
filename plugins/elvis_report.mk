ELVIS_PARALLEL_JOBS ?= erlang:system_info(schedulers)

## Generates an HTML report with elvis style warnings

define elvis_report.erl
	application:set_env(elvis, no_output, true),
	ParallelJobs = ${ELVIS_PARALLEL_JOBS},
	application:set_env(elvis, parallel, ParallelJobs),
	io:format("Running elvis style checker using ~p parallel jobs... ", [ParallelJobs]),
	Result = elvis_core:rock(),
	io:format("[DONE]~nGenerating report... "),

	DiffOutput = string:tokens(os:cmd("git diff HEAD~1 HEAD -U0 --no-color"), "\n"),
	{_, _, Changed} = lists:foldl(
											fun(DiffLine, {File, Line, Changes} = AccIn) ->
												case DiffLine of
													"--- a/" ++ _ ->
														AccIn;
													"+++ b/" ++ NewFile ->
														{NewFile, 0, Changes};
													"@@ " ++ LinesDesc ->
														LinesDescTokens = string:tokens(LinesDesc, " "),
														AddedLines = lists:nth(2, LinesDescTokens),
														"+" ++ AddedLineNumbers = AddedLines,
														NewLine = erlang:binary_to_integer(hd(re:split(AddedLineNumbers, ","))),
														{File, NewLine, Changes};
													"+" ++ _ ->
														NewChanges = maps:put({File, Line}, true, Changes),
														{File, Line+1, NewChanges};
													_ ->
														AccIn
													end
											end,
											{undefined, 0, maps:new()}, DiffOutput),

	{Output, Count} =
		case Result of
			ok ->
				{[], 0};
			{fail, Results} ->
				lists:mapfoldl(
					fun(FileResult, FileCountAccIn) ->
						F = maps:get(file, FileResult),
						Path = case is_map(F) of true -> maps:get(path, F); false -> F end,
						{ok, Rules} = maps:find(rules, FileResult),
						lists:mapfoldl(
							fun(Rule, RuleCountAccIn) ->
								case maps:find(items, Rule) of
									{ok, Items} ->
										Name = erlang:atom_to_list(maps:get(name, Rule)),
										lists:mapfoldl(
											fun(Item, ItemCountAccIn) ->
												case maps:find(message, Item) of
													{ok, Message} ->
														{Line, LineInt} =
															case maps:find(line_num, Item) of
																{ok, LineInt1} ->
																	{erlang:integer_to_list(LineInt1), LineInt1};
																error ->
																	{"-", 0}
															end,
														Info = maps:get(info, Item),
														FormattedMessage = io_lib:format(Message, Info),
														EscapedMessage = re:replace(FormattedMessage, [34], [92,92,34], [{return, list}, global]),

														case maps:get({Path, LineInt}, Changed, false) of
															true ->
																file:write_file(".phabricator-lint",
																								[
																									"{\\"name\\": \\"Style Warning\\", \\"code\\": \\"", Name, "\\", "
																									" \\"severity\\": \\"warning\\", \\"path\\": \\"", Path, "\\", "
																									" \\"line\\": ", Line, ", \\"description\\": \\"", EscapedMessage, "\\"}\n"],
																								[append]);
															false ->
																ok
														end,

														{["<tr><td>", Path, "</td><td>",
															Name, "</td><td>", Line, "</td><td>",
															FormattedMessage, "</td></tr>\n"], ItemCountAccIn+1};
													error ->
														{[], ItemCountAccIn}
												end
											end,
											RuleCountAccIn,
											Items
										);
									error ->
										{[], RuleCountAccIn}
								end
							end,
							FileCountAccIn,
							Rules
						)
					end,
					0,
					Results
				)
		end,
	GenTime = httpd_util:rfc1123_date(),
	Header =
		[
			"<html>\n<head>\n<title>Elvis Style Report - $(PROJECT)</title>\n<style>\n",
			"table, th, td { border: 1px solid black; border-collapse: collapse; }\n",
			"th, td { padding: 15px; }\n",
			"table tr:nth-child(even) { background-color: #eee; }\n",
			"table tr:nth-child(odd) { background-color: #fff; }\n",
			"table th { color: white; background-color: #555; }\n"
			"</style>\n</head>\n<body>\n",
			"<h2>Elvis Style Report - $(PROJECT)</h2>\n",
			"<h3>Number of Warnings: ", erlang:integer_to_list(Count), "</h3>",
			"<h4>Report generated at: ", GenTime, "</h4>",
			"<table>",
			"<tr><th>File</th><th>Rule</th><th>Line</th><th>Message</th></tr>"
		],
	Footer = "</table></body></html>",
	ok = file:write_file("$(ELVIS_HTML_OUT)", [Header, Output, Footer]),
	io:format("[DONE]~n"),
	io:format("Number of style warnings: ~p~n", [Count]),
	halt(0).
endef

elvis_report:
	$(verbose) $(call erlang,$(call elvis_report.erl))
	$(verbose) echo "Elvis Report generated at elvis_report.html"
