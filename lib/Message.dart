class Message {
  String text;
  int timestamp;
  bool send;
  Message(this.text, this.timestamp, this.send);
  getText() {
    return this.text;
  }

  getTimestamp() {
    return this.timestamp;
  }

  getSend() {
    return this.send;
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'timestamp': timestamp,
        'send': send,
      };
}
