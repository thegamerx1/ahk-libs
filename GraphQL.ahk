#Include <requests>
class GraphQL {
	__New(url, options := "") {
		this.url := url
		this.options := EzConf(options, {type: "POST"})
	}

	query(query) {
		request := new requests(this.options.type, this.url)
		request.json := {query: query}
		res := request.send()
		data := res.json()
		if (data.errors) {
			throw JSON.dump(data.errors)
		}
		return data.data
	}
}