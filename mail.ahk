class Mail {
	__New(from, to, obj := "") {
		this.from := from
		this.data := obj
		this.to := to
		this.attachments := []
	}

	attach(path) {
		this.attachments.push(path)
	}

	send(message, subject) {
		static schema := "http://schemas.microsoft.com/cdo/configuration/"
		pdo := ComObjCreate("CDO.Message")

		pdo.from := """" (this.data.nick ? this.data.nick : "Unkown") """ <" (this.data.reply ? this.data.reply : this.to) ">"
		pdo.TextBody := message
		pdo.subject := subject
		pdo.To := this.to

		data := {}
		data.smtpserver := this.data.smtp ? this.data.smtp : "smtp.gmail.com"
		data.smtpserverport := 465
		data.smtpusessl := True
		data.sendusing := 2
		data.smtpauthenticate := 1
		data.sendusername := this.from
		data.sendpassword := this.data.password
		data.smtpconnectiontimeout := 60


		pfld := pdo.Configuration.Fields

		for field, value in data
			pfld.Item(schema field) := value

		pfld.Update()

		for key, value in this.attachments {
			pdo.AddAttachment(value)
		}

		pdo.Send()
	}
}