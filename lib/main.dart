import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf_widgets;
import 'package:printing/printing.dart';

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
              icon: const Padding(
                padding: EdgeInsets.only(right: 4.0),
                child: Icon(
                  Icons.add_rounded,
                  size: 32.0,
                  color: Colors.black,
                ),
              )),
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
                    dense: true,
                    visualDensity: const VisualDensity(
                        horizontal: VisualDensity.minimumDensity,
                        vertical: VisualDensity.minimumDensity),
                    title: Text(
                      data.tasks,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(data.date,
                        style: Theme.of(context).textTheme.labelSmall),
                    trailing: Container(
                      padding: const EdgeInsets.only(left: 8.0),
                      height: 22.0,
                      width: 22.0,
                      alignment: Alignment.centerRight,
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        size: 22.0,
                      ),
                    ),
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
      floatingActionButton: FutureBuilder(
        future: _dataservice.getData(),
        initialData: const [],
        builder: (context, snapshot) {
          if (snapshot.data?.isNotEmpty ?? false) {
            return FloatingActionButton(
              backgroundColor: Colors.amber,
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => PDFPreview(
                    dataService: _dataservice,
                  ),
                ))
                    .then((value) {
                  if (value == true) {
                    setState(() {});
                  }
                });
              },
              child: const Icon(
                Icons.picture_as_pdf,
                size: 32,
              ),
            );
          } else {
            return const SizedBox();
          }
        },
      ),
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

class PDFPreview extends StatelessWidget {
  final DataService dataService;
  const PDFPreview({super.key, required this.dataService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Protokollvorschau'),
          backgroundColor: Colors.amber,
          leading: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.close)),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.file_download)),
          ]),
      body: PdfPreview(build: (context) async {
        List<DayData> data = await dataService.getData();
        return await createPreview(data);
      }),
    );
  }

  Future<Uint8List> createPreview(List<DayData> data) async {
    final pdf = pdf_widgets.Document();
    List<pdf_widgets.Widget> children = [];

    data.asMap().forEach((key, value) {
      final index = key + 1;
      if (index % 4 == 0 || index == data.length) {
        children.addAll(getDayColumn(value, children.isEmpty));
        final childrenCopy = children;
        children = [];
        pdf_widgets.Page page = pdf_widgets.Page(
          build: (context) {
            return pdf_widgets.Column(children: [
              ...getHeader(),
              ...childrenCopy,
            ]);
          },
        );
        pdf.addPage(page);
      } else {
        children.addAll(getDayColumn(value, children.isEmpty));
      }
    });
    return pdf.save();
  }

  List<pdf_widgets.Widget> getHeader() {
    return [
      pdf_widgets.Row(
        children: [
          pdf_widgets.Expanded(
            child: pdf_widgets.Text('Tätigkeit im Praktikum',
                textAlign: pdf_widgets.TextAlign.center),
          ),
        ],
      ),
      pdf_widgets.SizedBox(height: 20.0),
      pdf_widgets.Row(
        children: [
          pdf_widgets.Text('Beschreibe einen Tag der Woche ausführlich.')
        ],
      ),
      pdf_widgets.SizedBox(height: 20.0),
    ];
  }

  List<pdf_widgets.Widget> getDayColumn(DayData day, bool addTableHearer) {
    return [
      pdf_widgets.Table(
        border: pdf_widgets.TableBorder.all(color: PdfColors.black),
        columnWidths: {1: const pdf_widgets.FixedColumnWidth(100)},
        children: [
          if (addTableHearer)
            pdf_widgets.TableRow(
              children: [
                pdf_widgets.SizedBox(
                    width: 35.0,
                    child: pdf_widgets.Column(
                      children: [
                        pdf_widgets.Padding(
                          padding: const pdf_widgets.EdgeInsets.all(10.0),
                          child: pdf_widgets.Text('Datum/Arbeitszeit'),
                        )
                      ],
                    )),
                pdf_widgets.Column(
                    mainAxisAlignment: pdf_widgets.MainAxisAlignment.center,
                    children: [
                      pdf_widgets.Padding(
                        padding: const pdf_widgets.EdgeInsets.all(10.0),
                        child: pdf_widgets.Text('Ausgeführte Arbeiten'),
                      )
                    ]),
              ],
            ),
          pdf_widgets.TableRow(
            children: [
              pdf_widgets.SizedBox(
                width: 35.0,
                child: pdf_widgets.Column(children: [
                  pdf_widgets.Text(
                      '\n${day.date}\n\nvon: ${day.startTime}\nbis: ${day.endTime}\n\n',
                      textAlign: pdf_widgets.TextAlign.left)
                ]),
              ),
              pdf_widgets.Column(
                  mainAxisAlignment: pdf_widgets.MainAxisAlignment.start,
                  crossAxisAlignment: pdf_widgets.CrossAxisAlignment.start,
                  children: [
                    pdf_widgets.Padding(
                        padding: const pdf_widgets.EdgeInsets.all(10.0),
                        child: pdf_widgets.Text(day.tasks))
                  ]),
            ],
          ),
        ],
      )
    ];
  }
}
