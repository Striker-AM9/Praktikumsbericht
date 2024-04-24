import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:praktikumsbericht/extensions/datetime_extension.dart';
import 'package:praktikumsbericht/extensions/daydata.dart';
import 'package:praktikumsbericht/extensions/time_of_day_extension.dart';
import 'package:praktikumsbericht/services/data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  Gemini.init(
    apiKey: 'AIzaSyBWgubQS-g4cUFXmOZUEl3Q33hSgGk-XFQ',
  );
  runApp(MyApp(sharedPreferences: sharedPreferences));
}
//////

class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;
  const MyApp({super.key, required this.sharedPreferences});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Praktikumsbericht',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: HomePage(
        title: 'Praktikumsbericht',
        sharedPreferences: sharedPreferences,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String title;
  final SharedPreferences sharedPreferences;
  const HomePage(
      {super.key, required this.title, required this.sharedPreferences});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DataService _dataservice;

  @override
  void initState() {
    super.initState();
    _dataservice = DataService(widget.sharedPreferences);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 5,
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => Editor(
                    sharedPreferences: widget.sharedPreferences,
                  ),
                ))
                    .then((value) {
                  if (value == true) {
                    setState(() {});
                  }
                });
              },
              icon: const Icon(Icons.add)),
        ],
      ),
      body: FutureBuilder(
          future: _dataservice.getData(),
          builder: (context, snapShot) {
            if (snapShot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapShot.hasData && snapShot.data!.isEmpty) {
              return const Center(
                child: Text('Keine Daten'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(5),
              itemBuilder: (context, index) {
                DayData data = snapShot.data![index];
                return Dismissible(
                  key: Key(data.date),
                  direction: DismissDirection.endToStart,
                  background: const ColoredBox(
                      color: Colors.red,
                      child: Align(
                        child: Icon(
                          Icons.delete_forever,
                          color: Colors.white,
                        ),
                      )),
                  confirmDismiss: (_) async {
                    return await _dataservice.deletaData(data);
                  },
                  onDismissed: (_) => setState(() {}),
                  child: ListTile(
                    title: Text(data.tasks),
                    subtitle: Text(data.date),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context)
                          .push(MaterialPageRoute(
                              builder: (context) => Editor(
                                    sharedPreferences: widget.sharedPreferences,
                                    dayData: data,
                                  )))
                          .then((value) {
                        if (value == true) {
                          setState(() {});
                        }
                      });
                    },
                  ),
                );
              },
              itemCount: snapShot.data!.length,
              separatorBuilder: (context, index) {
                return const Divider(
                  height: 1,
                  indent: 15,
                );
              },
            );
          }),
    );
  }
}

class Editor extends StatefulWidget {
  final DayData? dayData;
  final SharedPreferences sharedPreferences;
  const Editor({super.key, required this.sharedPreferences, this.dayData});

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  final TextEditingController dateController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController activityController = TextEditingController();
  late DataService _dataservice;

  addItem() {}

  @override
  void initState() {
    super.initState();
    _dataservice = DataService(widget.sharedPreferences);
    if (widget.dayData != null) {
      dateController.text = widget.dayData?.date ?? '';
      startTimeController.text = widget.dayData?.startTime ?? '';
      endTimeController.text = widget.dayData?.endTime ?? '';
      activityController.text = widget.dayData?.tasks ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Praktikumstag"),
        leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            icon: const Icon(Icons.close)),
        actions: [
          IconButton(
              onPressed: isValid()
                  ? () async {
                      DayData daydata = DayData(
                          date: dateController.text,
                          startTime: startTimeController.text,
                          endTime: endTimeController.text,
                          tasks: activityController.text);
                      if (widget.dayData != null) {
                        _dataservice
                            .updateData(daydata)
                            .then((value) => Navigator.of(context).pop(true));
                      } else {
                        _dataservice
                            .storeData(daydata)
                            .then((value) => Navigator.of(context).pop(true));
                      }
                    }
                  : null,
              icon: const Icon(Icons.done)),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  if (widget.dayData != null) return;
                  showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2025))
                      .then((value) {
                    if (value == null) return;
                    setState(() {
                      dateController.text =
                          value.formateDateTime('dd.MM.yyyy').toString();
                    });
                  });
                },
                child: TextField(
                  autofocus: false,
                  enabled: false,
                  controller: dateController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLines: 1,
                  decoration: const InputDecoration(
                    filled: true,
                    labelText: 'Datum',
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  showTimePicker(context: context, initialTime: TimeOfDay.now())
                      .then((value) {
                    if (value == null) return;
                    setState(() {
                      startTimeController.text =
                          value.formateTimeOfDay('HH:mm').toString();
                    });
                  });
                },
                child: TextField(
                  autofocus: false,
                  enabled: false,
                  maxLines: 1,
                  controller: startTimeController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    filled: true,
                    labelText: 'Startziet',
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  showTimePicker(context: context, initialTime: TimeOfDay.now())
                      .then((value) {
                    if (value == null) return;
                    setState(() {
                      endTimeController.text =
                          value.formateTimeOfDay('HH:mm').toString();
                    });
                  });
                },
                child: TextField(
                  autofocus: false,
                  enabled: false,
                  maxLines: 1,
                  controller: endTimeController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    filled: true,
                    labelText: 'Endzeit',
                  ),
                ),
              ),
              TextField(
                maxLines: 10,
                controller: activityController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                    filled: true, helperMaxLines: 20, labelText: 'Tätigkeiten'),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    setState(() {});
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.all(150),
                child: MaterialButton(
                  onPressed: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (context) => const Chat()))
                        .then((value) {
                      if (value == true) {
                        setState(() {});
                      }
                    });
                  },
                  color: Colors.green,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(15.0),
                  child: const Icon(
                    Icons.adb,
                    size: 35,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  bool isValid() {
    return dateController.text.isNotEmpty &&
        startTimeController.text.isNotEmpty &&
        endTimeController.text.isNotEmpty &&
        activityController.text.isNotEmpty;
  }
}

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final Gemini gemini = Gemini.instance;

  List<ChatMessage> messages = [];

  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "Gemini",
    profileImage:
        "https://seeklogo.com/images/G/google-gemini-logo-A5787B2669-seeklogo.com.png",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.amber,
          title: const Text('AI Chat'),
        ),
        body: _buildUI());
  }

  Widget _buildUI() {
    return DashChat(
      inputOptions: const InputOptions(trailing: []),
      messageOptions: MessageOptions(
        onPressMessage: (message) async {
          await Clipboard.setData(ClipboardData(text: message.text)).then((_) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text("Message kopiert")));
          });

          if (kDebugMode) {
            print(message.text);
          }
        },
      ),
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
    );
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });
    try {
      String question = chatMessage.text;
      gemini
          .streamGenerateContent(
        question,
      )
          .listen((event) {
        ChatMessage? lastMessage = messages.firstOrNull;
        if (lastMessage != null && lastMessage.user == geminiUser) {
          lastMessage = messages.removeAt(0);
          String response = event.content?.parts?.fold(
                  "", (previous, current) => "$previous ${current.text}") ??
              "";
          lastMessage.text += response;
          setState(
            () {
              messages = [lastMessage!, ...messages];
            },
          );
        } else {
          String response = event.content?.parts?.fold(
                  "", (previous, current) => "$previous ${current.text}") ??
              "";
          ChatMessage message = ChatMessage(
            user: geminiUser,
            createdAt: DateTime.now(),
            text: response,
          );
          setState(() {
            messages = [message, ...messages];
          });
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }
}
