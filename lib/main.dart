import 'package:flutter/material.dart';
import 'package:praktikumsbericht/extensions/datetime_extension.dart';
import 'package:praktikumsbericht/extensions/time_of_day_extension.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Praktikumsbericht',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(title: 'Praktikumsbericht'),
    );
  }
}

class HomePage extends StatelessWidget {
  final String title;
  const HomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) =>
               const Editor(),
            ));
          }, icon: const Icon(Icons.add)),
        ],
      ),
    );
  }
}

class Editor extends StatefulWidget {

   const Editor({super.key});

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  final TextEditingController dateController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController activityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Praktikumstag"),
        leading: IconButton(onPressed: () {
            Navigator.of(context).pop();
        }, icon: const Icon(Icons.close)),
        actions: [
          IconButton(onPressed: () {

          }, icon: const Icon(Icons.done)),
        ],
      ),

      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  showDatePicker(context: context, initialDate: DateTime.now(),
                      firstDate: DateTime(2024), lastDate: DateTime(2025)).then((value) {
                    if(value == null) return;
                    setState(() {
                      dateController.text = value.formateDateTime('dd.MM.yyyy').toString();
                    });
                    print(value.toIso8601String());
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
            showTimePicker(context: context, initialTime: TimeOfDay.now()).then((value) {
              if(value == null) return;
              setState(() {
                startTimeController.text = value.formateTimeOfDay('HH:mm').toString();
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
                decoration: InputDecoration(
                  filled: true,
                  labelText: 'Startzeit',
                ),
              ),
            ),
            GestureDetector(
            onTap: () {
            showTimePicker(context: context, initialTime: TimeOfDay.now()).then((value) {
              if(value == null) return;
              setState(() {
                endTimeController.text = value.formateTimeOfDay('HH:mm').toString();
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
                decoration: InputDecoration(
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
                  decoration: InputDecoration(
                    filled: true,
                    helperMaxLines: 20,
                    labelText: 'Tätigkeiten'
                  ),
                ),
              MaterialButton(
                  onPressed: () {},
                  color: Colors.green,
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(15.0),
                  child: Icon(Icons.adb, size: 35,),
              )
            ],
          ),
        ),
      ),
    );
  }
}

