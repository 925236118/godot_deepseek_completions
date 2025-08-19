@tool
class_name DeepSeekChatStream
extends Node

@export var ds_token: String = ''
@export_multiline var prompt: String = ""

signal message(msg: String)
signal generate_finish

@onready var http_client: HTTPClient = HTTPClient.new()

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
		"stream": true,
		"stream_options": null,
		"temperature": 0,
		"top_p": 1,
		"tools": null,
		"tool_choice": "none",
		"logprobs": false,
		"top_logprobs": null
	})

	#http_request.request_completed.connect(_http_request_completed)
	var connect_err = http_client.connect_to_host("https://api.deepseek.com")
	if connect_err != OK:
		push_error("连接服务器失败: " + error_string(connect_err))
		return
	while http_client.get_status() == HTTPClient.STATUS_CONNECTING or http_client.get_status() == HTTPClient.STATUS_RESOLVING:
		http_client.poll()
		#print("Connecting...")
		await get_tree().process_frame
	# 发送POST请求
	var err = http_client.request(HTTPClient.METHOD_POST, "/beta/chat/completions", headers, request_body)
	if err != OK:
		push_error("请求发送失败: " + error_string(err))
		return
	while http_client.get_status() == HTTPClient.STATUS_REQUESTING:
		http_client.poll()
		await get_tree().process_frame

	if http_client.has_response():
		headers = http_client.get_response_headers_as_dictionary()

		while http_client.get_status() == HTTPClient.STATUS_BODY:
			http_client.poll()
			var chunk = http_client.read_response_body_chunk()
			if chunk.size() == 0:
				await get_tree().process_frame
			else:
				var chunk_string = chunk.get_string_from_utf8()
				var data_array = chunk_string.split("\n")
				for data_string in data_array:
					if data_string.begins_with("data: "):
						data_string = data_string.replace("data: ", "")
						if data_string == "[DONE]":
							continue
						var json = JSON.new()
						var parse_err = json.parse(data_string)
						if parse_err != OK:
							push_error("JSON解析错误: " + json.get_error_message())
							push_error(data_string)
							return

						var data = json.get_data()
						if data and data.has("choices"):
							var choices := data["choices"] as Array
							message.emit(choices[0]["delta"]["content"])
							if choices[0].has("finish_reason") and choices[0].get("finish_reason") == "stop":
								generate_finish.emit()
						else:
							print(data)
							push_error("无效的响应结构")

func close():
	http_client.close()
