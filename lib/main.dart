import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:bubble/bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker/emoji_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './Message.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:flutter/gestures.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Chat Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class LinkTextSpan extends TextSpan {
  LinkTextSpan({TextStyle style, String url, String text})
      : super(
            style: style,
            text: text ?? url,
            recognizer: new TapGestureRecognizer()
              ..onTap = () {
                if ((url.substring(0, 9) == "https://") ||
                    (url.substring(0, 8) == "http://")) {
                  launcher.launch(url);
                } else {
                  launcher.launch("https://" + url);
                }
              });
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    try {
      subscription = _db
          .collection("Chat")
          .document("Jay1")
          .snapshots()
          .listen((DocumentSnapshot snapshot) => onDatabaseUpdate(snapshot));
    } catch (E) {}

    getMessages();
    start = true;
    emoji = false;
    selectMode = false;
    read = false;
    iconData = Icons.insert_emoticon;
  }

  Future<void> onDatabaseUpdate(DocumentSnapshot snapshot) async {
    if ((!read)) {
      if ((snapshot.data["Jay2"].length != 0)) {
        read = true;
        final prefs = await SharedPreferences.getInstance();
        List<dynamic> pending = snapshot.data["Jay2"];
        setState(() {
          for (int i = 0; i < pending.length; i++) {
            Map rec = jsonDecode(pending[i]);
            Message recieve = new Message(
                rec["text"], new DateTime.now().millisecondsSinceEpoch, false);
            msgList.add(jsonEncode(recieve));
            prefs.remove("Jay2");
            prefs.setStringList("Jay2", msgList);
            textList.add(rec["text"]);
            timeList
                .add(DateFormat('yyyy-MM-dd  kk:mm').format(DateTime.now()));
            sendList.add(false);
            colorSelectList.add(Colors.transparent);
          }

          _db
              .collection("Chat")
              .document("Jay1")
              .setData({"Jay2": FieldValue.arrayRemove(pending)}).whenComplete(
                  () => read = false);
          Timer(
              Duration(milliseconds: 500),
              () => _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  curve: Curves.easeOut,
                  duration: const Duration(milliseconds: 300)));
          start = true;
          if (msgBox.length == 3) {
            emoji = true;
          }
        });
      }
    }
  }

  static var subscription;
  static Firestore _db = Firestore.instance;
  final textFieldFocusNode = FocusNode();
  static TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 20.0);
  static TextEditingController controller = new TextEditingController();
  static String msg = "";
  static List<String> msgList = [];
  static List<String> textList = [];
  static List<String> timeList = [];
  static List<bool> sendList = [];
  static List<Color> colorSelectList = [];
  static List<int> selectList = [];
  TextFormField msgField;
  Widget emojiDrawer;
  List<Widget> msgBox = [];
  List<Widget> actions = [];
  Widget list;
  Widget delete;
  Widget copyButton;
  Widget forwardButton;
  bool start;
  bool emoji;
  bool selectMode;
  bool read;
  IconData iconData;
  ScrollController _scrollController;

  void sendMessage() async {
    final prefs = await SharedPreferences.getInstance();
    Message message = new Message(
        msg.trim(), new DateTime.now().millisecondsSinceEpoch, true);
    msgList.add(jsonEncode(message));
    textList.add(msg.trim());
    timeList.add(DateFormat('yyyy-MM-dd  kk:mm').format(DateTime.now()));
    sendList.add(true);
    colorSelectList.add(Colors.transparent);
    prefs.remove("Jay2");
    prefs.setStringList("Jay2", msgList);
    controller.clear();

    setState(() {
      _db.collection("Chat").document("Jay2").updateData({
        "Jay1": FieldValue.arrayUnion([jsonEncode(message)]),
      }).whenComplete(() {
        setState(() {
          msg = "";
          start = true;
          Timer(
              Duration(milliseconds: 500),
              () => _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  curve: Curves.easeOut,
                  duration: const Duration(milliseconds: 300)));
        });
      });
    });
  }

  bool _isLink(String input) {
    final matcher = new RegExp(
        r"(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)");
    return matcher.hasMatch(input);
  }

  TextSpan getText(position) {
    final words = textList[position].split(' ');
    List<TextSpan> span = [];
    words.forEach((word) {
      span.add(_isLink(word)
          ? new LinkTextSpan(
              text: '$word ',
              url: word,
              style: TextStyle(color: Colors.black87, fontSize: 20)
                  .copyWith(color: Colors.blue))
          : new TextSpan(
              text: '$word ',
              style: TextStyle(color: Colors.black87, fontSize: 20)));
    });
    if (span.length > 0) {
      return new TextSpan(text: '', children: span);
    } else {
      return new TextSpan(text: textList[position]);
    }
  }

  @override
  Widget build(BuildContext context) {
    textFieldFocusNode.addListener(() {
      if (textFieldFocusNode.hasFocus) {
        setState(() {
          msgBox = [
            Expanded(child: list),
            Container(padding: EdgeInsets.all(5), child: msgField)
          ];
          Timer(
              Duration(milliseconds: 500),
              () => _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  curve: Curves.easeOut,
                  duration: const Duration(milliseconds: 300)));
        });
      }
    });

    forwardButton = Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(math.pi),
      child: Padding(
          padding: EdgeInsets.only(left: 20.0),
          child: IconButton(
              icon: Icon(Icons.reply),
              onPressed: () {
                Fluttertoast.showToast(
                    msg: 'Coming Soon!!',
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIos: 3,
                    backgroundColor: Colors.red[100],
                    textColor: Colors.white,
                    fontSize: 16.0);
              })),
    );

    copyButton = Padding(
        padding: EdgeInsets.only(right: 20.0),
        child: IconButton(
            icon: Icon(Icons.content_copy),
            onPressed: () {
              setState(() {
                String copy = "";
                var selectList1 = selectList..sort();
                var newSelectList = selectList1.reversed;
                if (newSelectList.length > 1) {
                  for (int i in newSelectList) {
                    if (sendList[i]) {
                      copy = copy + "Jay2 (";
                    } else {
                      copy = copy + "Jay1 (";
                    }
                    copy = copy + timeList[i] + "): ";
                    copy = copy + textList[i] + "\n";
                    colorSelectList[i] = Colors.transparent;
                  }
                } else {
                  copy = copy + textList[newSelectList.elementAt(0)];
                  colorSelectList[newSelectList.elementAt(0)] =
                      Colors.transparent;
                }
                selectList = [];
                actions = [];
                Clipboard.setData(new ClipboardData(text: copy));
                selectMode = false;
                start = true;
                if (msgBox.length == 3) {
                  emoji = true;
                }
              });
              Fluttertoast.showToast(
                  msg: 'Text copied to clipboard!!',
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.CENTER,
                  timeInSecForIos: 3,
                  backgroundColor: Colors.red[100],
                  textColor: Colors.white,
                  fontSize: 16.0);
            }));

    delete = Padding(
        padding: EdgeInsets.only(right: 20.0),
        child: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              setState(() {
                var selectList1 = selectList..sort();
                var newSelectList = selectList1.reversed;
                for (int i in newSelectList) {
                  msgList.removeAt(i);
                  textList.removeAt(i);
                  timeList.removeAt(i);
                  colorSelectList.removeAt(i);
                }
                selectList = [];
                actions = [];
                prefs.remove("Jay2");
                prefs.setStringList("Jay2", msgList);
                Timer(
                    Duration(milliseconds: 500),
                    () => _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        curve: Curves.easeOut,
                        duration: const Duration(milliseconds: 300)));
                selectMode = false;
                start = true;
                if (msgBox.length == 3) {
                  emoji = true;
                }
              });
              Fluttertoast.showToast(
                  msg: 'Message Deleted Successfully!!',
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.CENTER,
                  timeInSecForIos: 3,
                  backgroundColor: Colors.red[100],
                  textColor: Colors.white,
                  fontSize: 16.0);
            }));

    list = ListView.builder(
      controller: _scrollController,
      itemBuilder: (context, position) {
        return GestureDetector(
            onLongPress: () {
              if (!selectMode) {
                setState(() {
                  if (colorSelectList[position] ==
                      Color.fromRGBO(173, 216, 230, 1.0)) {
                    colorSelectList[position] = Colors.transparent;
                    selectList.remove(position);
                    if (selectList.isEmpty) {
                      setState(() {
                        actions = [];
                        selectMode = false;
                      });
                    }
                  } else {
                    colorSelectList[position] =
                        Color.fromRGBO(173, 216, 230, 1.0);
                    selectList.add(position);
                    if (actions.isEmpty) {
                      actions.add(delete);
                      actions.add(copyButton);
                      actions.add(forwardButton);
                      selectMode = true;
                    }
                  }
                  start = true;
                  if (msgBox.length == 3) {
                    emoji = true;
                  }
                });
              }
            },
            onTap: () {
              if (selectMode) {
                setState(() {
                  if (colorSelectList[position] ==
                      Color.fromRGBO(173, 216, 230, 1.0)) {
                    colorSelectList[position] = Colors.transparent;
                    selectList.remove(position);
                    if (selectList.isEmpty) {
                      setState(() {
                        actions = [];
                        selectMode = false;
                      });
                    }
                  } else {
                    colorSelectList[position] =
                        Color.fromRGBO(173, 216, 230, 1.0);
                    selectList.add(position);
                    if (actions.isEmpty) {
                      actions.add(delete);
                      actions.add(copyButton);
                      actions.add(forwardButton);
                      selectMode = true;
                    }
                  }
                  start = true;
                  if (msgBox.length == 3) {
                    emoji = true;
                  }
                });
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: colorSelectList[position],
              ),
              child: Material(
                  color: Colors.transparent,
                  child: Bubble(
                      elevation: 5,
                      padding: BubbleEdges.fromLTRB(20, 20, 20, 5),
                      margin: BubbleEdges.fromLTRB(2, 5, 2, 7.5),
                      nip: sendList[position]
                          ? BubbleNip.rightTop
                          : BubbleNip.leftTop,
                      color: sendList[position]
                          ? Color.fromRGBO(173, 216, 230, 1.0)
                          : Color.fromRGBO(232, 244, 248, 1.0),
                      alignment: sendList[position]
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Stack(
                        children: <Widget>[
                          Container(
                              constraints: BoxConstraints(minWidth: 100),
                              padding: EdgeInsets.fromLTRB(0, 0, 0, 27.5),
                              child: RichText(
                                  maxLines: null,
                                  textAlign: sendList[position] ? TextAlign.start : TextAlign.end,
                                  text: getText(position))),
                          Positioned(
                              bottom: 0,
                              right: 0,
                              child: RichText(
                                  maxLines: null,
                                  textAlign: TextAlign.end,
                                  text: TextSpan(
                                      text: "${timeList[position]}",
                                      style: TextStyle(
                                          color: Colors.deepPurple,
                                          fontSize: 12)))),
                        ],
                      ))),
            ));
      },
      padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
      itemCount: msgList.length,
    );

    emojiDrawer = EmojiPicker(
      rows: 3,
      columns: 7,
      onEmojiSelected: (emoji, category) {
        setState(() {
          msgField.controller.text = msg + emoji.emoji;
          msg = msg + emoji.emoji;
        });
      },
    );

    msgField = TextFormField(
      onChanged: (text) {
        msg = text;
      },
      controller: controller,
      maxLines: null,
      style: style,
      focusNode: textFieldFocusNode,
      decoration: InputDecoration(
          contentPadding: EdgeInsets.all(10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(width: 10),
          ),
          suffixIcon: IconButton(
              color: Colors.lightBlueAccent,
              disabledColor: Colors.lightBlueAccent[100],
              icon: Icon(Icons.send),
              onPressed: () {
                if (msg.trim() != "") {
                  setState(() {
                    textFieldFocusNode.canRequestFocus = true;
                    textFieldFocusNode.requestFocus();
                    msgBox = [
                      Expanded(child: list),
                      Container(padding: EdgeInsets.all(5), child: msgField)
                    ];
                    sendMessage();
                  });
                }
              }),
          prefixIcon: new IconButton(
              color: Colors.lightBlueAccent,
              disabledColor: Colors.lightBlueAccent[100],
              icon: Icon(iconData),
              onPressed: () {
                setState(() {
                  if (msgBox.length == 2) {
                    iconData = Icons.insert_emoticon;
                    textFieldFocusNode.unfocus();
                    textFieldFocusNode.canRequestFocus = false;
                    msgBox = [
                      Expanded(child: list),
                      Container(padding: EdgeInsets.all(5), child: msgField),
                      emojiDrawer
                    ];
                  } else {
                    iconData = Icons.keyboard;
                    textFieldFocusNode.canRequestFocus = true;
                    textFieldFocusNode.requestFocus();
                    msgBox = [
                      Expanded(child: list),
                      Container(padding: EdgeInsets.all(5), child: msgField)
                    ];
                  }
                });
              }),
          fillColor: Colors.lightBlueAccent,
          hintText: "Type Message"),
    );

    if (start) {
      if (emoji) {
        msgBox = [
          Expanded(child: list),
          Container(padding: EdgeInsets.all(5), child: msgField),
          emojiDrawer
        ];
        emoji = false;
      } else {
        msgBox = [
          Expanded(child: list),
          Container(padding: EdgeInsets.all(5), child: msgField)
        ];
      }
      start = false;
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: actions,
        ),
        body: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: msgBox,
        ));
  }

  getMessages() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      if (prefs.containsKey("Jay2")) {
        msgList = prefs.getStringList("Jay2");
      } else {
        prefs.setStringList("Jay2", []);
        msgList = [];
      }
      for (int i = 0; i < msgList.length; i++) {
        Map message1 = jsonDecode(msgList[i]);
        textList.add(message1["text"]);
        timeList.add(DateFormat('yyyy-MM-dd  kk:mm').format(
            DateTime.fromMicrosecondsSinceEpoch(message1["timestamp"] * 1000)));
        sendList.add(message1["send"]);
        if (message1["send"] == true) {
          colorSelectList.add(Colors.transparent);
        } else {
          colorSelectList.add(Colors.transparent);
        }
      }
      Timer(
          Duration(milliseconds: 500),
          () => _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              curve: Curves.easeOut,
              duration: const Duration(milliseconds: 300)));
      start = true;
    });
  }
}
