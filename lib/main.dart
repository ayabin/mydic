import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const String title = 'MyDic';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: title,
      routes: {
        '/': (_) => LoginPage(),
        '/mypage': (_) => MyPage(),
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String infoText = '';
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'email'),
                onChanged: (String value) {
                  email = value;
                },
              ),
              SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(labelText: 'password'),
                onChanged: (String value) {
                  password = value;
                },
              ),
              Container(
                padding: EdgeInsets.all(8),
                child: Text(
                  infoText,
                  style: TextStyle(color: Colors.red),
                ),
              ),
              SizedBox(height: 48),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  child: Text('ログイン'),
                  onPressed: () async {
                    try {
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final UserCredential userCredential =
                          await auth.signInWithEmailAndPassword(
                              email: email, password: password);
                      await Navigator.of(context)
                          .pushReplacementNamed('/mypage');
                    } catch (e) {
                      setState(() {
                        infoText = e.message;
                      });
                      print("エラー：${e.message}");
                    }
                  },
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  child: Text('新規登録'),
                  onPressed: () async {
                    try {
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final UserCredential userCredential =
                          await auth.createUserWithEmailAndPassword(
                              email: email, password: password);
                      await Navigator.of(context)
                          .pushReplacementNamed('/mypage');
                    } catch (e) {
                      setState(() {
                        infoText = e.message;
                      });
                      print("エラー：${e.message}");
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyPage extends StatelessWidget {
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MyPage'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                await Navigator.of(context).pushReplacementNamed('/');
              } catch (e) {
                print("エラー：${e.message}");
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(auth.currentUser.uid)
                  .collection('transaction')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final List<DocumentSnapshot> documents = snapshot.data.docs;
                  return ListView(
                    children: documents.map((document) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  AddWordPage(document),
                            ),
                          );
                        },
                        child: Card(
                          child: ListTile(
                            title: Text(document['word']),
                            subtitle: Text(document['meaning']),
                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(document['word'] + 'を削除します'),
                                      content: Text('削除してよいですか？'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            try {
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(auth.currentUser.uid)
                                                  .collection('transaction')
                                                  .doc(document.id)
                                                  .delete();
                                              Navigator.of(context).pop();
                                            } catch (e) {
                                              print("エラー：${e.message}");
                                            }
                                          },
                                          child: Text('OK'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }
                return Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) => AddWordPage(null),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddWordPage extends StatefulWidget {
  final DocumentSnapshot document;
  AddWordPage(this.document);

  @override
  _AddWordPageState createState() => _AddWordPageState();
}

class _AddWordPageState extends State<AddWordPage> {
  String word = '';
  String meaning = '';
  String uid;
  String docId;
  FirebaseAuth auth = FirebaseAuth.instance;
  @override
  void initState() {
    super.initState();
    uid = auth.currentUser.uid;
    docId = null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.document != null) {
      word = widget.document['word'];
      meaning = widget.document['meaning'];
      docId = widget.document.id;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Word'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              TextFormField(
                initialValue: word,
                decoration: InputDecoration(labelText: 'Word'),
                onChanged: (String value) {
                  word = value;
                },
              ),
              SizedBox(height: 8),
              TextFormField(
                initialValue: meaning,
                decoration: InputDecoration(labelText: 'Meaning'),
                onChanged: (String value) {
                  meaning = value;
                },
              ),
              SizedBox(height: 48),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final date = DateTime.now().toLocal().toIso8601String();
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('transaction')
                          .doc(docId)
                          .set({
                        'word': word,
                        'meaning': meaning,
                        'date': date,
                      });
                      Navigator.of(context).pop();
                    } catch (e) {
                      print("エラー：${e.message}");
                    }
                  },
                  child: Text('登録'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
