import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const String title = 'My Dic';
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
        '/': (_) => _LoginPage(),
        '/mypage': (_) => _MyPage(),
      },
    );
  }
}

class _LoginPage extends StatefulWidget {
  @override
  __LoginPageState createState() => __LoginPageState();
}

class __LoginPageState extends State<_LoginPage> {
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
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'email'),
                onChanged: (String value) {
                  setState(() {
                    email = value;
                  });
                },
              ),
              SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(labelText: 'password'),
                obscureText: true,
                onChanged: (String value) {
                  setState(() {
                    password = value;
                  });
                },
              ),
              Container(
                padding: EdgeInsets.all(8),
                child: Text(infoText),
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
                        email: email,
                        password: password,
                      );
                      print(userCredential);
                      if (userCredential.user == null) {
                        throw Exception('ログインに失敗しました');
                      }
                      await Navigator.of(context)
                          .pushReplacementNamed('/mypage');
                    } catch (e) {
                      print(e);
                      setState(() {
                        infoText = "ログインに失敗しました：${e.message}";
                      });
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
                        email: email,
                        password: password,
                      );
                      await Navigator.of(context)
                          .pushReplacementNamed('/mypage');
                    } catch (e) {
                      setState(() {
                        infoText = "登録に失敗しました：${e.message}";
                      });
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

class _MyPage extends StatelessWidget {
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
              await FirebaseAuth.instance.signOut();
              await Navigator.of(context).pushReplacementNamed('/');
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
                                  _AddWordPage(document),
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
                                            child: Text('Cancel')),
                                        TextButton(
                                            onPressed: () async {
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(auth.currentUser.uid)
                                                  .collection('transaction')
                                                  .doc(document.id)
                                                  .delete();
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('OK')),
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
                return Center(
                  child: Text('アイテムを追加しましょう！'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) => _AddWordPage(null),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class _AddWordPage extends StatefulWidget {
  final DocumentSnapshot document;
  _AddWordPage(this.document);

  @override
  __AddWordPageState createState() => __AddWordPageState();
}

class __AddWordPageState extends State<_AddWordPage> {
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
          padding: EdgeInsets.all(40),
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
                      print(e);
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
