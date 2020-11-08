import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medic_app/data/socket_io_manager.dart';
import 'package:medic_app/models/doctor/message.dart';
import 'package:medic_app/providers/doctors_provider/messages_provider.dart';
import 'package:medic_app/theme/theme.dart';
import 'package:medic_app/utils/apis/server.dart';
import 'package:medic_app/utils/essentials/loading.dart';
import 'package:provider/provider.dart';

import 'messages_form.dart';
import 'messages_item.dart';

class ChatScreen extends StatefulWidget {
  final String senderName;

  const ChatScreen(
    this.senderName,
  );

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  ScrollController _scrollController;

  SocketIoManager _socketIoManager;

  bool _isTyping = false;
  String _userNameTyping;

  void _onTyping() {
    _socketIoManager.sendMessage(
        'typing', json.encode({'senderName': widget.senderName}));
  }

  void _onStopTyping() {
    _socketIoManager.sendMessage(
        'stop_typing', json.encode({'senderName': widget.senderName}));
  }

  void _sendMessage(String messageContent) {
    _socketIoManager.sendMessage(
      'send_message',
      Message(
        widget.senderName,
        messageContent,
        DateTime.now(),
      ).toJson(),
    );

    Provider.of<MessagesProvider>(context, listen: false)
        .addMessage(Message(widget.senderName, messageContent, DateTime.now()));
  }

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    _socketIoManager = SocketIoManager(serverUrl: SERVER_URL)
      ..init()
      ..subscribe('receive_message', (Map<String, dynamic> data) {
        Provider.of<MessagesProvider>(context, listen: false)
            .addMessage(Message.fromJson(data));
        _scrollController.animateTo(
          0.0,
          duration: Duration(milliseconds: 200),
          curve: Curves.bounceInOut,
        );
      })
      ..subscribe('typing', (Map<String, dynamic> data) {
        _userNameTyping = data['senderName'];
        setState(() {
          _isTyping = true;
        });
      })
      ..subscribe('stop_typing', (Map<String, dynamic> data) {
        setState(() {
          _isTyping = false;
        });
      })
      ..connect();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _socketIoManager.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dr. ${widget.senderName}"),
      ),
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Visibility(
            visible: _isTyping,
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: typinG(context),
            ),
          ),
          Expanded(
            child:
                Consumer<MessagesProvider>(builder: (_, messagesProvider, __) {
              print(messagesProvider.allMessages.length);
              if (messagesProvider.allMessages.length < 1) {
                return ChatWaiting(
                    "Waiting ${widget.senderName.split(" ")[0]} to join...");
              }
              return ListView.builder(
                reverse: true,
                controller: _scrollController,
                itemCount: messagesProvider.allMessages.length,
                itemBuilder: (ctx, index) => MessagesItem(
                    messagesProvider.allMessages[index],
                    messagesProvider.allMessages[index]
                        .isUserMessage(widget.senderName),
                    widget.senderName),
              );
            }),
          ),
          MessageForm(
            onSendMessage: _sendMessage,
            onTyping: _onTyping,
            onStopTyping: _onStopTyping,
          ),
        ],
      ),
    );
  }

  Row typinG(BuildContext context) {
    return Row(
      children: <Widget>[
        Spacer(),
        Text(
          '${widget.senderName.split(" ")[0]} is typing',
          style: Theme.of(context).textTheme.caption.copyWith(
                color: Colors.black54,
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
        ),
        TypingLoading(),
        Spacer(),
      ],
    );
  }
}
