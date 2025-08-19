@tool
class_name DeepSeekChat
extends Node

var ds_token: String = ''
var prompt: String = ""

signal generate_finish(msg: String)

var http_request: HTTPRequest = null

func _ready() -> void:
	var node = HTTPRequest.new()
	add_child(node)
	http_request = node

func post_message(msg: String):
	# 准备请求数据
	var headers = [
		"Accept: application/json",
		"Authorization: Bearer %s" % ds_token,
		"Content-Type: application/json"
	]

	var request_body = JSON.stringify({
		"messages": [
			{
				"content": prompt,
				"role": "user"
			},
			{
				"content": "``` gdscript\n" + msg,
				"role": "assistant",
				"prefix": true
			}
		],
		"model": "deepseek-chat",
		"frequency_penalty": 0,
		"max_tokens": 2048,
		"presence_penalty": 0,
		"response_format": {
			"type": "text"
		},
		"stop": ["```"],
		"stream": false,
		"stream_options": null,
		"temperature": 0,
		"top_p": 1,
		"tools": null,
		"tool_choice": "none",
		"logprobs": false,
		"top_logprobs": null
	})

	http_request.request_completed.connect(_http_request_completed)

	# 发送POST请求
	var err = http_request.request( "https://api.deepseek.com/beta/chat/completions", headers, HTTPClient.METHOD_POST, request_body)
	if err != OK:
		push_error("请求发送失败: " + str(err))
		return

func _http_request_completed(result, response_code, headers, body: PackedByteArray):
	var json = JSON.new()
	var err = json.parse(body.get_string_from_utf8())
	if err != OK:
		push_error("JSON解析错误: " + json.get_error_message())
		push_error(body.get_string_from_utf8())
		return

	var data = json.get_data()
	if data and data.has("choices"):
		var choices := data["choices"] as Array
		generate_finish.emit(choices[0]["message"]["content"])
	else:
		print(data)
		push_error("无效的响应结构")
